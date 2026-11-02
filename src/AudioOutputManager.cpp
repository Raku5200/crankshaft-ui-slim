/*
 * Project: Crankshaft
 * This file is part of Crankshaft project.
 * Copyright (C) 2025 OpenCarDev Team
 *
 *  Crankshaft is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Crankshaft is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Crankshaft. If not, see <http://www.gnu.org/licenses/>.
 */

#include "AudioOutputManager.h"

#include <unistd.h>

#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QProcessEnvironment>
#include <QTimer>

#include "Logger.h"

namespace {
constexpr int kPactlTimeoutMs = 5000;
constexpr int kRetryDelayMs = 3000;
constexpr int kMaxRetries = 20;  // the sound server can start after the UI
}  // namespace

AudioOutputManager::AudioOutputManager(QObject* parent) : QObject(parent) {}

auto AudioOutputManager::hasOutput(const QString& name) const -> bool {
    for (const QVariant& entry : m_outputs) {
        if (entry.toMap().value(QStringLiteral("name")).toString() == name) {
            return true;
        }
    }
    return false;
}

auto AudioOutputManager::labelFor(const QString& name, const QString& description) -> QString {
    const QString lower = name.toLower();
    QString kind;
    if (lower.contains(QStringLiteral("bluez"))) {
        kind = tr("Bluetooth");
    } else if (lower.contains(QStringLiteral("hdmi"))) {
        kind = tr("HDMI");
    } else if (lower.contains(QStringLiteral("mailbox")) ||
               lower.contains(QStringLiteral("headphones")) ||
               lower.contains(QStringLiteral("bcm2835"))) {
        kind = tr("Headphone jack");
    } else if (lower.contains(QStringLiteral("usb"))) {
        kind = tr("USB");
    }

    if (kind.isEmpty()) {
        return description.isEmpty() ? name : description;
    }
    // Bluetooth and USB devices have useful names (the speaker or card model).
    if ((kind == tr("Bluetooth") || kind == tr("USB")) && !description.isEmpty()) {
        return QStringLiteral("%1: %2").arg(kind, description);
    }
    return kind;
}

void AudioOutputManager::runPactl(const QStringList& args,
                                  std::function<void(bool, const QByteArray&)> done) {
    auto* process = new QProcess(this);

    // The UI service runs as the crankshaft user; point pactl at that user's server.
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    if (!env.contains(QStringLiteral("XDG_RUNTIME_DIR"))) {
        env.insert(QStringLiteral("XDG_RUNTIME_DIR"),
                   QStringLiteral("/run/user/%1").arg(getuid()));
    }
    if (!env.contains(QStringLiteral("PULSE_SERVER"))) {
        const QString socket =
            env.value(QStringLiteral("XDG_RUNTIME_DIR")) + QStringLiteral("/pulse/native");
        if (QFileInfo::exists(socket)) {
            env.insert(QStringLiteral("PULSE_SERVER"), QStringLiteral("unix:") + socket);
        }
    }
    process->setProcessEnvironment(env);

    auto* timeout = new QTimer(process);
    timeout->setSingleShot(true);
    connect(timeout, &QTimer::timeout, process, [process]() { process->kill(); });

    connect(process, &QProcess::finished, this,
            [process, done](int exitCode, QProcess::ExitStatus status) {
                const bool ok = status == QProcess::NormalExit && exitCode == 0;
                done(ok, process->readAllStandardOutput());
                process->deleteLater();
            });
    connect(process, &QProcess::errorOccurred, this, [process, done](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            done(false, QByteArray());
            process->deleteLater();
        }
    });

    timeout->start(kPactlTimeoutMs);
    process->start(QStringLiteral("pactl"), args);
}

void AudioOutputManager::refresh() {
    if (m_refreshing) {
        return;
    }
    m_refreshing = true;

    runPactl({QStringLiteral("--format=json"), QStringLiteral("list"), QStringLiteral("sinks")},
             [this](bool ok, const QByteArray& out) {
                 if (ok) {
                     parseSinks(out, true);
                 } else {
                     // Older pactl without JSON output: names only.
                     runPactl({QStringLiteral("list"), QStringLiteral("short"),
                               QStringLiteral("sinks")},
                              [this](bool shortOk, const QByteArray& shortOut) {
                                  if (shortOk) {
                                      parseSinks(shortOut, false);
                                  } else {
                                      m_refreshing = false;
                                      Logger::instance().warningContext(
                                          QStringLiteral("AudioOutputManager"),
                                          QStringLiteral("Sound server not reachable yet"));
                                      scheduleRetry();
                                  }
                              });
                 }
             });
}

