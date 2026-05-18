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
    }

    // High-reliability Niri Polling
    property int lastOutputCount: -1

    Timer {
        id: niriWatcher
        interval: 3000
        repeat: true
        running: true

        property int initTicks: 0

        onTriggered: {
            NiriDS.setDisplays();
            const current = NiriDS.displays.length;

            if (initTicks < 3) {
                initTicks++;
                return;
            }

            if (initTicks === 3) {
                lastOutputCount = current;
                initTicks++;
                return;
            }

            if (current !== lastOutputCount) {
                if (current > lastOutputCount) {
                    const profileOnConnect = PluginService.loadPluginData("niriDS", "profileOnConnect", "");
                    const autoShow = PluginService.loadPluginData("niriDS", "autoShowOnConnect", false);
                    
                    if (profileOnConnect) {
                        NiriDS.apply(profileOnConnect);
                    } else if (autoShow) {
                        root.openMenu();
                    }
                } else if (current < lastOutputCount) {
                    const enableFallback = PluginService.loadPluginData("niriDS", "enableFallback", true);
                    if (enableFallback) {
                        NiriDS.fallbackIfUnplugged();
                    }
                }
                lastOutputCount = current;
            }
        }
    }

    function openMenu() {
        modal.shouldBeVisible = true;
        modal.openCentered();
        NiriDS.setDisplays();
    }
}
