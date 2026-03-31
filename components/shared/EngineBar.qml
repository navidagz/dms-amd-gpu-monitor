import QtQuick

import qs.Common
import qs.Widgets

Item {
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
