import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "."

PluginComponent {
    id: root
    pluginId: "niriDS"
    pluginService: PluginService

    // Control Center Integration
    ccWidgetIcon: "computer"
    ccWidgetPrimaryText: "Display Settings"
    ccWidgetSecondaryText: {
        const displays = NiriDS.displays || [];
        const enabledCount = displays.filter(d => !d.disabled).length;
        return enabledCount + " active display" + (enabledCount === 1 ? "" : "s");
    }
    ccWidgetIsActive: modal.shouldBeVisible

    onCcWidgetToggled: {
        root.openMenu();
    }

    NiriDisplaySettingsModal {
        id: modal
    }

    Connections {
        target: NiriDS
        function onOpenRequested() {
            root.openMenu();
        }
        function onCloseRequested() {
            modal.shouldBeVisible = false;
            modal.close();
        }
        function onToggleRequested() {
            if (modal.shouldBeVisible) {
                NiriDS.closeRequested();
            } else {
                NiriDS.openRequested();
            }
        }
    }

    function openMenu() {
        modal.shouldBeVisible = true;
        modal.openCentered();
        NiriDS.setDisplays();
    }
}