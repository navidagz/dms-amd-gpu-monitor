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
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: `${root.gpuUsage.toFixed(0)}% | ${(root.vramUsed / 1024).toFixed(1)}GB`
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    
    // Popout content
    popoutContent: Component {
        PopoutComponent {
            headerText: root.gpuName
            showCloseButton: true
            
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
                        height: processColumn.implicitHeight
                        radius: Theme.cornerRadius
                        clip: true
                        
                        Flickable {
                            anchors.fill: parent
                            contentHeight: processColumn.implicitHeight
                            
                            Column {
                                id: processColumn
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
                                            
                                            // Process name and PID
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
                                            
                                            // VRAM usage
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
                                            
                                            // GPU usage
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
                                            
                                            // CPU usage
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
    }
}
