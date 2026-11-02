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
 * The car's IBus as seen by core (ibus/status, ibus/obc, ibus/input topics):
 * on-board computer values from the cluster, interface status, and BMBT /
 * steering wheel buttons. Exposed to QML as _ibus.
 */
class IbusFacade : public QObject {
    Q_OBJECT
    /// The USB interface is open.
    Q_PROPERTY(bool connected READ connected NOTIFY statusChanged)
    /// Traffic seen on the bus recently (ignition on or car awake).
    Q_PROPERTY(bool busAwake READ busAwake NOTIFY statusChanged)
    Q_PROPERTY(QVariantMap status READ status NOTIFY statusChanged)
    /// time, outsideTemp, consumption1, range, avgSpeed, speedKmh, rpm, units...
    Q_PROPERTY(QVariantMap obc READ obc NOTIFY obcChanged)
    /// Parking sensors (PDC) while reversing: visible, reverse, active,
    /// frontLeft..rearRight in cm (255 = nothing in range, -1 = unknown).
    Q_PROPERTY(QVariantMap parking READ parking NOTIFY parkingChanged)

  public:
    explicit IbusFacade(CoreClient* coreClient, QObject* parent = nullptr)
        : QObject(parent), m_coreClient(coreClient) {
        if (m_coreClient) {
            connect(m_coreClient, &CoreClient::ibusEventReceived, this, &IbusFacade::handleEvent);
            // Core forgets the input target when it restarts.
            connect(m_coreClient, &CoreClient::coreConnected, this,
                    [this]() { publishInputTarget(); });
        }
    }

    [[nodiscard]] auto connected() const -> bool {
        return m_status.value(QStringLiteral("connected")).toBool();
    }
    [[nodiscard]] auto busAwake() const -> bool {
        return m_status.value(QStringLiteral("busAwake")).toBool();
    }
    [[nodiscard]] auto status() const -> QVariantMap { return m_status; }
    [[nodiscard]] auto obc() const -> QVariantMap { return m_obc; }
    [[nodiscard]] auto parking() const -> QVariantMap { return m_parking; }

    /// GT 0x41 to the cluster: property 0x04 consumption 1, 0x0A avg speed,
    /// 0x09 limit, 0x0E timer...; control 0x04 on, 0x08 off, 0x10 reset, 0x20 set.
    Q_INVOKABLE void obcControl(int property, int control) {
        if (!m_coreClient) {
            return;
        }
        QJsonObject payload;
        payload[QStringLiteral("property")] = property;
        payload[QStringLiteral("control")] = control;
        m_coreClient->publish(QStringLiteral("ibus/obc-control"), payload);
    }

    /// "ui" while a Crankshaft screen is on top (car buttons drive it), else
    /// "android-auto" (car buttons go to Android Auto).
    Q_INVOKABLE void setInputTarget(const QString& target) {
        if (target == m_inputTarget) {
            return;
        }
        m_inputTarget = target;
        publishInputTarget();
    }

    /// Show the Android Auto line on the cluster again after the BC button
    /// paused it (it also comes back by itself with the next song or turn).
    Q_INVOKABLE void resumeClusterText() {
        if (m_coreClient) {
            m_coreClient->publish(QStringLiteral("ibus/cluster-text-resume"), QJsonObject{});
        }
    }

  public slots:
    void handleEvent(const QString& topic, const QVariantMap& payload) {
        if (topic == QStringLiteral("ibus/status")) {
            m_status = payload;
            emit statusChanged();
        } else if (topic == QStringLiteral("ibus/obc")) {
            m_obc = payload;
            emit obcChanged();
        } else if (topic == QStringLiteral("ibus/parking")) {
            m_parking = payload;
            emit parkingChanged();
        } else if (topic == QStringLiteral("ibus/input")) {
            emit inputReceived(payload);
        }
    }

  signals:
    void statusChanged();
    void obcChanged();
    void parkingChanged();
    /// {kind: button|dial, source: bmbt|mfl, button, state: press|hold|release, steps}
    void inputReceived(const QVariantMap& event);

  private:
    void publishInputTarget() {
        if (!m_coreClient) {
            return;
        }
        QJsonObject payload;
        payload[QStringLiteral("target")] = m_inputTarget;
        m_coreClient->publish(QStringLiteral("ibus/input-target"), payload);
    }

    QPointer<CoreClient> m_coreClient;
    QVariantMap m_status;
    QVariantMap m_obc;
    QVariantMap m_parking;
    QString m_inputTarget = QStringLiteral("android-auto");
};
