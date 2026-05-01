pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property bool launched: false

    Component.onCompleted: {
        if (Config.executeReady) _launch();
    }

    Connections {
        target: Config
        function onExecuteReadyChanged() {
            if (Config.executeReady && !root.launched) _launch();
        }
        function onExecuteConfigReloaded() {
            let entries = Config.execute.autostart ?? [];
            for (let i = 0; i < entries.length; i++) {
                let e = entries[i];
                if (e.enabled && e.execOnPreset && e.command)
                    _spawn(["bash", "-c", e.command], e.delay ?? 0, e.once !== false);
            }
        }
    }

    function _launch() {
        if (root.launched) return;
        root.launched = true;
        Qt.callLater(_runStartup);
    }

    function _runStartup() {
        let autostart = Config.execute.autostart ?? [];
        for (let i = 0; i < autostart.length; i++) {
            let e = autostart[i];
            if (e.enabled && e.command)
                _spawn(["bash", "-c", e.command], e.delay ?? 0, e.once !== false);
        }
        let hyprland = Config.execute.hyprland ?? [];
        for (let i = 0; i < hyprland.length; i++) {
            let e = hyprland[i];
            if (e.enabled && e.command)
                _spawn(["hyprctl", "dispatch", "exec", e.command], e.delay ?? 0, true);
        }
    }

    function _spawn(command, delaySecs, once) {
        let ms = Math.max(0, delaySecs) * 1000;
        if (ms > 0) {
            let t = Qt.createQmlObject('import QtQuick; Timer { repeat: false }', root);
            t.interval = ms;
            t.triggered.connect(() => { _fire(command, once); t.destroy(); });
            t.start();
        } else {
            _fire(command, once);
        }
    }

    function _fire(command, once) {
        let proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        proc.command = command;
        if (once) {
            proc.onExited.connect(() => proc.destroy());
        } else {
            proc.onExited.connect(() => Qt.callLater(() => { proc.running = true; }));
        }
        proc.running = true;
    }

    function runNow(command, type) {
        _fire(type === "hyprland" ? ["hyprctl", "dispatch", "exec", command] : ["bash", "-c", command], true);
    }
}
