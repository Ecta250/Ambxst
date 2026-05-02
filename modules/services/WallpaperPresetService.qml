pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.globals
import qs.config

Singleton {
    id: root

    property int sequenceIndex: 0
    property bool startupRotationPending: false

    // True once both the config and the wallpaper manager are ready.
    // Config.wallpaperReady fires early; GlobalStates.wallpaperManager is set
    // later by Wallpaper.qml's Component.onCompleted, so we watch both.
    readonly property bool ready: Config.wallpaperReady && GlobalStates.wallpaperManager !== null

    // True once the manager has finished scanning its wallpaper directory.
    readonly property bool pathsAvailable: GlobalStates.wallpaperManager !== null
                                        && GlobalStates.wallpaperManager.wallpaperPaths.length > 0

    onReadyChanged: {
        if (!ready) return;
        updateRotationTimer();
        if (Config.wallpaper.rotationEnabled && Config.wallpaper.rotationOnStartup) {
            // If using a custom folder the scan happens inside rotateWallpaper itself,
            // so we can fire immediately. Otherwise wait until paths are loaded.
            if (Config.wallpaper.rotationFolder !== "" || pathsAvailable) {
                Qt.callLater(rotateWallpaper);
            } else {
                startupRotationPending = true;
            }
        } else if (Config.wallpaper.enabled && !Config.wallpaper.rotationEnabled) {
            Qt.callLater(applyStaticWallpaper);
        }
    }

    // Once wallpaperPaths are populated, fulfil any pending startup rotation.
    onPathsAvailableChanged: {
        if (pathsAvailable && startupRotationPending) {
            startupRotationPending = false;
            rotateWallpaper();
        }
    }

    // Fires when wallpaper.json is reloaded from disk (i.e. a preset was applied).
    Connections {
        target: Config
        function onWallpaperConfigReloaded() {
            if (!root.ready) return;
            updateRotationTimer();
            if (Config.wallpaper.enabled && !Config.wallpaper.rotationEnabled) {
                applyStaticWallpaper();
            }
        }
    }

    Timer {
        id: rotationTimer
        repeat: true
        running: false
        onTriggered: root.rotateWallpaper()
    }

    function updateRotationTimer() {
        if (Config.wallpaper.rotationEnabled && Config.wallpaper.rotationInterval > 0) {
            rotationTimer.interval = Config.wallpaper.rotationInterval * 1000;
            if (!rotationTimer.running) rotationTimer.start();
        } else {
            rotationTimer.stop();
        }
    }

    function applyStaticWallpaper() {
        var path = Config.wallpaper.wallpaper;
        if (!path || !GlobalStates.wallpaperManager) return;
        if (GlobalStates.wallpaperManager.currentWallpaper === path) return;
        GlobalStates.wallpaperManager.setWallpaper(path);
    }

    function rotateWallpaper() {
        if (!GlobalStates.wallpaperManager) return;
        var folder = Config.wallpaper.rotationFolder;
        if (folder) {
            scanFolderProcess.command = [
                "find", folder, "-name", ".*", "-prune", "-o", "-type", "f",
                "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png",
                "-o", "-name", "*.webp", "-o", "-name", "*.gif",
                "-o", "-name", "*.mp4", "-o", "-name", "*.webm", ")", "-print"
            ];
            scanFolderProcess.running = true;
        } else {
            pickAndApply(GlobalStates.wallpaperManager.wallpaperPaths);
        }
    }

    function pickAndApply(paths) {
        if (!paths || paths.length === 0) return;
        var idx;
        if (Config.wallpaper.rotationMode === "sequential") {
            idx = root.sequenceIndex % paths.length;
            root.sequenceIndex = (root.sequenceIndex + 1) % paths.length;
        } else {
            idx = Math.floor(Math.random() * paths.length);
        }
        GlobalStates.wallpaperManager.setWallpaper(paths[idx]);
    }

    Process {
        id: scanFolderProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.pickAndApply(text.trim().split('\n').filter(p => p.length > 0));
            }
        }
    }
}