void AudioOutputManager::parseSinks(const QByteArray& data, bool isJson) {
    QVariantList outputs;
    if (isJson) {
        const QJsonArray sinks = QJsonDocument::fromJson(data).array();
        for (const QJsonValue& value : sinks) {
            const QJsonObject sink = value.toObject();
            const QString name = sink.value(QStringLiteral("name")).toString();
            if (name.isEmpty()) {
                continue;
            }
            const QString description = sink.value(QStringLiteral("description")).toString();
            outputs.append(QVariantMap{{QStringLiteral("name"), name},
                                       {QStringLiteral("label"), labelFor(name, description)}});
        }
    } else {
        // "<index>\t<name>\t<driver>\t<format>\t<state>"
        for (const QByteArray& line : data.split('\n')) {
            const QList<QByteArray> fields = line.split('\t');
            if (fields.size() < 2) {
                continue;
            }
            const QString name = QString::fromUtf8(fields.at(1)).trimmed();
            outputs.append(QVariantMap{{QStringLiteral("name"), name},
                                       {QStringLiteral("label"), labelFor(name, QString())}});
        }
    }

    // Two outputs of the same kind (e.g. two HDMI ports) need telling apart.
    QStringList labels;
    for (const QVariant& entry : outputs) {
        labels.append(entry.toMap().value(QStringLiteral("label")).toString());
    }
    for (int i = 0; i < outputs.size(); ++i) {
        if (labels.count(labels.at(i)) > 1) {
            QVariantMap entry = outputs.at(i).toMap();
            entry[QStringLiteral("label")] =
                QStringLiteral("%1 %2").arg(labels.at(i)).arg(labels.mid(0, i + 1).count(labels.at(i)));
            outputs[i] = entry;
        }
    }

    if (outputs != m_outputs) {
        m_outputs = outputs;
        emit outputsChanged();
    }

    runPactl({QStringLiteral("get-default-sink")}, [this](bool ok, const QByteArray& out) {
        m_refreshing = false;
        const QString current = ok ? QString::fromUtf8(out).trimmed() : QString();
        if (current != m_currentOutput) {
            m_currentOutput = current;
            emit currentOutputChanged();
        }
        const bool wasAvailable = m_available;
        if (!m_available) {
            m_available = true;
            emit availableChanged();
        }
        Logger::instance().infoContext(
            QStringLiteral("AudioOutputManager"),
            QStringLiteral("%1 output(s), default: %2").arg(m_outputs.size()).arg(m_currentOutput));
        if (!wasAvailable) {
            emit ready();
        }
    });
}

void AudioOutputManager::scheduleRetry() {
    if (m_available || m_retries >= kMaxRetries) {
        return;
    }
    ++m_retries;
    QTimer::singleShot(kRetryDelayMs, this, &AudioOutputManager::refresh);
}

void AudioOutputManager::selectOutput(const QString& name) {
    if (name.isEmpty()) {
        return;
    }
    Logger::instance().infoContext(QStringLiteral("AudioOutputManager"),
                                   QStringLiteral("Switching output to %1").arg(name));
    runPactl({QStringLiteral("set-default-sink"), name}, [this, name](bool ok, const QByteArray&) {
        if (!ok) {
            Logger::instance().warningContext(
                QStringLiteral("AudioOutputManager"),
                QStringLiteral("Could not switch output to %1").arg(name));
            refresh();
            return;
        }
        if (m_currentOutput != name) {
            m_currentOutput = name;
            emit currentOutputChanged();
        }
        emit outputSelected(name);
    });
}

void AudioOutputManager::setVolume(int percent) {
    const int clamped = qBound(0, percent, 100);
    runPactl({QStringLiteral("set-sink-volume"), QStringLiteral("@DEFAULT_SINK@"),
              QStringLiteral("%1%").arg(clamped)},
             [clamped](bool ok, const QByteArray&) {
                 if (!ok) {
                     Logger::instance().warningContext(
                         QStringLiteral("AudioOutputManager"),
                         QStringLiteral("Could not set volume to %1%").arg(clamped));
                 }
             });
}
