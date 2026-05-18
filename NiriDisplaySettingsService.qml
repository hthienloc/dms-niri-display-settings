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

    function isInternal(display) {
        if (!display || !display.name) return false;
        
        // Use correct DMS API for loading plugin settings
        let preferred = "";
        try {
            preferred = PluginService.loadPluginData("niriDS", "fallbackDisplay", "");
        } catch (e) {}

        if (preferred && display.name === preferred) return true;

        const name = display.name.toLowerCase();
        return name.startsWith("edp") || name.startsWith("lvds");
    }

    function setDisplays() {
        Proc.runCommand("niriDS:getOutputs", ["niri", "msg", "--json", "outputs"], (output, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const parsed = JSON.parse(output);
                const arr = [];
                for (const name in parsed) {
                    const raw = parsed[name];
                    const internal = isInternal({ name: name });
                    
                    let friendly = internal ? "Laptop Screen" : (raw.model || name);

                    arr.push({
                        name: name,
                        friendlyName: friendly,
                        disabled: !raw.logical,
                        logical: raw.logical || null
                    });
                }
                root.displays = arr;
            } catch (e) {
                console.error("[NiriDS] UI Processing Error:", e);
            }
        });
    }

    function toggleDisable(display: var): void {
        if (!display || !display.name) return;
        const action = display.disabled ? "on" : "off";
        Proc.runCommand("niriDS:toggle", ["niri", "msg", "output", display.name, action], (out, code) => {
            if (code === 0) setDisplays();
        });
    }

    function apply(profile: string): void {
        const toProcess = [...displays];
        if (toProcess.length === 0) return;

        function next(i) {
            if (i >= toProcess.length) {
                setDisplays();
                return;
            }
            
            const d = toProcess[i];
            const internal = isInternal(d);
            let action = "on";

            if (profile === "internal_only") {
                action = internal ? "on" : "off";
            } else if (profile === "external_only") {
                action = internal ? "off" : "on";
            } else if (profile === "extend") {
                action = "on";
            }
            
            Proc.runCommand("niriDS:applyStep", ["niri", "msg", "output", d.name, action], () => next(i + 1));
        }
        
        next(0);
    }

    function fallbackIfUnplugged(): void {
        Proc.runCommand("niriDS:fallbackCheck", ["niri", "msg", "--json", "outputs"], (output, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const parsed = JSON.parse(output);
                let activeExt = 0;
                let internal = null;
                for (const name in parsed) {
                    const raw = parsed[name];
                    if (name.toLowerCase().startsWith("edp") || name.toLowerCase().startsWith("lvds")) {
                        internal = { name: name, active: !!raw.logical };
                    } else if (raw.logical) {
                        activeExt++;
                    }
                }
                if (activeExt === 0 && internal && !internal.active) {
                    Proc.runCommand("niriDS:recover", ["niri", "msg", "output", internal.name, "on"], () => setDisplays());
                }
            } catch (e) {}
        });
    }

    Component.onCompleted: Qt.callLater(() => setDisplays())
}
