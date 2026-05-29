pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Plugins

Singleton {
    id: root

    property var displays: []
    property var rawOutputs: ({} )
    property int wlMirrorPid: 0
    readonly property bool mirrorRunning: wlMirrorPid > 0

    readonly property string activeProfile: {
        const list = root.displays || [];
        if (list.length === 0) return "";
        const internal = list.filter(d => root.isInternal(d));
        const external = list.filter(d => !root.isInternal(d));
        
        const anyInternalEnabled = internal.some(d => !d.disabled);
        const anyExternalEnabled = external.some(d => !d.disabled);
        
        if (anyInternalEnabled && !anyExternalEnabled) {
            return "internal_only";
        }
        if (!anyInternalEnabled && anyExternalEnabled) {
            return "external_only";
        }
        if (anyInternalEnabled && anyExternalEnabled) {
            return root.mirrorRunning ? "mirror" : "extend";
        }
        return "";
    }

    property string focusedOutputName: ""

    readonly property string mirrorSourceFriendly: {
        if (displays.length < 2) return "";
        let source = displays.find(d => d.name === root.focusedOutputName);
        if (!source) {
            source = displays.find(d => isInternal(d)) || displays[0];
        }
        return source ? source.friendlyName : "";
    }

    readonly property string mirrorTargetFriendly: {
        if (displays.length < 2) return "";
        let source = displays.find(d => d.name === root.focusedOutputName);
        if (!source) {
            source = displays.find(d => isInternal(d)) || displays[0];
        }
        let target = displays.find(d => d.name !== source.name);
        return target ? target.friendlyName : "";
    }

    function detectFocusedOutput(callback): void {
        Proc.runCommand("niriDS:focusedOutput", ["niri", "msg", "focused-output"], (output, exitCode) => {
            if (exitCode === 0) {
                let cleaned = output.replace(/^(Output\s+|Focused\s+output:\s*)/i, "").trim();
                let parts = cleaned.split(/[\s(]/);
                let name = parts[0].trim();
                if (name) {
                    root.focusedOutputName = name;
                    console.log("niriDS: Resolved focused output name:", root.focusedOutputName);
                }
            }
            if (callback) callback();
        });
    }

    // Launcher for background wl-mirror execution
    Process {
        id: mirrorLauncher
        command: ["sh", "-c", ""]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim();
                const pid = parseInt(trimmed);
                if (!isNaN(pid) && pid > 0) {
                    root.wlMirrorPid = pid;
                    console.log("niriDS: Started wl-mirror with PID:", pid);
                } else if (trimmed.length > 0) {
                    console.warn("niriDS: wl-mirror output:", trimmed);
                }
            }
        }
    }

    Timer {
        id: mirrorDelayTimer
        interval: 1000
        repeat: false
        onTriggered: {
            root.startMirrorProcess();
        }
    }

    function stopMirror(): void {
        Quickshell.execDetached(["sh", "-c", "pkill -f wl-mirror 2>/dev/null"]);
        root.wlMirrorPid = 0;
        if (mirrorLauncher.running) mirrorLauncher.running = false;
    }

    readonly property var internalPrefixes: ["edp", "lvds"]

    function isInternalName(name) {
        if (!name) return false;
        const lower = name.toLowerCase();
        return internalPrefixes.some(prefix => lower.startsWith(prefix));
    }

    function isInternal(display) {
        if (!display || !display.name) return false;

        let preferred = "";
        try {
            preferred = PluginService.loadPluginData("niriDS", "fallbackDisplay", "");
        } catch (e) {}

        if (preferred && display.name === preferred) return true;

        return isInternalName(display.name);
    }

    function setDisplays() {
        Proc.runCommand("niriDS:checkMirror", ["pgrep", "-f", "wl-mirror"], (out, code) => {
            const running = (code === 0 && out.trim().length > 0);
            if (!running && root.wlMirrorPid > 0) {
                root.wlMirrorPid = 0;
            }
        });

        Proc.runCommand("niriDS:getOutputs", ["niri", "msg", "--json", "outputs"], (output, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const parsed = JSON.parse(output);
                root.rawOutputs = parsed;
                const arr = [];
                for (const name in parsed) {
                    const raw = parsed[name];
                    const internal = isInternal({ name: name });
                    const hasLogical = raw.logical && typeof raw.logical === 'object';
                    let friendly = internal ? "Laptop Screen" : ((raw.make && raw.model) ? (raw.make + " " + raw.model) : name);

                    arr.push({
                        name: name,
                        friendlyName: friendly,
                        disabled: !hasLogical,
                        logical: hasLogical ? raw.logical : null,
                        isInternal: internal
                    });
                }
                arr.sort((a, b) => {
                    if (a.isInternal !== b.isInternal) return a.isInternal ? -1 : 1;
                    return a.name.localeCompare(b.name);
                });
                arr.forEach(d => delete d.isInternal);
                root.displays = arr;
            } catch (e) {
                console.warn("niriDS: setDisplays failed:", e);
            }
        });
    }

    function toggleDisable(display: var): void {
        if (!display || !display.name) return;
        stopMirror();
        const action = display.disabled ? "on" : "off";
        Proc.runCommand("niriDS:toggle", ["niri", "msg", "output", display.name, action], (out, code) => {
            if (code === 0) setDisplays();
        });
    }

    function apply(profile: string): void {
        stopMirror();
        const toProcess = [...displays];
        if (toProcess.length === 0) return;

        const internal = toProcess.filter(d => isInternal(d));
        const external = toProcess.filter(d => !isInternal(d));

        function enableAll(callback) {
            function enableNext(i) {
                if (i >= toProcess.length) {
                    callback();
                    return;
                }
                Proc.runCommand("niriDS:enable", ["niri", "msg", "output", toProcess[i].name, "on"], () => enableNext(i + 1));
            }
            enableNext(0);
        }

        function disableExternal(callback) {
            function disableNext(i) {
                if (i >= external.length) {
                    callback();
                    return;
                }
                Proc.runCommand("niriDS:disable", ["niri", "msg", "output", external[i].name, "off"], () => disableNext(i + 1));
            }
            disableNext(0);
        }

        function disableInternal(callback) {
            function disableNext(i) {
                if (i >= internal.length) {
                    callback();
                    return;
                }
                Proc.runCommand("niriDS:disable", ["niri", "msg", "output", internal[i].name, "off"], () => disableNext(i + 1));
            }
            disableNext(0);
        }

        function finish() {
            Qt.callLater(() => setDisplays());
        }

        if (profile === "internal_only") {
            enableAll(() => {
                disableExternal(() => finish());
            });
        } else if (profile === "external_only") {
            enableAll(() => {
                disableInternal(() => finish());
            });
        } else if (profile === "extend") {
            enableAll(() => finish());
        } else if (profile === "mirror") {
            enableAll(() => {
                mirrorDisplay();
                finish();
            });
        } else {
            finish();
        }
    }

    function enableInternalDisplay(): void {
        Proc.runCommand("niriDS:fallbackCheck", ["niri", "msg", "--json", "outputs"], (output, exitCode) => {
            if (exitCode !== 0) {
                const pref = PluginService?.loadPluginData("niriDS", "fallbackDisplay", "") || "";
                if (pref) {
                    Proc.runCommand("niriDS:recover", ["niri", "msg", "output", pref, "on"], () => setDisplays());
                }
                return;
            }

            try {
                const parsed = JSON.parse(output);
                for (const name in parsed) {
                    if (isInternalName(name)) {
                        Proc.runCommand("niriDS:recover", ["niri", "msg", "output", name, "on"], () => setDisplays());
                        return;
                    }
                }
                const pref = PluginService?.loadPluginData("niriDS", "fallbackDisplay", "") || "";
                if (pref) {
                    Proc.runCommand("niriDS:recover", ["niri", "msg", "output", pref, "on"], () => setDisplays());
                }
            } catch (e) {
                console.warn("niriDS: enableInternalDisplay failed:", e);
            }
        });
    }

    function mirrorDisplay(): void {
        stopMirror();
        detectFocusedOutput(() => {
            mirrorDelayTimer.start();
        });
    }

    function startMirrorProcess(): void {
        if (displays.length < 2) return;
        
        let source = displays.find(d => d.name === root.focusedOutputName);
        let target = displays.find(d => d.name !== root.focusedOutputName);
        
        if (!source) {
            source = displays.find(d => isInternal(d)) || displays[0];
            target = displays.find(d => d.name !== source.name) || displays[1];
        }
        
        if (!source || !target) {
            console.warn("niriDS: Cannot mirror, source or target display is missing. Displays:", JSON.stringify(displays));
            return;
        }
        
        console.log("niriDS: Launching wl-mirror from source:", source.name, "to target:", target.name);
        
        // Launch wl-mirror in background detaching via sh, redirecting stderr to stdout for debugging, and capture its PID
        const cmd = "wl-mirror --fullscreen-output \"" + target.name + "\" \"" + source.name + "\" 2>&1 & echo $!";
        mirrorLauncher.command = ["sh", "-c", cmd];
        mirrorLauncher.running = true;
    }

    Component.onCompleted: Qt.callLater(() => {
        setDisplays();
        detectFocusedOutput();
    })
}
