import QtQuick
import Quickshell
import Quickshell.Io

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

import "components/shared" as Shared

PluginComponent {
    id: root

    property string variantId: ""
    property var variantData: null

    property real gpuUsage: 0.0
    property real vramUsed: 0.0
    property real vramTotal: 0.0
    property real vramPercent: 0.0
    property int temperature: 0
    property int powerUsage: 0
    property string gpuName: "AMD GPU"
    property var processes: []
    property bool statsError: false
    property bool gpuSuspended: false

    property real gfxUsage: 0.0
    property real memUsage: 0.0
    property real mediaUsage: 0.0

    function resetStats() {
        // A sysfs read in flight would land on top of the cleared state and
        // show a temperature for a GPU we just reported as idle.
        if (updateTemperatureFallbackProcess.running)
            updateTemperatureFallbackProcess.running = false;
        temperatureFallbackTimeoutTimer.stop();
        gfxUsage = 0.0;
        memUsage = 0.0;
        mediaUsage = 0.0;
        gpuUsage = 0.0;
        vramUsed = 0.0;
        vramTotal = 0.0;
        vramPercent = 0.0;
        temperature = 0;
        powerUsage = 0;
        temperatureSysfsPath = "";
        processes = [];
    }

    property int updateInterval: Math.max(1000, parseInt(variantData?.updateInterval ?? pluginData.updateInterval ?? "4000") || 4000)
    property string temperatureSysfsPath: ""

    property bool minimumWidth: variantData?.minimumWidth ?? pluginData.minimumWidth ?? true
    property int gpuIndex: Math.max(0, parseInt(variantData?.gpuIndex ?? "0") || 0)
    // amdgpu_top drops runtime-suspended GPUs from `devices`, so positions shift.
    // gpuIndex is kept only as a fallback for variants created before this.
    property string gpuPci: (variantData?.gpuPci ?? "").toString()
    property string popoutStyle: variantData?.popoutStyle ?? pluginData.popoutStyle ?? "default"
    property int processListHeight: Math.max(100, Math.min(750, parseInt(variantData?.processListHeight ?? pluginData.processListHeight ?? "250") || 250))
    readonly property string popoutStyleSource: {
        switch (popoutStyle) {
            case "alt":
                return "components/styles/AltStyle.qml";
            case "legacy":
                return "components/styles/LegacyStyle.qml";
            default:
                return "components/styles/DefaultStyle.qml";
        }
    }

    Shared.CommonStyles {
        id: commonStyles
    }

    Timer {
        id: updateTimer
        interval: root.updateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!updateGpuStatsProcess.running)
                updateGpuStatsProcess.running = true;
        }
    }

    Timer {
        id: temperatureFallbackTimeoutTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: {
            if (updateTemperatureFallbackProcess.running)
                updateTemperatureFallbackProcess.running = false;
        }
    }

    Process {
        id: updateTemperatureFallbackProcess
        command: []
        running: false

        onRunningChanged: {
            if (running) {
                temperatureFallbackTimeoutTimer.restart();
            } else {
                temperatureFallbackTimeoutTimer.stop();
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const rawValue = text.trim();
                const milliCelsius = parseInt(rawValue);
                if (!isNaN(milliCelsius) && milliCelsius > 0) {
                    root.temperature = Math.round(milliCelsius / 1000);
                }
            }
        }
    }

    Process {
        id: updateGpuStatsProcess
        command: ["amdgpu_top", "-J", "-n", "1"]
        running: false

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.statsError = true;
                console.warn(`amdGpuMonitor: amdgpu_top exited with code ${exitCode}`);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const errorText = text.trim();
                if (errorText.length > 0) {
                    root.statsError = true;
                    console.warn(`amdGpuMonitor: ${errorText}`);
                }
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                let data;
                try {
                    data = JSON.parse(output);
                } catch (e) {
                    root.statsError = true;
                    console.warn(`amdGpuMonitor: failed to parse amdgpu_top output: ${e}`);
                    return;
                }

                root.statsError = false;
                const devices = Array.isArray(data.devices) ? data.devices : [];
                const suspended = Array.isArray(data.suspended_devices) ? data.suspended_devices : [];

                let selectedGpu = null;
                if (root.gpuPci) {
                    selectedGpu = devices.find(d => d["Info"]?.["PCI"] === root.gpuPci) || null;
                    if (!selectedGpu) {
                        // Configured GPU is powered down: report it idle rather than
                        // silently falling through to whichever card is still awake.
                        const naps = suspended.find(d => d.pci === root.gpuPci);
                        if (naps) {
                            root.resetStats();
                            root.gpuName = naps.DeviceName || "AMD GPU";
                            root.gpuSuspended = true;
                            return;
                        }
                    }
                } else {
                    selectedGpu = devices[root.gpuIndex] || devices[0];
                }
                root.gpuSuspended = false;

                if (!selectedGpu) {
                    root.resetStats();
                    root.gpuName = "AMD GPU";
                    return;
                }

                root.gpuName = selectedGpu["Info"]?.["DeviceName"] || `AMD GPU ${root.gpuIndex}`;

                root.gfxUsage = parseFloat(selectedGpu.gpu_activity?.["GFX"]?.value) || 0.0;
                root.memUsage = parseFloat(selectedGpu.gpu_activity?.["Memory"]?.value) || 0.0;
                root.mediaUsage = parseFloat(selectedGpu.gpu_activity?.["MediaEngine"]?.value) || 0.0;
                root.gpuUsage = Math.max(root.gfxUsage, root.memUsage, root.mediaUsage);

                root.vramUsed = parseFloat(selectedGpu["VRAM"]?.["Total VRAM Usage"]?.value) || 0.0;
                root.vramTotal = parseFloat(selectedGpu["VRAM"]?.["Total VRAM"]?.value) || 0.0;
                root.vramPercent = root.vramTotal > 0
                    ? (root.vramUsed / root.vramTotal * 100) : 0.0;
                const extractedTemperature = root.extractTemperature(selectedGpu);
                if (extractedTemperature > 0) {
                    root.temperature = extractedTemperature;
                    root.temperatureSysfsPath = "";
                } else if (!root.refreshTemperatureFromSysfs(selectedGpu)) {
                    root.temperature = 0;
                }
                root.powerUsage = parseInt(selectedGpu.Sensors?.["Average Power"]?.value) || 0;

                if (selectedGpu.fdinfo) {
                    const processList = [];

                    Object.keys(selectedGpu.fdinfo).forEach(pid => {
                        const procInfo = selectedGpu.fdinfo[pid];
                        const usage = procInfo.usage?.usage;
                        if (!usage) return;

                        const vram = usage.VRAM?.value || 0;
                        const gfx = usage.GFX?.value || 0;
                        const cpu = usage.CPU?.value || 0;

                        if (vram > 0 || gfx > 0) {
                            processList.push({
                                name: procInfo.name || "Unknown",
                                pid: parseInt(pid),
                                vram: vram,
                                vramUnit: usage.VRAM?.unit || "MiB",
                                gfx: gfx,
                                cpu: cpu,
                                gtt: usage.GTT?.value || 0,
                                compute: usage.Compute?.value || 0
                            });
                        }
                    });

                    processList.sort((a, b) => b.vram - a.vram);
                    if (!root.processListsEqual(root.processes, processList))
                        root.processes = processList;
                } else if (root.processes.length > 0) {
                    root.processes = [];
                }
            }
        }
    }

    function processListsEqual(a, b) {
        if (a.length !== b.length)
            return false;
        return JSON.stringify(a) === JSON.stringify(b);
    }

    function formatVram() {
        if (root.vramTotal < 1024) {
            return `${root.vramUsed.toFixed(0)}/${root.vramTotal.toFixed(0)} MiB`;
        }

        const usedGiB = (root.vramUsed / 1024).toFixed(1);
        const totalGiB = (root.vramTotal / 1024).toFixed(1);
        return `${usedGiB}/${totalGiB} GiB`;
    }

    function extractTemperature(selectedGpu) {
        const edgeTemp = parseInt(selectedGpu?.gpu_metrics?.temperature_edge);
        if (!isNaN(edgeTemp) && edgeTemp > 0)
            return edgeTemp;

        const sensorsEdgeTemp = parseInt(selectedGpu?.Sensors?.["Edge Temperature"]?.value);
        if (!isNaN(sensorsEdgeTemp) && sensorsEdgeTemp > 0)
            return sensorsEdgeTemp;

        const gfxTemp = parseInt(selectedGpu?.gpu_metrics?.temperature_gfx);
        if (!isNaN(gfxTemp) && gfxTemp > 0)
            return Math.round(gfxTemp / 100);

        return 0;
    }

    function normalizeSysfsPath(path) {
        if (typeof path !== "string")
            return "";

        const normalizedPath = path.trim().replace(/\/+$/, "");
        return normalizedPath.startsWith("/sys/") ? normalizedPath : "";
    }

    function normalizePciAddress(address) {
        if (typeof address !== "string")
            return "";

        const normalizedAddress = address.trim();
        return /^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-7]$/.test(normalizedAddress)
            ? normalizedAddress
            : "";
    }

    function getTemperatureSysfsPath(selectedGpu) {
        const infoDevicePath = selectedGpu?.Info?.DevicePath;
        const nestedDevicePath = selectedGpu?.DevicePath;
        const legacyDevicePath = selectedGpu?.device_path;
        const directPath = root.normalizeSysfsPath(
            (typeof infoDevicePath === "string" ? infoDevicePath : infoDevicePath?.sysfs_path)
            || (typeof nestedDevicePath === "string" ? nestedDevicePath : nestedDevicePath?.sysfs_path)
            || (typeof legacyDevicePath === "string" ? legacyDevicePath : legacyDevicePath?.sysfs_path)
            || selectedGpu?.sysfs_path
        );
        if (directPath)
            return directPath;

        const pciAddress = root.normalizePciAddress(
            infoDevicePath?.pci
            || selectedGpu?.PCI
            || selectedGpu?.pci
        );
        if (pciAddress)
            return `/sys/bus/pci/devices/${pciAddress}`;

        return "";
    }

    function refreshTemperatureFromSysfs(selectedGpu) {
        if (updateTemperatureFallbackProcess.running)
            return true;

        const sysfsPath = root.getTemperatureSysfsPath(selectedGpu);
        root.temperatureSysfsPath = sysfsPath;
        if (!sysfsPath)
            return false;

        updateTemperatureFallbackProcess.command = [
            "find",
            `${sysfsPath}/hwmon`,
            "-mindepth",
            "2",
            "-maxdepth",
            "2",
            "-type",
            "f",
            "-name",
            "temp1_input",
            "-exec",
            "cat",
            "{}",
            ";",
            "-quit"
        ];
        updateTemperatureFallbackProcess.running = true;
        return true;
    }

    function getUsageColor(percent) {
        return commonStyles.usageColor(percent);
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: "shadow"
                size: root.iconSize
                color: root.statsError ? Theme.error : Theme.widgetIconColor
                opacity: root.gpuSuspended ? 0.5 : 1.0
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.minimumWidth ? Math.max(textBaseline.width, currentTextMetrics.width) : currentTextMetrics.width
                implicitHeight: currentTextMetrics.height
                width: implicitWidth
                height: implicitHeight

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }

                StyledTextMetrics {
                    id: textBaseline
                    font.pixelSize: Theme.fontSizeSmall
                    text: "88% | 8.8GiB"
                }

                StyledTextMetrics {
                    id: currentTextMetrics
                    font.pixelSize: Theme.fontSizeSmall
                    text: `${root.gpuUsage.toFixed(0)}% | ${(root.vramUsed / 1024).toFixed(1)}GiB`
                }

                StyledText {
                    id: gpuText
                    text: currentTextMetrics.text
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.widgetTextColor
                    anchors.fill: parent
                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    elide: Text.ElideNone
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            DankIcon {
                name: "shadow"
                size: root.iconSize
                color: root.statsError ? Theme.error : Theme.widgetIconColor
                opacity: root.gpuSuspended ? 0.5 : 1.0
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: `${root.gpuUsage.toFixed(0)}%`
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.widgetTextColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: root.gpuName
            showCloseButton: true

            Loader {
                id: popoutLoader
                width: parent.width
                function loadStyle() {
                    setSource(root.popoutStyleSource, { "root": root });
                }

                Component.onCompleted: loadStyle()
                Connections {
                    target: root
                    function onPopoutStyleSourceChanged() {
                        popoutLoader.loadStyle();
                    }
                }
            }
        }
    }
}
