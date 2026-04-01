import QtQuick

import qs.Common

Item {
    id: progressBarRoot
    height: barHeight

    property real value: 0
    property real barHeight: 12
    property real barRadius: barHeight / 2
    property color barColor: Theme.primary
    property color backgroundColor: Theme.surfaceText

    Rectangle {
        anchors.fill: parent
        color: progressBarRoot.backgroundColor
        radius: progressBarRoot.barRadius

        Rectangle {
            width: parent.width * Math.min(1, progressBarRoot.value / 100)
            height: parent.height
            color: progressBarRoot.barColor
            radius: progressBarRoot.barRadius

            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }
}
