import QtQuick

import qs.Common

QtObject {
    readonly property int largePanelRadius: 16
    readonly property int mediumPanelRadius: 12
    readonly property int smallBadgeRadius: 12
    readonly property int chipHeight: 48
    readonly property int badgeHeight: 24

    readonly property real usageWarningThreshold: 70
    readonly property real usageCriticalThreshold: 90
    readonly property real temperatureWarningThreshold: 70
    readonly property real temperatureCriticalThreshold: 85

    function usageColor(percent) {
        if (percent > usageCriticalThreshold) return Theme.error;
        if (percent > usageWarningThreshold) return Theme.warning;
        return Theme.primary;
    }

    function temperatureColor(temperature) {
        if (temperature > temperatureCriticalThreshold) return Theme.error;
        if (temperature > temperatureWarningThreshold) return Theme.warning;
        return Theme.info;
    }
}
