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

#include <QCursor>
#include <QEvent>
#include <QGuiApplication>
#include <QMouseEvent>
#include <QObject>
#include <QTimer>

/**
 * Hides the mouse pointer on a touch head unit. The pointer is hidden at
 * start, on any touch or tap, and after a few seconds without mouse movement.
 * It only comes back while a real mouse is moved with no button held, so
 * touch panels that report taps as mouse clicks never leave a pointer on
 * screen.
 */
class CursorAutoHider : public QObject {
    Q_OBJECT

  public:
    explicit CursorAutoHider(int idleMs = 3000, QObject* parent = nullptr) : QObject(parent) {
        m_idle.setSingleShot(true);
        m_idle.setInterval(idleMs);
        connect(&m_idle, &QTimer::timeout, this, &CursorAutoHider::hide);
        hide();
    }

    ~CursorAutoHider() override {
        if (m_hidden) {
            QGuiApplication::restoreOverrideCursor();
        }
    }

  protected:
    auto eventFilter(QObject* watched, QEvent* event) -> bool override {
        switch (event->type()) {
            case QEvent::MouseMove: {
                const auto* mouse = static_cast<QMouseEvent*>(event);
                if (mouse->source() == Qt::MouseEventNotSynthesized &&
                    mouse->buttons() == Qt::NoButton) {
                    show();
                }
                break;
            }
            case QEvent::MouseButtonPress:
            case QEvent::TouchBegin:
            case QEvent::TouchUpdate:
                hide();
                break;
            default:
                break;
        }
        return QObject::eventFilter(watched, event);
    }

  private:
    void show() {
        if (m_hidden) {
            QGuiApplication::restoreOverrideCursor();
            m_hidden = false;
        }
        m_idle.start();
    }

    void hide() {
        m_idle.stop();
        if (!m_hidden) {
            QGuiApplication::setOverrideCursor(QCursor(Qt::BlankCursor));
            m_hidden = true;
        }
    }

    QTimer m_idle;
    bool m_hidden{false};
};
