---
layout: default
title: Configuration
---

# Configuration

All settings are available in the DankMaterialShell settings UI under the AMD GPU Monitor plugin. No manual file editing is required for standard configuration.

## Settings UI Options

### Force Padding (`minimumWidth`)

| | |
|---|---|
| **Type** | Toggle |
| **Default** | Off |

When enabled, the bar widget is padded to the width of the widest possible value (`88% | 8.8GiB`). This prevents the widget from resizing as values change, keeping the bar layout stable.

### Popout Style (`popoutStyle`)

| | |
|---|---|
| **Type** | Selection |
| **Default** | `default` |

Controls the visual style of the popout panel when you click the bar widget.

| Value | Description |
|---|---|
| `default` | Three animated circular arc gauges (GPU %, VRAM, Temperature+Power) + engine activity bars + process list |
| `alt` | Two large stat cards (GPU % and VRAM GiB) + chip badges for temp/power + engine bars + process list |
| `legacy` | Plain text labels with full-width horizontal progress bars + columnar stats + process list |

### Process List Height (`processListHeight`)

| | |
|---|---|
| **Type** | Slider |
| **Default** | `250` px |
| **Range** | 100 – 750 px |

Sets the maximum height of the GPU process list in the popout panel.

---

## Advanced Configuration

The following require editing `AmdGpuMonitorWidget.qml` directly.

### Update Interval

Controls how often `amdgpu_top` is polled. Default is 4000 ms (4 seconds).

```qml
property int updateInterval: 4000
```

Increasing this value reduces CPU overhead from polling. Decreasing it gives more frequent updates.

### Usage Color Thresholds

```qml
function getUsageColor(percent) {
    if (percent > 90) return Theme.error;   // Critical — red
    if (percent > 70) return "#ffa500";     // Warning — orange
    return Theme.primary;                    // Normal
}
```

### Temperature Warning Threshold

In `LegacyStyle.qml` and `AltStyle.qml`, temperature turns red above 80°C:

```qml
color: root.temperature > 80 ? Theme.error : Theme.surfaceText
```

In `DefaultStyle.qml` (circle gauges), the gauge color changes at 70°C (warning) and 85°C (critical).
