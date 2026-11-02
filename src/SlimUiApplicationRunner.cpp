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

#include "SlimUiApplicationRunner.h"

#include "AndroidAutoWebRtcReceiver.h"
#include "AndroidAutoWebRtcSession.h"

#include <QCommandLineParser>
#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QQuickStyle>
#include <QTimer>

#ifdef Q_OS_LINUX
#include <QByteArray>
#include <cstring>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#endif

#ifdef Q_OS_WIN
#include <QStandardPaths>
#endif

#include "AndroidAutoFacade.h"
#include "AudioBridge.h"
#include "BluetoothAdapter.h"
#include "ConnectionStateMachine.h"
#include "DeviceManager.h"
#include "ErrorHandler.h"
#include "Logger.h"
#include "PreferencesFacade.h"
#include <QJsonObject>
#include "CoreClient.h"
#include "AudioOutputManager.h"
#include "ProjectionInfoFacade.h"
#include "ServiceProvider.h"
#include "TouchEventForwarder.h"

namespace {
#ifdef Q_OS_LINUX
auto sendSystemdNotify(const QByteArray& state) -> bool {
    const QByteArray notifySocket = qgetenv("NOTIFY_SOCKET");
    if (notifySocket.isEmpty()) {
        return false;
    }

    sockaddr_un address {};
    address.sun_family = AF_UNIX;

    QByteArray socketPath = notifySocket;
    if (socketPath.size() >= static_cast<int>(sizeof(address.sun_path))) {
        return false;
    }

    bool isAbstractSocket = !socketPath.isEmpty() && socketPath[0] == '@';
    if (isAbstractSocket) {
        socketPath[0] = '\0';
    }

    ::memcpy(address.sun_path, socketPath.constData(), static_cast<size_t>(socketPath.size()));

    int fd = ::socket(AF_UNIX, SOCK_DGRAM | SOCK_CLOEXEC, 0);
    if (fd < 0) {
        return false;
    }

    socklen_t addressLength = static_cast<socklen_t>(sizeof(address.sun_family) + socketPath.size());
    if (!isAbstractSocket) {
        addressLength = static_cast<socklen_t>(sizeof(address));
    }

    ssize_t sent = ::sendto(fd, state.constData(), static_cast<size_t>(state.size()), MSG_NOSIGNAL,
                            reinterpret_cast<const sockaddr*>(&address), addressLength);
    ::close(fd);

    return sent == state.size();
}

auto watchdogIntervalMs() -> int {
    bool ok = false;
    quint64 watchdogUsec = qgetenv("WATCHDOG_USEC").toULongLong(&ok);
    if (!ok || watchdogUsec == 0) {
        return 0;
    }

    quint64 intervalMs = watchdogUsec / 2000;  // half of watchdog window
    if (intervalMs < 1000) {
        intervalMs = 1000;
    }

    return static_cast<int>(intervalMs);
}
#else
auto sendSystemdNotify(const QByteArray& state) -> bool {
    Q_UNUSED(state)
    return false;
}

auto watchdogIntervalMs() -> int { return 0; }
#endif
}  // namespace

