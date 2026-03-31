import QtQuick
import Quickshell
import Quickshell.Io

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

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

    property bool minimumWidth: pluginData.minimumWidth !== undefined ? pluginData.minimumWidth : false
    property string popoutStyle: pluginData.popoutStyle || "default"
    readonly property string popoutStyleSource: {
        switch (popoutStyle) {
            case "alt":
                return "styles/popout/AltStyle.qml";
            case "dms":
                return "styles/popout/DmsStyle.qml";
            default:
                return "styles/popout/DefaultStyle.qml";
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
        id: updateGpuStatsProcess
        command: ["amdgpu_top", "-J", "-n", "1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                const data = JSON.parse(output);
                const amd_gpu = data.devices[0];

                root.gpuName = amd_gpu["Info"]["DeviceName"] || "AMD GPU";

                root.gfxUsage = parseFloat(amd_gpu.gpu_activity["GFX"].value) || 0.0;
                root.memUsage = parseFloat(amd_gpu.gpu_activity["Memory"].value) || 0.0;
                root.mediaUsage = parseFloat(amd_gpu.gpu_activity["MediaEngine"].value) || 0.0;
                root.gpuUsage = Math.max(root.gfxUsage, root.memUsage, root.mediaUsage);

                root.vramUsed = parseFloat(amd_gpu["VRAM"]["Total VRAM Usage"].value) || 0.0;
                root.vramTotal = parseFloat(amd_gpu["VRAM"]["Total VRAM"].value) || 0.0;
                root.vramPercent = root.vramTotal > 0
                    ? (root.vramUsed / root.vramTotal * 100) : 0.0;
                root.temperature = parseInt(amd_gpu.gpu_metrics.temperature_edge) || 0;
                root.powerUsage = parseInt(amd_gpu.Sensors["Average Power"].value) || 0;

                if (amd_gpu.fdinfo) {
                    const processList = [];

                    Object.keys(amd_gpu.fdinfo).forEach(pid => {
                        const procInfo = amd_gpu.fdinfo[pid];
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
                implicitWidth: root.minimumWidth ? Math.max(textBaseline.width, gpuText.paintedWidth) : gpuText.paintedWidth
                implicitHeight: gpuText.implicitHeight
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

                StyledText {
                    id: gpuText
                    text: `${root.gpuUsage.toFixed(0)}% | ${(root.vramUsed / 1024).toFixed(1)}GiB`
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.widgetTextColor
                    anchors.fill: parent
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
