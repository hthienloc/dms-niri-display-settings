import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root
    pluginId: "niriDS"
    pluginService: PluginService
    readonly property bool isDaemonInstance: root.parent !== null
    readonly property bool hasExternal: {
        const raw = NiriDS.rawOutputs || {};
        return Object.keys(raw).some(n => n && !NiriDS.isInternalName(n));
    }

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

    IpcHandler {
        target: "niriDS"
        enabled: root.isDaemonInstance

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
            const needsExternal = ["external_only", "extend", "mirror"].includes(profile);
            if (needsExternal && !root.hasExternal) return "ERROR: no external display connected";
            NiriDS.apply(profile);
            return "SUCCESS";
        }

        function fallback(): string {
            NiriDS.enableInternalDisplay();
            return "SUCCESS";
        }
    }

    property int lastOutputCount: 0
    property int initTicks: 0
    property var cachedRawOutputs: ({} )

    function checkFallback() {
        const enableFallback = PluginService.loadPluginData("niriDS", "enableFallback", true);
        if (!enableFallback) return;

        // Kill wl-mirror first — its target output just disappeared
        NiriDS.stopMirror();

        NiriDS.enableInternalDisplay();
        Qt.callLater(() => NiriDS.enableInternalDisplay());
        Qt.callLater(() => Qt.callLater(() => NiriDS.enableInternalDisplay()));
    }

    Timer {
        id: niriWatcher
        interval: 3000
        repeat: true
        running: root.isDaemonInstance

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
                    const action = (typeof pluginData?.connectionAction === 'string' && pluginData.connectionAction)
                        ? pluginData.connectionAction
                        : "show_menu";

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

    Component.onCompleted: {
        if (root.isDaemonInstance && pluginService && pluginId) {
            // 1. Register daemon component in pluginWidgetComponents dynamically
            if (pluginService.pluginWidgetComponents && !pluginService.pluginWidgetComponents[pluginId]) {
                const newWidgets = Object.assign({}, pluginService.pluginWidgetComponents);
                newWidgets[pluginId] = pluginService.pluginDaemonComponents[pluginId];
                pluginService.pluginWidgetComponents = newWidgets;
            }
            // 2. Bypass daemon filter in WidgetModel by updating in-memory type to widget
            const plugins = pluginService.getLoadedPlugins ? pluginService.getLoadedPlugins() : [];
            const pluginInfo = plugins.find(p => p.id === pluginId);
            if (pluginInfo) {
                pluginInfo.type = "widget";
            }
        }
    }
}