int runSlimUiApplication(int argc, char* argv[], const QString& version) {
    QQuickStyle::setStyle("Material");

    QGuiApplication app(argc, argv);
    app.setApplicationName("Crankshaft Slim UI");
    app.setApplicationVersion(version);
    app.setOrganizationName("OpenCarDev");
    app.setOrganizationDomain("opencardev.org");

    QCommandLineParser parser;
    parser.setApplicationDescription("Lightweight AndroidAuto UI for Crankshaft");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption debugOption(QStringList() << "d" << "debug",
                                   "Enable debug logging (same as SLIM_UI_DEBUG=1)");
    parser.addOption(debugOption);

    QCommandLineOption touchDebugOption(QStringList() << "touch-debug",
                                        "Enable the AA touch-coordinate diagnostic overlay (toggle with F12)");
    parser.addOption(touchDebugOption);

    QCommandLineOption platformOption(QStringList() << "p" << "platform",
                                      "Qt platform plugin (e.g., eglfs, vnc:port=5900, xcb)",
                                      "platform");
    parser.addOption(platformOption);

    parser.process(app);

    const QString logLevel = qEnvironmentVariable("SLIM_UI_LOG_LEVEL", "info").trimmed().toLower();
    QString logFilePath =
        qEnvironmentVariable("SLIM_UI_LOG_FILE", "/var/log/crankshaft/ui_slim.log");
#ifdef Q_OS_WIN
    if (logFilePath.isEmpty() || logFilePath.startsWith('/')) {
        const QString appDataPath =
            QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        const QString fallbackBase = appDataPath.isEmpty() ? QStringLiteral(".") : appDataPath;
        logFilePath = QDir(fallbackBase).filePath(QStringLiteral("ui_slim.log"));
    }
#endif

    Logger::instance().setLogFile(logFilePath);

    bool debugMode = parser.isSet(debugOption) || qEnvironmentVariableIsSet("SLIM_UI_DEBUG");
    const bool touchDebugMode = parser.isSet(touchDebugOption) ||
                                qEnvironmentVariableIsSet("SLIM_UI_TOUCH_DEBUG");

    if (debugMode || logLevel == "debug") {
        Logger::instance().setLevel(Logger::Level::Debug);
        Logger::instance().infoContext("Main", "Debug logging enabled");
    } else if (logLevel == "warning") {
        Logger::instance().setLevel(Logger::Level::Warning);
    } else if (logLevel == "error") {
        Logger::instance().setLevel(Logger::Level::Error);
    } else {
        Logger::instance().setLevel(Logger::Level::Info);
    }

    Logger::instance().infoContext(
        "Main", "Logging configured",
        {{"level", debugMode ? QStringLiteral("debug") : logLevel}, {"file_path", logFilePath}});

    Logger::instance().infoContext(
        "Main", "Starting Crankshaft Slim UI",
        {{"version", version}, {"platform", QGuiApplication::platformName()}});

    ServiceProvider& services = ServiceProvider::instance();
    if (!services.initialize()) {
        Logger::instance().errorContext("Main", "Failed to initialize core services");
        return 1;
    }

    int exitCode = 0;

    {
        AndroidAutoFacade androidAutoFacade(&services);
        AndroidAutoWebRtcSession androidAutoWebRtcSession(&androidAutoFacade);
        AndroidAutoWebRtcReceiver androidAutoWebRtcReceiver(&androidAutoWebRtcSession);
        DeviceManager deviceManager(&services, &androidAutoFacade);
        AudioBridge audioBridge(&services);
        BluetoothAdapter bluetoothAdapter(services.androidAutoService());
        TouchEventForwarder touchForwarder(&androidAutoFacade, &services);
        ConnectionStateMachine connectionStateMachine(&androidAutoFacade);

        PreferencesFacade preferencesFacade(&services);
        ErrorHandler errorHandler;

        // Tell core whether to look for the phone over USB or wireless: on every
        // (re)connection to core, and whenever the user changes the preference.
        ProjectionInfoFacade projectionInfo;
        if (CoreClient* coreClient = services.androidAutoService()) {
            QObject::connect(coreClient, &CoreClient::projectionInfoReceived, &projectionInfo,
                             &ProjectionInfoFacade::handleEvent);
        }

        if (CoreClient* coreClient = services.androidAutoService()) {
            const auto publishConnectionMode = [coreClient, &preferencesFacade]() {
                coreClient->publish(
                    QStringLiteral("android-auto/connection-mode"),
                    QJsonObject{{QStringLiteral("mode"),
                                 preferencesFacade.connectionPreference().toLower()}});
            };
            QObject::connect(coreClient, &CoreClient::coreConnected, &preferencesFacade,
                             publishConnectionMode);
            QObject::connect(&preferencesFacade, &PreferencesFacade::connectionPreferenceChanged,
                             coreClient, [publishConnectionMode](const QString&) {
                                 publishConnectionMode();
                             });
        }

        // Sound outputs (jack, HDMI, USB, Bluetooth) and where AA audio plays.
        AudioOutputManager audioOutputs;
        QObject::connect(&audioOutputs, &AudioOutputManager::ready, &preferencesFacade,
                         [&audioOutputs, &preferencesFacade]() {
                             // Restore the user's output if it is plugged in, and their volume.
                             const QString wanted = preferencesFacade.audioOutputDevice();
                             if (!wanted.isEmpty() && wanted != audioOutputs.currentOutput() &&
                                 audioOutputs.hasOutput(wanted)) {
                                 audioOutputs.selectOutput(wanted);
                             }
                             audioOutputs.setVolume(preferencesFacade.audioVolume());
                         });
        QObject::connect(&audioOutputs, &AudioOutputManager::outputSelected, &preferencesFacade,
                         [&audioOutputs, &preferencesFacade](const QString& name) {
                             preferencesFacade.setAudioOutputDevice(name);
                             // Each output keeps its own volume; carry the slider's over.
                             audioOutputs.setVolume(preferencesFacade.audioVolume());
                         });
        QObject::connect(&preferencesFacade, &PreferencesFacade::audioVolumeChanged,
                         &audioOutputs, [&audioOutputs](int volume) {
                             audioOutputs.setVolume(volume);
                         });
        audioOutputs.refresh();

        if (CoreClient* coreClient = services.androidAutoService()) {
            const auto publishAudioOutput = [coreClient, &preferencesFacade]() {
                coreClient->publish(
                    QStringLiteral("android-auto/audio-output"),
                    QJsonObject{{QStringLiteral("target"),
                                 preferencesFacade.audioOutputTarget().toLower()}});
            };
            QObject::connect(coreClient, &CoreClient::coreConnected, &preferencesFacade,
                             publishAudioOutput);
            QObject::connect(&preferencesFacade, &PreferencesFacade::audioOutputTargetChanged,
                             coreClient, [publishAudioOutput](const QString&) {
                                 publishAudioOutput();
                             });
        }

        if (!audioBridge.initialize()) {
            Logger::instance().warningContext(
                "Main", "Audio initialization failed, continuing without audio");
            errorHandler.reportError(ErrorHandler::ErrorCode::AudioBackendUnavailable,
                                     "Audio system initialization failed",
                                     ErrorHandler::Severity::Warning);
        }

        QQmlApplicationEngine engine;

        QObject::connect(&engine, &QQmlEngine::warnings, [](const QList<QQmlError>& warnings) {
            for (const QQmlError& warning : warnings) {
                Logger::instance().errorContext("QML", warning.toString());
            }
        });

        engine.rootContext()->setContextProperty("_serviceProvider", &services);
        engine.rootContext()->setContextProperty("_androidAutoFacade", &androidAutoFacade);
        engine.rootContext()->setContextProperty("_androidAutoWebRtcSession", &androidAutoWebRtcSession);
        engine.rootContext()->setContextProperty("_androidAutoWebRtcReceiver", &androidAutoWebRtcReceiver);
        engine.rootContext()->setContextProperty("_deviceManager", &deviceManager);
        engine.rootContext()->setContextProperty("_audioBridge", &audioBridge);
        engine.rootContext()->setContextProperty("_bluetoothService", &bluetoothAdapter);
        engine.rootContext()->setContextProperty("_touchForwarder", &touchForwarder);
        engine.rootContext()->setContextProperty("_connectionStateMachine", &connectionStateMachine);
        engine.rootContext()->setContextProperty("_preferencesFacade", &preferencesFacade);
        engine.rootContext()->setContextProperty("_audioOutputs", &audioOutputs);
        engine.rootContext()->setContextProperty("_errorHandler", &errorHandler);
        engine.rootContext()->setContextProperty("_touchDebugEnabled", touchDebugMode);
        engine.rootContext()->setContextProperty("_projectionInfo", &projectionInfo);
        // MK4-navigation-style menu is on by default; CRANKSHAFT_UI_STYLE=classic turns it off.
        engine.rootContext()->setContextProperty(
            "_mk4Enabled",
            qEnvironmentVariable("CRANKSHAFT_UI_STYLE").compare(QStringLiteral("classic"),
                                                               Qt::CaseInsensitive) != 0);

        if (touchDebugMode) {
            Logger::instance().infoContext(
                "Main",
                "Touch debug overlay enabled (toggle with F12)");
        }

        const QUrl url(QStringLiteral("qrc:/qml/main.qml"));

        QObject::connect(
            &engine, &QQmlApplicationEngine::objectCreated, &app,
            [url](QObject* obj, const QUrl& objUrl) {
                if (!obj && url == objUrl) {
                    Logger::instance().errorContext("Main", "Failed to load QML",
                                                    {{"url", url.toString()}});
                    QCoreApplication::exit(-1);
                }
            },
            Qt::QueuedConnection);

        engine.load(url);

        if (engine.rootObjects().isEmpty()) {
            Logger::instance().errorContext("Main", "No root QML objects created");
            return -1;
        }

        sendSystemdNotify("READY=1\nSTATUS=Running\n");

        QTimer watchdogTimer;
        const int intervalMs = watchdogIntervalMs();
        if (intervalMs > 0) {
            QObject::connect(&watchdogTimer, &QTimer::timeout, []() {
                sendSystemdNotify("WATCHDOG=1\nSTATUS=Running\n");
            });
            watchdogTimer.start(intervalMs);
            sendSystemdNotify("WATCHDOG=1\nSTATUS=Running\n");
            Logger::instance().infoContext("Main",
                                           QString("Systemd watchdog heartbeat enabled (%1ms)")
                                               .arg(intervalMs));
        }

        Logger::instance().infoContext("Main", "Application started successfully");

        exitCode = app.exec();

        watchdogTimer.stop();
        sendSystemdNotify("STOPPING=1\nSTATUS=Stopping\n");
        Logger::instance().infoContext("Main", "Shutting down", {{"exitCode", exitCode}});
    }

    services.shutdown();

    return exitCode;
}
