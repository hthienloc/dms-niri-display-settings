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

        function fallback(): string {
            NiriDS.fallbackIfUnplugged();
            return "SUCCESS";
        }
    }

    property int lastEnabledCount: -1
    property int lastTotalOutputs: -1
    property int decreaseCount: 0
    property int initTicks: 0
    property var cachedRawOutputs: ({} )

    function checkFallback() {
        const enableFallback = PluginService.loadPluginData("niriDS", "enableFallback", true);
        if (!enableFallback) return;

        const displays = NiriDS.displays || [];
        const totalOutputs = Object.keys(NiriDS.rawOutputs || {}).length;
        const enabledDisplays = displays.filter(d => !d.disabled).length;

        if (totalOutputs > 0 && enabledDisplays === 0 && lastEnabledCount > 0) {
            const allLostAtOnce = totalOutputs === lastEnabledCount;
            if (!allLostAtOnce) {
                NiriDS.enableInternalDisplay();
                Qt.callLater(() => NiriDS.enableInternalDisplay());
                Qt.callLater(() => Qt.callLater(() => NiriDS.enableInternalDisplay()));
            }
        }
        decreaseCount = 0;
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
                const enabledCount = (NiriDS.displays || []).filter(d => !d.disabled).length;
                const totalOutputs = Object.keys(NiriDS.rawOutputs || {}).length;
                cachedRawOutputs = NiriDS.rawOutputs;

                if (initTicks < 3) {
                    if (initTicks === 2) {
                        lastEnabledCount = enabledCount;
                        lastTotalOutputs = totalOutputs;
                    }
                    return;
                }

                if (totalOutputs > prevTotalOutputs) {
                    const profileObj = pluginData?.profileOnConnect;
                    let profileOnConnect = "";
                    if (profileObj && typeof profileObj === 'object') {
                        const val = profileObj.value;
                        const label = profileObj.label;
                        if (val && val !== label) {
                            profileOnConnect = val;
                        }
                    }
                    const autoShow = pluginData?.autoShowOnConnect === true;

                    if (profileOnConnect) {
                        NiriDS.apply(profileOnConnect);
                    } else if (autoShow) {
                        Qt.callLater(() => root.openMenu());
                    }
                    return;
                } else if (enabledCount < lastEnabledCount) {
                    decreaseCount++;
                    if (decreaseCount >= 2) {
                        checkFallback();
                    }
                }

                lastEnabledCount = enabledCount;
                lastTotalOutputs = totalOutputs;
            });
        }
    }

    function openMenu() {
        modal.shouldBeVisible = true;
        modal.openCentered();
        NiriDS.setDisplays();
    }
}