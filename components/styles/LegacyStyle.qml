import QtQuick
import QtQuick.Controls

import qs.Common
import qs.Services
import qs.Widgets

import "../shared" as Shared

Column {
    required property var root

    width: parent ? parent.width : 0
    spacing: Theme.spacingL

    Shared.CommonStyles {
        id: commonStyles
    }

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

        Shared.ProgressBar {
            width: parent.width
            barHeight: 12
            barRadius: Theme.cornerRadius
            value: root.gpuUsage
            barColor: root.getUsageColor(root.gpuUsage)
        }
    }

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

        Shared.ProgressBar {
            width: parent.width
            barHeight: 12
            barRadius: Theme.cornerRadius
            value: root.vramPercent
            barColor: root.getUsageColor(root.vramPercent)
        }
    }

    Column {
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
                color: root.temperature > commonStyles.temperatureCriticalThreshold ? Theme.error : Theme.surfaceText
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

        DankListView {
            width: parent.width
            height: Math.min(contentHeight, root.processListHeight)
            model: root.processes
            spacing: 1
            clip: true

            delegate: Rectangle {
                width: ListView.view.width
                height: 50
                color: Theme.surfaceContainer
                radius: Theme.cornerRadius

                ToolTip.text: modelData.name
                ToolTip.visible: procMouseArea.containsMouse && nameLabel.implicitWidth > nameLabel.width
                ToolTip.delay: 400

                MouseArea {
                    id: procMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingM

                    Row {
                        width: 170
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        DankIcon {
                            name: DgopService.getProcessIcon(modelData.name || "")
                            size: Theme.iconSize - 4
                            color: Theme.surfaceText
                            opacity: 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: 140
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                id: nameLabel
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
