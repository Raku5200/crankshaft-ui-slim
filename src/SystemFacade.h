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

#include <QJsonObject>
#include <QObject>
#include <QPointer>
#include <QVariantMap>

#include "CoreClient.h"

/**
 * System actions handled by core (system/... topics). Exposed to QML as
 * _system. saveLogs() copies the logs to the SD card's boot partition
 * (crankshaft-logs folder), readable on any PC.
 */
class SystemFacade : public QObject {
    Q_OBJECT
    /// "", "saving", "done" or "error"
    Q_PROPERTY(QString logSaveState READ logSaveState NOTIFY logSaveChanged)
    /// Folder on the boot partition when done, the reason on error.
    Q_PROPERTY(QString logSaveMessage READ logSaveMessage NOTIFY logSaveChanged)

  public:
    explicit SystemFacade(CoreClient* coreClient, QObject* parent = nullptr)
        : QObject(parent), m_coreClient(coreClient) {
        if (m_coreClient) {
            connect(m_coreClient, &CoreClient::systemEventReceived, this,
                    &SystemFacade::handleEvent);
        }
    }

    [[nodiscard]] auto logSaveState() const -> QString { return m_logSaveState; }
    [[nodiscard]] auto logSaveMessage() const -> QString { return m_logSaveMessage; }

    Q_INVOKABLE void saveLogs() {
        if (!m_coreClient || m_logSaveState == QStringLiteral("saving")) {
            return;
        }
        m_logSaveState = QStringLiteral("saving");
        m_logSaveMessage.clear();
        emit logSaveChanged();
        m_coreClient->publish(QStringLiteral("system/save-logs"), QJsonObject{});
    }

  public slots:
    void handleEvent(const QString& topic, const QVariantMap& payload) {
        if (topic == QStringLiteral("system/save-logs-result")) {
            m_logSaveState = payload.value(QStringLiteral("state")).toString();
            m_logSaveMessage = payload.value(QStringLiteral("message")).toString();
            emit logSaveChanged();
        }
    }

  signals:
    void logSaveChanged();

  private:
    QPointer<CoreClient> m_coreClient;
    QString m_logSaveState;
    QString m_logSaveMessage;
};
