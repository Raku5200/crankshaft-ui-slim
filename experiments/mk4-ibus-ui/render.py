"""Render the MK4 experiment screens at 800x480: python3 render.py <out_dir>"""
import os, sys
from PySide6.QtCore import QObject, QTimer, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow

here = os.path.dirname(os.path.abspath(__file__))
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "screens")
os.makedirs(out, exist_ok=True)
app = QGuiApplication(sys.argv)
engine = QQmlApplicationEngine()
engine.load(QUrl.fromLocalFile(os.path.join(here, "main.qml")))
if not engine.rootObjects():
    sys.exit("failed to load main.qml")
win = engine.rootObjects()[0]
if not isinstance(win, QQuickWindow):
    import shiboken6
    win = shiboken6.wrapInstance(shiboken6.getCppPointer(win)[0], QQuickWindow)
child = lambda n: win.findChild(QObject, n)

def shot(name):
    return lambda: win.grabWindow().save(os.path.join(out, name))

def setp(obj, prop, val):
    return lambda: (child(obj) if obj else win).setProperty(prop, val)

steps = [
    (900, shot("1-android-auto.png")),
    (10, setp(None, "page", "menu")), (10, setp("menuPage", "focusIndex", 0)),
    (500, shot("2-main-menu.png")),
    (10, setp("menuPage", "focusIndex", 3)),
    (400, shot("3-main-menu-computer.png")),
    (10, setp(None, "page", "computer")), (10, setp("computerPage", "focusIndex", 3)),
    (500, shot("4-computer.png")),
    (10, setp(None, "page", "vehicle")),
    (900, shot("5-vehicle.png")),
    (10, setp(None, "page", "settings")), (10, setp("settingsPage", "focusIndex", 0)),
    (400, shot("6-settings.png")),
    (10, setp("settingsPage", "infoBar", False)), (10, setp(None, "lastAaSection", "media")),
    (10, setp(None, "page", "aa")),
    (500, shot("7-android-auto-media-no-bar.png")),
    (100, app.quit),
]
t = 0
for d, fn in steps:
    t += d
    QTimer.singleShot(t, fn)
app.exec()
