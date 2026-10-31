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
#include <QVariantMap>

/**
 * Now playing, turn-by-turn guidance and the derived 20-character cluster
 * (IKE) line, as reported by core from the phone's Android Auto session.
 * Exposed to QML as _projectionInfo.
 */
class ProjectionInfoFacade : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap nowPlaying READ nowPlaying NOTIFY nowPlayingChanged)
    Q_PROPERTY(QVariantMap navigation READ navigation NOTIFY navigationChanged)
    Q_PROPERTY(QVariantMap clusterText READ clusterText NOTIFY clusterTextChanged)

  public:
    explicit ProjectionInfoFacade(QObject* parent = nullptr) : QObject(parent) {}

    [[nodiscard]] auto nowPlaying() const -> QVariantMap { return m_nowPlaying; }
    [[nodiscard]] auto navigation() const -> QVariantMap { return m_navigation; }
    [[nodiscard]] auto clusterText() const -> QVariantMap { return m_clusterText; }

  public slots:
    void handleEvent(const QString& topic, const QVariantMap& payload) {
        if (topic == QStringLiteral("android-auto/status/now-playing")) {
            m_nowPlaying = payload;
            emit nowPlayingChanged();
        } else if (topic == QStringLiteral("android-auto/status/navigation")) {
            m_navigation = payload;
            emit navigationChanged();
        } else if (topic == QStringLiteral("android-auto/status/cluster-text")) {
            m_clusterText = payload;
            emit clusterTextChanged();
        }
    }

  signals:
    void nowPlayingChanged();
    void navigationChanged();
    void clusterTextChanged();

  private:
    QVariantMap m_nowPlaying;
    QVariantMap m_navigation;
    QVariantMap m_clusterText;
};
