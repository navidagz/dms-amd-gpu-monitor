import QtQuick
import QtQuick.Controls

import qs.Common
import qs.Services
import qs.Widgets

import "../shared" as Shared

Column {
    required property var root

    width: parent ? parent.width : 0
    spacing: Theme.spacingM

    Shared.CommonStyles {
        id: commonStyles
    }

    Row {
        width: parent.width
        spacing: Theme.spacingM

        Shared.StatCard {
            width: (parent.width - Theme.spacingM) / 2
            iconName: "speed"
            iconColor: Theme.primary
            label: "GPU"
            valueText: `${root.gpuUsage.toFixed(0)}%`
            progressValue: root.gpuUsage
            progressColor: root.getUsageColor(root.gpuUsage)
        }

        Shared.StatCard {
            width: (parent.width - Theme.spacingM) / 2
            iconName: "memory"
            iconColor: Theme.secondary
            label: "VRAM"
            valueText: `${(root.vramUsed / 1024).toFixed(1)} GiB`
            progressValue: root.vramPercent
            progressColor: root.getUsageColor(root.vramPercent)
        }
    }

    Row {
        width: parent.width
        spacing: Theme.spacingS

        Rectangle {
            visible: root.temperature > 0
            width: (parent.width - Theme.spacingS) / 2
            height: commonStyles.chipHeight
            radius: commonStyles.mediumPanelRadius
            color: root.temperature > commonStyles.temperatureCriticalThreshold ? Theme.errorHover : Theme.surfaceContainerHigh

            Row {
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DankIcon {
                    name: "thermostat"
                    size: 22
                    color: root.temperature > commonStyles.temperatureCriticalThreshold ? Theme.error : Theme.secondary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: `${root.temperature}°C`
                    color: root.temperature > commonStyles.temperatureCriticalThreshold ? Theme.error : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            visible: root.powerUsage > 0
            width: (parent.width - Theme.spacingS) / 2
            height: commonStyles.chipHeight
            radius: commonStyles.mediumPanelRadius
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

    Rectangle {
        width: parent.width
        height: engineColumn.height + Theme.spacingM * 2
        radius: commonStyles.largePanelRadius
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

            Shared.EngineBar {
                width: parent.width
                label: "GFX"
                value: root.gfxUsage
                barColor: Theme.primary
            }

            Shared.EngineBar {
                width: parent.width
                label: "MEM"
                value: root.memUsage
                barColor: Theme.secondary
            }

            Shared.EngineBar {
                width: parent.width
                label: "Media"
                value: root.mediaUsage
                barColor: Theme.info
            }
        }
    }

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

        Row {
            width: parent.width - Theme.spacingM * 2
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingS

            StyledText {
                width: parent.width - procHeaderBadges.width - Theme.spacingS
                text: "Process"
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            Row {
                id: procHeaderBadges
                spacing: Theme.spacingXS

                StyledText {
                    width: 70
                    text: "VRAM"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.weight: Font.Medium
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    width: 52
                    text: "GFX"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.weight: Font.Medium
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    width: 52
                    text: "CPU"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.weight: Font.Medium
                    color: Theme.surfaceVariantText
                }
            }
        }

        DankListView {
            width: parent.width
            height: Math.min(contentHeight, root.processListHeight)
            model: root.processes
            spacing: Theme.spacingXS
            clip: true

            delegate: Rectangle {
                width: ListView.view.width
                height: 44
                radius: 8
                color: Theme.surfaceContainerHigh

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
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingM
                    spacing: Theme.spacingS

                    Row {
                        width: parent.width - procBadgesRow.width - Theme.spacingS
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
                            width: parent.width - (Theme.iconSize - 4) - Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                id: nameLabel
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
                    }

                    Row {
                        id: procBadgesRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        Rectangle {
                            width: 70
                            height: commonStyles.badgeHeight
                            radius: commonStyles.smallBadgeRadius
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

                        Rectangle {
                            width: 52
                            height: commonStyles.badgeHeight
                            radius: commonStyles.smallBadgeRadius
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
                                    text: modelData.gfx > 0 ? `${modelData.gfx}%` : "-"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Rectangle {
                            width: 52
                            height: commonStyles.badgeHeight
                            radius: commonStyles.smallBadgeRadius
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
                                    text: modelData.cpu > 0 ? `${modelData.cpu}%` : "-"
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
