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

                root.powerUsage = parseInt(amd_gpu.Sensors["Average Power"].value) || 0;

                if (amd_gpu.fdinfo) {
                    const processList = [];
                    
                    // Iterate through PIDs
                    Object.keys(amd_gpu.fdinfo).forEach(pid => {
                        const procInfo = amd_gpu.fdinfo[pid];
                        
                        // Access the nested usage.usage structure
                        const usage = procInfo.usage?.usage;
                        if (!usage) return;
                        
                        const vram = usage.VRAM?.value || 0;
                        const gfx = usage.GFX?.value || 0;
                        const cpu = usage.CPU?.value || 0;
                        
                        // Only include processes using VRAM or GPU
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
                    
                    // Sort by VRAM usage (highest first)
                    processList.sort((a, b) => b.vram - a.vram);
                    
                    root.processes = processList;
                }
            }
        }
    }
    
    function formatVram() {
        if (root.vramTotal < 1024) {
            return `${root.vramUsed.toFixed(0)}/${root.vramTotal.toFixed(0)} MB`;
        } else {
            const usedGB = (root.vramUsed / 1024).toFixed(1);
            const totalGB = (root.vramTotal / 1024).toFixed(1);
            return `${usedGB}/${totalGB} GB`;
        }
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
                    text: "88% | 8.8GB"
                }

                StyledText {
                    id: gpuText
                    text: `${root.gpuUsage.toFixed(0)}% | ${(root.vramUsed / 1024).toFixed(1)}GB`
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

    // Popout content
    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: root.gpuName
            showCloseButton: true

            Loader {
                width: parent.width
                sourceComponent: {
                    switch (root.popoutStyle) {
                        case "alt": return altStyleContent
                        case "dms": return dmsStyleContent
                        default: return defaultStyleContent
                    }
                }
            }
        }
    }

    // Default style component
    Component {
        id: defaultStyleContent

        Column {
            width: parent.width
            spacing: Theme.spacingL

            // GPU Usage
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    width: parent.width

                    StyledText {
                        width: parent.width - 50
                        text: "GPU Usage"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    StyledText {
                        text: `${root.gpuUsage.toFixed(1)}%`
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 12
                    color: Theme.surfaceText
                    radius: Theme.cornerRadius

                    Rectangle {
                        width: parent.width * (root.gpuUsage / 100)
                        height: parent.height
                        color: root.getUsageColor(root.gpuUsage)
                        radius: Theme.cornerRadius

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            // VRAM Usage
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    width: parent.width

                    StyledText {
                        width: parent.width - 100
                        text: "VRAM Usage"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    StyledText {
                        text: root.formatVram()
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 12
                    color: Theme.surfaceText
                    radius: Theme.cornerRadius

                    Rectangle {
                        width: parent.width * (root.vramPercent / 100)
                        height: parent.height
                        color: root.getUsageColor(root.vramPercent)
                        radius: Theme.cornerRadius

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Column {
                visible: root.gfxUsage > 0
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: "Engine Usage"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingL

                    StyledText {
                        text: `GFX: ${root.gfxUsage.toFixed(0)}%`
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    StyledText {
                        text: `MEM: ${root.memUsage.toFixed(0)}%`
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    StyledText {
                        text: `Media: ${root.mediaUsage.toFixed(0)}%`
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }

            // Temperature & Power
            Row {
                width: parent.width
                spacing: Theme.spacingXL

                Column {
                    visible: root.temperature > 0
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Temperature"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    StyledText {
                        text: `${root.temperature}°C`
                        color: root.temperature > 80 ? Theme.error : Theme.surfaceText
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                    }
                }

                Column {
                    visible: root.powerUsage > 0
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Power"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    StyledText {
                        text: `${root.powerUsage}W`
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                    }
                }
            }

            // Process List
            Column {
                visible: root.processes.length > 0
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: `GPU Processes (${root.processes.length})`
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                }

                Rectangle {
                    width: parent.width
                    height: processColumnDefault.implicitHeight
                    radius: Theme.cornerRadius
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        contentHeight: processColumnDefault.implicitHeight

                        Column {
                            id: processColumnDefault
                            width: parent.width
                            spacing: 1

                            Repeater {
                                model: root.processes

                                Rectangle {
                                    width: parent.width
                                    height: 50
                                    color: Theme.surfaceContainer

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingS
                                        spacing: Theme.spacingM

                                        Column {
                                            width: 140
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            StyledText {
                                                width: parent.width
                                                text: modelData.name
                                                color: Theme.surfaceText
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            StyledText {
                                                text: `PID: ${modelData.pid}`
                                                color: Theme.surfaceVariantText
                                                font.pixelSize: Theme.fontSizeSmall - 1
                                            }
                                        }

                                        Column {
                                            width: 70
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            StyledText {
                                                text: "VRAM"
                                                color: Theme.surfaceVariantText
                                                font.pixelSize: Theme.fontSizeSmall - 1
                                            }

                                            StyledText {
                                                text: `${modelData.vram} ${modelData.vramUnit}`
                                                color: Theme.primary
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.bold: true
                                            }
                                        }

                                        Column {
                                            visible: modelData.gfx > 0
                                            width: 50
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            StyledText {
                                                text: "GPU"
                                                color: Theme.surfaceVariantText
                                                font.pixelSize: Theme.fontSizeSmall - 1
                                            }

                                            StyledText {
                                                text: `${modelData.gfx}%`
                                                color: Theme.surfaceText
                                                font.pixelSize: Theme.fontSizeSmall
                                            }
                                        }

                                        Column {
                                            visible: modelData.cpu > 0
                                            width: 50
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            StyledText {
                                                text: "CPU"
                                                color: Theme.surfaceVariantText
                                                font.pixelSize: Theme.fontSizeSmall - 1
                                            }

                                            StyledText {
                                                text: `${modelData.cpu}%`
                                                color: Theme.surfaceText
                                                font.pixelSize: Theme.fontSizeSmall
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Alternative style
    Component {
        id: altStyleContent

        Column {
            width: parent.width
            spacing: Theme.spacingM

            // Main stats
            Row {
                width: parent.width
                spacing: Theme.spacingM

                // GPU Usage
                Rectangle {
                    width: (parent.width - Theme.spacingM) / 2
                    height: 100
                    radius: 16
                    color: Theme.surfaceContainerHigh

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Row {
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "speed"
                                size: 20
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "GPU"
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            text: `${root.gpuUsage.toFixed(0)}%`
                            color: Theme.surfaceText
                            font.pixelSize: 28
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Theme.surfaceContainerHighest

                            Rectangle {
                                width: parent.width * (root.gpuUsage / 100)
                                height: parent.height
                                radius: 2
                                color: root.getUsageColor(root.gpuUsage)

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }

                // VRAM Usage
                Rectangle {
                    width: (parent.width - Theme.spacingM) / 2
                    height: 100
                    radius: 16
                    color: Theme.surfaceContainerHigh

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Row {
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "memory"
                                size: 20
                                color: Theme.secondary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "VRAM"
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            text: `${(root.vramUsed / 1024).toFixed(1)} GB`
                            color: Theme.surfaceText
                            font.pixelSize: 28
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Theme.surfaceContainerHighest

                            Rectangle {
                                width: parent.width * (root.vramPercent / 100)
                                height: parent.height
                                radius: 2
                                color: root.getUsageColor(root.vramPercent)

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }
            }

            // Temperature & Power
            Row {
                width: parent.width
                spacing: Theme.spacingS

                // Temperature chip
                Rectangle {
                    visible: root.temperature > 0
                    width: (parent.width - Theme.spacingS) / 2
                    height: 48
                    radius: 12
                    color: root.temperature > 80 ? Theme.errorHover : Theme.surfaceContainerHigh

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "thermostat"
                            size: 22
                            color: root.temperature > 80 ? Theme.error : Theme.secondary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: `${root.temperature}°C`
                            color: root.temperature > 80 ? Theme.error : Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Power chip
                Rectangle {
                    visible: root.powerUsage > 0
                    width: (parent.width - Theme.spacingS) / 2
                    height: 48
                    radius: 12
                    color: Theme.surfaceContainerHigh

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "bolt"
                            size: 22
                            color: Theme.secondary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: `${root.powerUsage}W`
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Engine usage section
            Rectangle {
                visible: root.gfxUsage > 0 || root.memUsage > 0 || root.mediaUsage > 0
                width: parent.width
                height: engineColumn.height + Theme.spacingM * 2
                radius: 16
                color: Theme.surfaceContainerHigh

                Column {
                    id: engineColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    StyledText {
                        text: "Engine Activity"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    // GFX bar
                    Row {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            width: 50
                            text: "GFX"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: parent.width - 100
                            height: 8
                            radius: 4
                            color: Theme.surfaceContainerHighest
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: parent.width * (root.gfxUsage / 100)
                                height: parent.height
                                radius: 4
                                color: Theme.primary

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        StyledText {
                            width: 40
                            text: `${root.gfxUsage.toFixed(0)}%`
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // MEM bar
                    Row {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            width: 50
                            text: "MEM"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: parent.width - 100
                            height: 8
                            radius: 4
                            color: Theme.surfaceContainerHighest
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: parent.width * (root.memUsage / 100)
                                height: parent.height
                                radius: 4
                                color: Theme.secondary

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        StyledText {
                            width: 40
                            text: `${root.memUsage.toFixed(0)}%`
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Media bar
                    Row {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            width: 50
                            text: "Media"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: parent.width - 100
                            height: 8
                            radius: 4
                            color: Theme.surfaceContainerHighest
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: parent.width * (root.mediaUsage / 100)
                                height: parent.height
                                radius: 4
                                color: Theme.secondary

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        StyledText {
                            width: 40
                            text: `${root.mediaUsage.toFixed(0)}%`
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Process list
            Column {
                visible: root.processes.length > 0
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "apps"
                        size: 18
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: `GPU Processes (${root.processes.length})`
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                DankListView {
                    width: parent.width
                    height: Math.min(contentHeight, 250)
                    model: root.processes
                    spacing: Theme.spacingXS
                    clip: true

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 44
                        radius: 8
                        color: Theme.surfaceContainerHigh

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingS

                            Column {
                                width: parent.width - procBadgesRow.width - Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                StyledText {
                                    width: parent.width
                                    text: modelData.name
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    text: `PID ${modelData.pid}`
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 2
                                }
                            }

                            Row {
                                id: procBadgesRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingXS

                                // VRAM badge
                                Rectangle {
                                    width: 70
                                    height: 24
                                    radius: 12
                                    color: Theme.primaryHover

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        DankIcon {
                                            name: "memory"
                                            size: 14
                                            color: Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: `${modelData.vram} ${modelData.vramUnit}`
                                            color: Theme.primary
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                            font.weight: Font.Medium
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                // GPU badge
                                Rectangle {
                                    width: 52
                                    height: 24
                                    radius: 12
                                    color: Theme.surfaceContainerHighest
                                    opacity: modelData.gfx > 0 ? 1 : 0.3

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        DankIcon {
                                            name: "speed"
                                            size: 14
                                            color: Theme.surfaceText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: modelData.gfx > 0 ? `${modelData.gfx}%` : "—"
                                            color: Theme.surfaceText
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                            font.weight: Font.Medium
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                // CPU badge
                                Rectangle {
                                    width: 52
                                    height: 24
                                    radius: 12
                                    color: Theme.surfaceContainerHighest
                                    opacity: modelData.cpu > 0 ? 1 : 0.3

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        DankIcon {
                                            name: "developer_board"
                                            size: 14
                                            color: Theme.surfaceText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: modelData.cpu > 0 ? `${modelData.cpu}%` : "—"
                                            color: Theme.surfaceText
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                            font.weight: Font.Medium
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // DMS style (matches ProcessListPopout aesthetic)
    Component {
        id: dmsStyleContent

        Column {
            width: parent.width
            spacing: Theme.spacingM

            // Gauges row
            Item {
                width: parent.width
                height: gaugesRow.height

                readonly property real gaugeSize: Theme.fontSizeMedium * 6.5

                Row {
                    id: gaugesRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingM

                    CircleGauge {
                        width: parent.parent.gaugeSize
                        height: parent.parent.gaugeSize
                        value: root.gpuUsage / 100
                        label: root.gpuUsage.toFixed(0) + "%"
                        sublabel: "GPU"
                        accentColor: root.gpuUsage > 80 ? Theme.error : (root.gpuUsage > 50 ? Theme.warning : Theme.primary)
                    }

                    CircleGauge {
                        width: parent.parent.gaugeSize
                        height: parent.parent.gaugeSize
                        value: root.vramPercent / 100
                        label: (root.vramUsed / 1024).toFixed(1) + " GB"
                        sublabel: "VRAM"
                        detail: root.vramPercent.toFixed(0) + "%"
                        accentColor: root.vramPercent > 90 ? Theme.error : (root.vramPercent > 70 ? Theme.warning : Theme.secondary)
                    }

                    CircleGauge {
                        visible: root.temperature > 0
                        width: parent.parent.gaugeSize
                        height: parent.parent.gaugeSize
                        value: Math.min(1, root.temperature / 100)
                        label: root.temperature + "°C"
                        sublabel: "Temp"
                        detail: root.powerUsage > 0 ? (root.powerUsage + "W") : ""
                        accentColor: root.temperature > 85 ? Theme.error : (root.temperature > 70 ? Theme.warning : Theme.info)
                        detailColor: Theme.surfaceVariantText
                    }
                }
            }

            // Engine activity section
            Rectangle {
                visible: root.gfxUsage > 0 || root.memUsage > 0 || root.mediaUsage > 0
                width: parent.width
                height: engineContent.height + Theme.spacingM * 2
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)

                Column {
                    id: engineContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    Row {
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "speed"
                            size: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Engine Activity"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    EngineBar {
                        width: parent.width
                        label: "GFX"
                        value: root.gfxUsage
                        barColor: Theme.primary
                    }

                    EngineBar {
                        width: parent.width
                        label: "MEM"
                        value: root.memUsage
                        barColor: Theme.secondary
                    }

                    EngineBar {
                        width: parent.width
                        label: "Media"
                        value: root.mediaUsage
                        barColor: Theme.info
                    }
                }
            }

            // Process list section
            Column {
                visible: root.processes.length > 0
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "apps"
                        size: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: `GPU Processes (${root.processes.length})`
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                DankListView {
                    width: parent.width
                    height: Math.min(contentHeight, 220)
                    model: root.processes
                    spacing: 2
                    clip: true

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 44
                        radius: Theme.cornerRadius
                        color: procMouseArea.containsMouse
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06)
                            : "transparent"
                        border.color: procMouseArea.containsMouse
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            : "transparent"
                        border.width: 1

                        MouseArea {
                            id: procMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            spacing: Theme.spacingS

                            // Process name column
                            Item {
                                width: parent.width - vramBadge.width - gfxBadge.width - cpuBadge.width - Theme.spacingS * 3
                                height: parent.height

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        name: "terminal"
                                        size: Theme.iconSize - 4
                                        color: Theme.surfaceText
                                        opacity: 0.8
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        StyledText {
                                            text: modelData.name
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            color: Theme.surfaceText
                                            elide: Text.ElideRight
                                            width: Math.min(implicitWidth, 120)
                                        }

                                        StyledText {
                                            text: `PID: ${modelData.pid}`
                                            font.pixelSize: Theme.fontSizeSmall - 2
                                            color: Theme.surfaceVariantText
                                        }
                                    }
                                }
                            }

                            // VRAM badge
                            Rectangle {
                                id: vramBadge
                                width: 95
                                height: 24
                                radius: Theme.cornerRadius
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    DankIcon {
                                        name: "memory"
                                        size: 12
                                        color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: `${modelData.vram} ${modelData.vramUnit}`
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            // GFX badge
                            Rectangle {
                                id: gfxBadge
                                width: 64
                                height: 24
                                radius: Theme.cornerRadius
                                color: modelData.gfx > 50
                                    ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12)
                                    : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.06)
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    DankIcon {
                                        name: "speed"
                                        size: 12
                                        color: modelData.gfx > 50 ? Theme.warning : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: modelData.gfx > 0 ? `${modelData.gfx}%` : "—"
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        font.weight: Font.Bold
                                        color: modelData.gfx > 50 ? Theme.warning : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            // CPU badge
                            Rectangle {
                                id: cpuBadge
                                width: 64
                                height: 24
                                radius: Theme.cornerRadius
                                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.06)
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    DankIcon {
                                        name: "developer_board"
                                        size: 12
                                        color: Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: modelData.cpu > 0 ? `${modelData.cpu}%` : "—"
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        font.weight: Font.Bold
                                        color: Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // CircleGauge component (matching ProcessListPopout style)
    component CircleGauge: Item {
        id: gaugeRoot

        property real value: 0
        property string label: ""
        property string sublabel: ""
        property string detail: ""
        property color accentColor: Theme.primary
        property color detailColor: Theme.surfaceVariantText

        readonly property real thickness: Math.max(4, Math.min(width, height) / 15)
        readonly property real glowExtra: thickness * 1.4
        readonly property real arcPadding: thickness / 1.3

        readonly property real innerDiameter: width - (arcPadding + thickness + glowExtra) * 2
        readonly property real maxTextWidth: innerDiameter * 0.9
        readonly property real baseLabelSize: Math.round(width * 0.18)
        readonly property real labelSize: Math.round(Math.min(baseLabelSize, maxTextWidth / Math.max(1, label.length * 0.65)))
        readonly property real sublabelSize: Math.round(Math.min(width * 0.13, maxTextWidth / Math.max(1, sublabel.length * 0.7)))
        readonly property real detailSize: Math.round(Math.min(width * 0.12, maxTextWidth / Math.max(1, detail.length * 0.65)))

        property real animValue: 0

        onValueChanged: animValue = Math.min(1, Math.max(0, value))

        Behavior on animValue {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Easing.OutCubic
            }
        }

        Component.onCompleted: animValue = Math.min(1, Math.max(0, value))

        Canvas {
            id: glowCanvas
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2;
                const cy = height / 2;
                const radius = (Math.min(width, height) / 2) - gaugeRoot.arcPadding;
                const startAngle = -Math.PI * 0.5;
                const endAngle = Math.PI * 1.5;

                ctx.lineCap = "round";

                if (gaugeRoot.animValue > 0) {
                    const prog = startAngle + (endAngle - startAngle) * gaugeRoot.animValue;
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, startAngle, prog);
                    ctx.strokeStyle = Qt.rgba(gaugeRoot.accentColor.r, gaugeRoot.accentColor.g, gaugeRoot.accentColor.b, 0.2);
                    ctx.lineWidth = gaugeRoot.thickness + gaugeRoot.glowExtra;
                    ctx.stroke();
                }
            }

            Connections {
                target: gaugeRoot
                function onAnimValueChanged() { glowCanvas.requestPaint(); }
                function onAccentColorChanged() { glowCanvas.requestPaint(); }
                function onWidthChanged() { glowCanvas.requestPaint(); }
                function onHeightChanged() { glowCanvas.requestPaint(); }
            }

            Component.onCompleted: requestPaint()
        }

        Canvas {
            id: arcCanvas
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2;
                const cy = height / 2;
                const radius = (Math.min(width, height) / 2) - gaugeRoot.arcPadding;
                const startAngle = -Math.PI * 0.5;
                const endAngle = Math.PI * 1.5;

                ctx.lineCap = "round";

                ctx.beginPath();
                ctx.arc(cx, cy, radius, startAngle, endAngle);
                ctx.strokeStyle = Qt.rgba(gaugeRoot.accentColor.r, gaugeRoot.accentColor.g, gaugeRoot.accentColor.b, 0.1);
                ctx.lineWidth = gaugeRoot.thickness;
                ctx.stroke();

                if (gaugeRoot.animValue > 0) {
                    const prog = startAngle + (endAngle - startAngle) * gaugeRoot.animValue;
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, startAngle, prog);
                    ctx.strokeStyle = gaugeRoot.accentColor;
                    ctx.lineWidth = gaugeRoot.thickness;
                    ctx.stroke();
                }
            }

            Connections {
                target: gaugeRoot
                function onAnimValueChanged() { arcCanvas.requestPaint(); }
                function onAccentColorChanged() { arcCanvas.requestPaint(); }
                function onWidthChanged() { arcCanvas.requestPaint(); }
                function onHeightChanged() { arcCanvas.requestPaint(); }
            }

            Component.onCompleted: requestPaint()
        }

        Column {
            anchors.centerIn: parent
            spacing: 1

            StyledText {
                text: gaugeRoot.label
                font.pixelSize: gaugeRoot.labelSize
                font.weight: Font.Bold
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: gaugeRoot.sublabel
                font.pixelSize: gaugeRoot.sublabelSize
                font.weight: Font.Medium
                color: gaugeRoot.accentColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: gaugeRoot.detail
                font.pixelSize: gaugeRoot.detailSize
                color: gaugeRoot.detailColor
                anchors.horizontalCenter: parent.horizontalCenter
                visible: gaugeRoot.detail.length > 0
            }
        }
    }

    // Engine bar component
    component EngineBar: Item {
        id: engineBarRoot
        height: 24

        property string label: ""
        property real value: 0
        property color barColor: Theme.primary

        Row {
            anchors.fill: parent
            spacing: Theme.spacingS

            StyledText {
                width: 50
                text: engineBarRoot.label
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: parent.width - 100
                height: 8
                radius: 4
                color: Theme.surfaceContainerHighest
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: parent.width * (engineBarRoot.value / 100)
                    height: parent.height
                    radius: 4
                    color: engineBarRoot.barColor

                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }

            StyledText {
                width: 40
                text: `${engineBarRoot.value.toFixed(0)}%`
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
