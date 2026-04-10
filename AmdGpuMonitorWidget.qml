import QtQuick
import Quickshell
import Quickshell.Io

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

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

    property real gfxUsage: 0.0
    property real memUsage: 0.0
    property real mediaUsage: 0.0

    property int updateInterval: 4000
    property string temperatureSysfsPath: ""

    property bool minimumWidth: variantData?.minimumWidth ?? pluginData.minimumWidth ?? false
    property int gpuIndex: Math.max(0, parseInt(variantData?.gpuIndex ?? "0") || 0)
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

    Timer {
        id: updateTimer
        interval: root.updateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateGpuStatsProcess.running = true
    }

    Process {
        id: updateTemperatureFallbackProcess
        command: []
        running: false

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

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                const data = JSON.parse(output);
                const devices = Array.isArray(data.devices) ? data.devices : [];
                const selectedGpu = devices[root.gpuIndex] || devices[0];

                if (!selectedGpu) {
                    root.gpuName = "AMD GPU";
                    root.gfxUsage = 0.0;
                    root.memUsage = 0.0;
                    root.mediaUsage = 0.0;
                    root.gpuUsage = 0.0;
                    root.vramUsed = 0.0;
                    root.vramTotal = 0.0;
                    root.vramPercent = 0.0;
                    root.temperature = 0;
                    root.powerUsage = 0;
                    root.temperatureSysfsPath = "";
                    root.processes = [];
                    return;
                }

                root.gpuName = selectedGpu["Info"]?.["DeviceName"] || `AMD GPU ${root.gpuIndex}`;
                root.temperatureSysfsPath = root.getTemperatureSysfsPath(selectedGpu);

                root.gfxUsage = parseFloat(selectedGpu.gpu_activity?.["GFX"]?.value) || 0.0;
                root.memUsage = parseFloat(selectedGpu.gpu_activity?.["Memory"]?.value) || 0.0;
                root.mediaUsage = parseFloat(selectedGpu.gpu_activity?.["MediaEngine"]?.value) || 0.0;
                root.gpuUsage = Math.max(root.gfxUsage, root.memUsage, root.mediaUsage);

                root.vramUsed = parseFloat(selectedGpu["VRAM"]?.["Total VRAM Usage"]?.value) || 0.0;
                root.vramTotal = parseFloat(selectedGpu["VRAM"]?.["Total VRAM"]?.value) || 0.0;
                root.vramPercent = root.vramTotal > 0
                    ? (root.vramUsed / root.vramTotal * 100) : 0.0;
                root.temperature = root.extractTemperature(selectedGpu);
                if (root.temperature <= 0)
                    root.refreshTemperatureFromSysfs();
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
                    root.processes = processList;
                } else {
                    root.processes = [];
                }
            }
        }
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

    function getTemperatureSysfsPath(selectedGpu) {
        const infoDevicePath = selectedGpu?.Info?.DevicePath;
        const directPath = infoDevicePath?.sysfs_path
            || selectedGpu?.DevicePath?.sysfs_path
            || selectedGpu?.device_path?.sysfs_path
            || selectedGpu?.sysfs_path;
        if (directPath)
            return directPath;

        const pciAddress = infoDevicePath?.pci
            || selectedGpu?.PCI
            || selectedGpu?.pci;
        if (pciAddress)
            return `/sys/bus/pci/devices/${pciAddress}`;

        return "";
    }

    function refreshTemperatureFromSysfs() {
        if (!root.temperatureSysfsPath || updateTemperatureFallbackProcess.running)
            return;
        updateTemperatureFallbackProcess.command = [
            "sh",
            "-c",
            `for hw in "${root.temperatureSysfsPath}"/hwmon/*; do [ -f "$hw/temp1_input" ] && cat "$hw/temp1_input" && exit 0; done; exit 1`
        ];
        updateTemperatureFallbackProcess.running = true;
    }

    function getUsageColor(percent) {
        if (percent > 90) return Theme.error;
        if (percent > 70) return "#ffa500";
        return Theme.primary;
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: "shadow"
                size: root.iconSize
                color: Theme.widgetIconColor
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
                color: Theme.widgetIconColor
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
