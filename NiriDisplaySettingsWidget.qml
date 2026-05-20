import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    NiriDisplaySettingsModal {
        id: modal
    }

    IpcHandler {
        target: "niriDS"

        function open(): string {
            root.openMenu();
            return "SUCCESS";
        }

        function close(): string {
            modal.shouldBeVisible = false;
            modal.close();
            return "SUCCESS";
        }

        function toggle(): string {
            return modal.shouldBeVisible ? close() : open();
        }

        function apply(profile: string): string {
            NiriDS.apply(profile);
            return "SUCCESS";
        }

        function mirror(): string {
            NiriDS.mirrorDisplay();
            return "SUCCESS";
        }

        function fallback(): string {
            NiriDS.fallbackIfUnplugged();
            return "SUCCESS";
        }
    }

    property int lastOutputCount: 0
    property int initTicks: 0
    property var cachedRawOutputs: ({} )

    function checkFallback() {
        const enableFallback = PluginService.loadPluginData("niriDS", "enableFallback", true);
        if (!enableFallback) return;

        NiriDS.enableInternalDisplay();
        Qt.callLater(() => NiriDS.enableInternalDisplay());
        Qt.callLater(() => Qt.callLater(() => NiriDS.enableInternalDisplay()));
    }

    Timer {
        id: niriWatcher
        interval: 3000
        repeat: true
        running: true

        onTriggered: {
            const prevTotalOutputs = Object.keys(cachedRawOutputs || {}).length;
            NiriDS.setDisplays();
            root.initTicks++;

            Qt.callLater(() => {
                const current = NiriDS.displays.length;
                const totalOutputs = Object.keys(NiriDS.rawOutputs || {}).length;
                cachedRawOutputs = NiriDS.rawOutputs;

                // Skip first 2 ticks to allow Niri to stabilize outputs
                if (initTicks < 3) {
                    if (initTicks === 2) {
                        lastOutputCount = current;
                    }
                    return;
                }

                if (totalOutputs > prevTotalOutputs) {
                    const actionObj = pluginData?.connectionAction;
                    let action = "show_menu"; // Default
                    if (actionObj && typeof actionObj === 'object' && actionObj.value) {
                        action = actionObj.value;
                    }

                    if (action === "show_menu") {
                        Qt.callLater(() => root.openMenu());
                    } else if (action !== "none") {
                        NiriDS.apply(action);
                    }
                } else if (lastOutputCount > 0 && current < lastOutputCount) {
                    // Display count decreased - external monitor unplugged
                    checkFallback();
                }

                lastOutputCount = current;
            });
        }
    }

    function openMenu() {
        modal.shouldBeVisible = true;
        modal.openCentered();
        NiriDS.setDisplays();
    }
}