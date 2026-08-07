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

### Process List Sort (`processSort`)

| | |
|---|---|
| **Type** | Selection |
| **Default** | `VRAM Usage` |
| **Options** | VRAM Usage, GPU Usage (GFX), CPU Usage, Process Name, PID |

Controls how the GPU process list is ordered in the popout panel. The list re-sorts immediately when the setting is changed.

### GPU Variants

Below the settings above, the plugin settings UI has a **Your GPUs** / **Configured Widgets** section for multi-GPU systems.

GPUs are discovered automatically using `amdgpu_top -J -n 1` and matched by PCI address, so you do not need to type a GPU index. Each detected GPU gets its own widget variant automatically:

1. Open the AMD GPU Monitor plugin settings.
2. Under **Configured Widgets**, each detected GPU already has a variant.
3. Go to **Add Widget** in the bar configuration and add the variant you want — it behaves as an independent widget instance targeting that GPU.

![GPU auto-detection and variant editing](images/settings.png)

#### Editing a variant

Click the pencil icon on a configured widget to change its display name and Material Symbol icon. Leave the icon text field empty to use the icon picked from the dropdown. Click **Save** to apply, or **Cancel** to discard changes.

Click the reset icon to restore the widget's original detected name and default icon.

#### Legacy variants

Variants created before v4.0.0 stored only a `gpuIndex`. These are automatically adopted by PCI address the first time the matching GPU is detected. Legacy entries are labeled with `(legacy)` tag and can be safely removed.

### Update Interval (`updateInterval`)

| | |
|---|---|
| **Type** | Selection |
| **Default** | `4000` ms |
| **Options** | 1s, 2s, 4s, 8s, 15s |

Controls how often `amdgpu_top` is polled. Lower values are more responsive but use more CPU; higher values reduce polling overhead.

All widgets share a single poll timer via `AmdGpuService`, and the fastest interval requested by any active widget drives that timer. For example, if one widget is set to 1s and another to 4s, both update every 1s.

---

## Advanced Configuration

### Usage Color Thresholds

Usage and temperature color thresholds are centralized in `components/shared/CommonStyles.qml`:

```qml
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
```

All three popout styles (`Default`, `Alternative`, `Legacy`) read these same thresholds, so editing this one file changes coloring everywhere consistently.

## Error Indication

If the bar widget's icon tints red, `amdgpu_top` failed on the last poll (non-zero exit, stderr output, or invalid JSON). See [Troubleshooting: Widget icon turns red](troubleshooting#widget-icon-turns-red--stats-stop-updating) for diagnosis steps. The widget keeps its last-known values during a transient failure.
