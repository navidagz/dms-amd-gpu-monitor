import QtQuick

import qs.Common
import qs.Widgets

Rectangle {
    id: statCardRoot
    width: 100
    height: 100
    radius: 16
    color: Theme.surfaceContainerHigh

    property string iconName: ""
    property color iconColor: Theme.primary
    property string label: ""
    property string valueText: ""
    property real progressValue: 0
    property color progressColor: Theme.primary

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: statCardRoot.iconName
                size: 20
                color: statCardRoot.iconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: statCardRoot.label
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StyledText {
            text: statCardRoot.valueText
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
                width: parent.width * (statCardRoot.progressValue / 100)
                height: parent.height
                radius: 2
                color: statCardRoot.progressColor

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
