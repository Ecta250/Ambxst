pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool bypassed: false
    property var outputPresets: []
    property var inputPresets: []
    property string activeOutputPreset: ""
    property string activeInputPreset: ""

    function toggleBypass() {
        bypassToggleProcess.command = ["easyeffects", "-b", bypassed ? "2" : "1"];
        bypassToggleProcess.running = true;
    }

    function setBypass(enable: bool) {
        bypassToggleProcess.command = ["easyeffects", "-b", enable ? "1" : "2"];
        bypassToggleProcess.running = true;
    }

    function loadOutputPreset(name: string) {
        root.activeOutputPreset = name;
        loadPresetProcess.command = ["easyeffects", "-l", name];
        loadPresetProcess.running = true;
    }

    function loadInputPreset(name: string) {
        root.activeInputPreset = name;
        loadPresetProcess.command = ["easyeffects", "-l", name];
        loadPresetProcess.running = true;
    }

    function loadPreset(name: string) {
        loadPresetProcess.command = ["easyeffects", "-l", name];
        loadPresetProcess.running = true;
    }

    function refresh() {
        checkAvailableProcess.running = true;
    }

    function openApp() {
        Quickshell.execDetached(["easyeffects"]);
    }

    property bool _initialized: false
    property bool _fetchingInitialState: false

    function initialize() {
        if (_initialized) return;
        _initialized = true;
        checkAvailableProcess.running = true;
    }

    // Check if EasyEffects is actually running before querying it.
    // Using pgrep instead of `which` prevents queries from spawning a fresh
    // primary instance when no service is running (which caused the brief flash).
    Process {
        id: checkAvailableProcess
        command: ["pgrep", "-x", "easyeffects"]
        running: false
        onExited: (exitCode, exitStatus) => {
            const running = (exitCode === 0);
            if (running && !root.available) {
                root.available = true;
                root._fetchingInitialState = true;
                bypassStateProcess.running = true;
            } else if (!running) {
                root.available = false;
            }
        }
    }

    // Get bypass state
    Process {
        id: bypassStateProcess
        command: ["easyeffects", "-b", "3"]
        running: false
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: SplitParser {
            onRead: data => {
                const val = data.trim();
                root.bypassed = (val === "1");
            }
        }
        onExited: {
            if (root._fetchingInitialState) {
                presetsProcess.running = true;
            }
        }
    }

    Process {
        id: bypassToggleProcess
        running: false
        onExited: {
            bypassStateProcess.running = true;
        }
    }

    Process {
        id: loadPresetProcess
        running: false
        onExited: {
            refreshDelayTimer.restart();
        }
    }

    property var refreshDelayTimer: Timer {
        id: refreshDelayTimer
        interval: 100
        repeat: false
        onTriggered: {
            activeOutputPresetProcess.running = true;
        }
    }

    Process {
        id: presetsProcess
        command: ["easyeffects", "-p"]
        running: false
        property string buffer: ""
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: SplitParser {
            onRead: data => {
                presetsProcess.buffer += data + "\n";
            }
        }
        onExited: {
            const text = presetsProcess.buffer;
            presetsProcess.buffer = "";

            const lines = text.split("\n");
            let isOutput = false;
            let isInput = false;
            let outputList = [];
            let inputList = [];

            for (const line of lines) {
                const trimmed = line.trim();
                if (trimmed.toLowerCase().includes("output")) {
                    isOutput = true;
                    isInput = false;
                    const parts = trimmed.split(":");
                    if (parts.length > 1 && parts[1].trim()) {
                        outputList = parts[1].trim().split(",").map(p => p.trim()).filter(p => p);
                    }
                } else if (trimmed.toLowerCase().includes("input")) {
                    isInput = true;
                    isOutput = false;
                    const parts = trimmed.split(":");
                    if (parts.length > 1 && parts[1].trim()) {
                        inputList = parts[1].trim().split(",").map(p => p.trim()).filter(p => p);
                    }
                } else if (trimmed && !trimmed.includes(":")) {
                    if (isOutput) outputList.push(trimmed);
                    else if (isInput) inputList.push(trimmed);
                }
            }

            root.outputPresets = outputList;
            root.inputPresets = inputList;

            // EasyEffects 8.x requires `easyeffects -a output` / `easyeffects -a input`
            // (argument is mandatory). Chain them sequentially after presets.
            if (root._fetchingInitialState) {
                activeOutputPresetProcess.running = true;
            }
        }
    }

    // EasyEffects 8.x: -a requires explicit type argument
    Process {
        id: activeOutputPresetProcess
        command: ["easyeffects", "-a", "output"]
        running: false
        property string buffer: ""
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: SplitParser {
            onRead: data => {
                activeOutputPresetProcess.buffer += data + "\n";
            }
        }
        onExited: {
            const name = activeOutputPresetProcess.buffer.trim();
            if (name) root.activeOutputPreset = name;
            activeOutputPresetProcess.buffer = "";
            activeInputPresetProcess.running = true;
        }
    }

    Process {
        id: activeInputPresetProcess
        command: ["easyeffects", "-a", "input"]
        running: false
        property string buffer: ""
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: SplitParser {
            onRead: data => {
                activeInputPresetProcess.buffer += data + "\n";
            }
        }
        onExited: {
            const name = activeInputPresetProcess.buffer.trim();
            if (name) root.activeInputPreset = name;
            activeInputPresetProcess.buffer = "";
            root._fetchingInitialState = false;
        }
    }

    // Poll pgrep to detect when EasyEffects starts or stops, then query state.
    // Running always (not gated on available) so the panel auto-updates when
    // the user starts EasyEffects after settings is already open.
    property var pollTimer: Timer {
        interval: 5000
        running: !SuspendManager.isSuspending
        repeat: true
        onTriggered: {
            pollCheckProcess.running = true;
        }
    }

    Process {
        id: pollCheckProcess
        command: ["pgrep", "-x", "easyeffects"]
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                if (!root.available) {
                    // EasyEffects just became available — do a full fetch
                    root.available = true;
                    root._initialized = true;
                    root._fetchingInitialState = true;
                    bypassStateProcess.running = true;
                } else {
                    bypassStateProcess.running = true;
                }
            } else {
                if (root.available) {
                    root.available = false;
                    root._initialized = false;
                    root._fetchingInitialState = false;
                }
            }
        }
    }
}
