pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Plugins

Singleton {
    id: root

    property var displays: []

    function getPluginData() {
        if (typeof PluginService !== 'undefined') {
            return PluginService.getPluginData("niriDS") || {};
        }
        return {};
    }

    function isInternal(display) {
        if (!display || !display.name) return false;
        const data = getPluginData();
        const preferred = data.fallbackDisplay || "";
        if (preferred && display.name === preferred) return true;
        const name = display.name.toLowerCase();
        return name.startsWith("edp") || name.startsWith("lvds");
    }

    function setDisplays() {
        Proc.runCommand("niriDS:setDisplays", ["niri", "msg", "--json", "outputs"], (output, exitCode) => {
            if (exitCode != 0) return;
            try {
                const parsed = JSON.parse(output);
                const arr = [];
                for (const name in parsed) {
                    const rawDisp = parsed[name];
                    // Create a clean new object to ensure QML properties work correctly
                    const disp = {
                        name: name,
                        make: rawDisp.make || "",
                        model: rawDisp.model || "",
                        disabled: !rawDisp.logical,
                        logical: rawDisp.logical || null
                    };
                    arr.push(disp);
                }
                root.displays = arr;
                console.log("[NiriDS] Updated displays list, count:", arr.length);
            } catch (e) {
                console.error("[NiriDS] Failed to parse outputs:", e);
            }
        });
    }

    Component.onCompleted: {
        setDisplays();
    }

    function toggleDisable(display: var): void {
        if (!display || !display.name) return;
        const action = display.disabled ? "on" : "off";
        Proc.runCommand("niriDS:toggle", ["niri", "msg", "output", display.name, action], (output, exitCode) => {
            if (exitCode == 0) setDisplays();
        });
    }

    function apply(profileName: string): void {
        const displaysToProcess = [...displays];
        if (displaysToProcess.length === 0) return;

        function processNext(index) {
            if (index >= displaysToProcess.length) {
                setDisplays();
                return;
            }
            const disp = displaysToProcess[index];
            const internal = isInternal(disp);
            let action = "on";
            if (profileName === "internal_only") action = internal ? "on" : "off";
            else if (profileName === "external_only") action = internal ? "off" : "on";
            Proc.runCommand("niriDS:apply", ["niri", "msg", "output", disp.name, action], () => processNext(index + 1));
        }
        processNext(0);
    }

    function fallbackIfUnplugged(): void {
        Proc.runCommand("niriDS:fallback", ["niri", "msg", "--json", "outputs"], (output, exitCode) => {
            if (exitCode != 0) return;
            try {
                const parsed = JSON.parse(output);
                let activeExternalCount = 0;
                let internalDisplay = null;
                for (const name in parsed) {
                    const rawDisp = parsed[name];
                    const internal = name.toLowerCase().startsWith("edp") || name.toLowerCase().startsWith("lvds");
                    if (internal) internalDisplay = { name: name, logical: rawDisp.logical };
                    else if (rawDisp.logical) activeExternalCount++;
                }
                if (activeExternalCount === 0 && internalDisplay && !internalDisplay.logical) {
                    Proc.runCommand("niriDS:fallbackAct", ["niri", "msg", "output", internalDisplay.name, "on"], () => setDisplays());
                }
            } catch (e) {}
        });
    }
}
