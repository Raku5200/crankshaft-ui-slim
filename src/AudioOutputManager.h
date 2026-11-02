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

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <functional>

/**
 * Lists the sound outputs of the PipeWire sound server (headphone jack, HDMI, USB
 * sound cards, Bluetooth speakers) and switches between them. Core plays Android
 * Auto audio to the default output, so choosing an output here makes it the
 * default. Talks to PipeWire through pactl (pipewire-pulse). Exposed to QML as
 * _audioOutputs.
 */
class AudioOutputManager : public QObject {
    Q_OBJECT
    /// List of {name, label} maps, one per output.
    Q_PROPERTY(QVariantList outputs READ outputs NOTIFY outputsChanged)
    /// Name of the current default output, or empty when unknown.
    Q_PROPERTY(QString currentOutput READ currentOutput NOTIFY currentOutputChanged)
    /// False until the sound server has answered at least once.
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)

  public:
    explicit AudioOutputManager(QObject* parent = nullptr);

    [[nodiscard]] auto outputs() const -> QVariantList { return m_outputs; }
    [[nodiscard]] auto currentOutput() const -> QString { return m_currentOutput; }
    [[nodiscard]] auto available() const -> bool { return m_available; }
    [[nodiscard]] auto hasOutput(const QString& name) const -> bool;

    /// Re-read the outputs from the sound server.
    Q_INVOKABLE void refresh();
    /// Make @p name the default output (the user picked it).
    Q_INVOKABLE void selectOutput(const QString& name);
    /// Set the volume of the default output, 0-100 %.
    Q_INVOKABLE void setVolume(int percent);

    /// Friendly label for an output, e.g. "Headphone jack" or "HDMI".
    static auto labelFor(const QString& name, const QString& description) -> QString;

  signals:
    void outputsChanged();
    void currentOutputChanged();
    void availableChanged();
    /// The user chose an output in the UI (not emitted for refreshes).
    void outputSelected(const QString& name);
    /// The first successful refresh after start-up has completed.
    void ready();

  private:
    void runPactl(const QStringList& args, std::function<void(bool, const QByteArray&)> done);
    void parseSinks(const QByteArray& json, bool isJson);
    void scheduleRetry();

    QVariantList m_outputs;
    QString m_currentOutput;
    bool m_available = false;
    bool m_refreshing = false;
    int m_retries = 0;
};
