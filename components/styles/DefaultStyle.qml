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

    Item {
        width: parent.width
        height: gaugesRow.height + Theme.spacingM * 2

        readonly property real gaugeSize: Theme.fontSizeMedium * 6.5

        Row {
            id: gaugesRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingM

            Shared.CircleGauge {
                width: parent.parent.gaugeSize
                height: parent.parent.gaugeSize
                value: root.gpuUsage / 100
                label: root.gpuUsage.toFixed(0) + "%"
                sublabel: "GPU"
                accentColor: root.gpuUsage > 80 ? Theme.error : (root.gpuUsage > 50 ? Theme.warning : Theme.primary)
            }

            Shared.CircleGauge {
                width: parent.parent.gaugeSize
                height: parent.parent.gaugeSize
                value: root.vramPercent / 100
                label: root.formatVram()
                sublabel: "VRAM"
                detail: root.vramPercent.toFixed(0) + "%"
                accentColor: root.vramPercent > 90 ? Theme.error : (root.vramPercent > 70 ? Theme.warning : Theme.secondary)
            }

            Shared.CircleGauge {
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

    Rectangle {
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

        Row {
            width: parent.width - Theme.spacingS * 2
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingS

            StyledText {
                width: parent.width - 95 - 64 - 64 - Theme.spacingS * 3
                text: "Process"
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            StyledText {
                width: 95
                text: "VRAM"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            StyledText {
                width: 64
                text: "GFX"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            StyledText {
                width: 64
                text: "CPU"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }
        }

        DankListView {
            width: parent.width
            height: Math.min(contentHeight, root.processListHeight)
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
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                    spacing: Theme.spacingS

                    Item {
                        width: parent.width - vramBadge.width - gfxBadge.width - cpuBadge.width - Theme.spacingS * 3
                        height: parent.height

                        Row {
                            width: parent.width
                            anchors.left: parent.left
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
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    text: `PID: ${modelData.pid}`
                                    font.pixelSize: Theme.fontSizeSmall - 2
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: vramBadge
                        width: 95
                        height: commonStyles.badgeHeight
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

                    Rectangle {
                        id: gfxBadge
                        width: 64
                        height: commonStyles.badgeHeight
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
                                text: modelData.gfx > 0 ? `${modelData.gfx}%` : "-"
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.weight: Font.Bold
                                color: modelData.gfx > 50 ? Theme.warning : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Rectangle {
                        id: cpuBadge
                        width: 64
                        height: commonStyles.badgeHeight
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
                                text: modelData.cpu > 0 ? `${modelData.cpu}%` : "-"
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
