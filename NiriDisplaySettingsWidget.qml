import QtQuick
import Quickshell
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
            modal.shouldBeVisible = true;
            modal.openCentered();
            NiriDS.setDisplays();
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

    // Monitor Hotplug Detection
    property int lastCount: -1

    Timer {
        id: hotplugTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            if (!Quickshell.screens) return;
            const current = Quickshell.screens.length;

            if (lastCount === -1) {
                lastCount = current;
                return;
            }

            if (current !== lastCount) {
                const data = NiriDS.getPluginData();

                if (current > lastCount && data.autoShowOnConnect) {
                    modal.shouldBeVisible = true;
                    modal.openCentered();
                    NiriDS.setDisplays();
                } else if (current < lastCount && data.enableFallback !== false) {
                    NiriDS.fallbackIfUnplugged();
                }
                lastCount = current;
            }
        }
    }

    Component.onCompleted: {
        lastCount = Quickshell.screens ? Quickshell.screens.length : 0;
    }
}
