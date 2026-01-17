---
layout: default
title: Configuration
---

# Configuration

## Update Interval

Modify the update interval (default: 4000ms) in the QML file:

```qml
property int updateInterval: 4000  // Change to desired milliseconds
```

## Color Thresholds

Adjust the usage color thresholds in the `getUsageColor` function:

```qml
function getUsageColor(percent) {
    if (percent > 90) return Theme.error;      // Critical threshold
    if (percent > 70) return "#ffa500";        // Warning threshold
    return Theme.primary;                       // Normal color
}
```

## Temperature Warning

Modify the temperature threshold for red warning color:

```qml
color: root.temperature > 80 ? Theme.error : Theme.surfaceText
```

Default threshold is 80°C.
