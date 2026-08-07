---
layout: default
title: Technical Details
---

# Technical Details

## How It Works

The plugin uses `amdgpu_top` with JSON output mode to gather GPU statistics:

1. A single `AmdGpuService` singleton polls `amdgpu_top` once per update cycle.
2. Each widget and the settings UI subscribe to the service with `request(widget, interval)` and release it on destruction.
3. The shared `Timer` runs only while subscribers exist and uses the shortest requested interval, so the fastest widget sets the pace (default: 4000 ms, configurable per widget as 1s–15s).
4. A `Process { command: ["amdgpu_top", "-J", "-n", "1"] }` is guarded so a new poll never starts while the previous one is still running.
5. A `StdioCollector` captures stdout; when the stream finishes the JSON is parsed inside a `try`/`catch`. Parse failures, non-zero exit codes, and stderr output all set a shared `statsError` flag (shown as a red-tinted bar icon on every widget) without resetting existing values.
6. State properties are updated and the UI re-renders reactively via QML bindings; the process list is only reassigned when its contents actually changed, avoiding needless list-view churn.

## Data Fields

### GPU Activity

Overall `gpuUsage` is `Math.max(gfxUsage, memUsage, mediaUsage)`.

| Field | Source key | Description |
|---|---|---|
| `gfxUsage` | `gpu_activity.GFX.value` | Graphics engine usage (%) |
| `memUsage` | `gpu_activity.Memory.value` | Memory controller usage (%) |
| `mediaUsage` | `gpu_activity.MediaEngine.value` | Video encode/decode usage (%) |

### VRAM

| Field | Source key | Description |
|---|---|---|
| `vramUsed` | `VRAM["Total VRAM Usage"].value` | Currently allocated VRAM (MiB) |
| `vramTotal` | `VRAM["Total VRAM"].value` | Total available VRAM (MiB) |

Display auto-scales: if total < 1024 MiB, values are shown in MiB; otherwise they are converted to GiB with one decimal place.

### Sensors

| Field | Source key | Description |
|---|---|---|
| `temperature` | `gpu_metrics.temperature_edge` | Edge temperature (°C) |
| `powerUsage` | `Sensors["Average Power"].value` | Average power draw (W) |

### Error State

| Field | Set when | Description |
|---|---|---|
| `statsError` | `amdgpu_top` exits non-zero, writes to stderr, or its stdout fails `JSON.parse` | Drives the red bar-icon tint; last-known values are kept, not reset |

### Per-Process Metrics (fdinfo)

Only processes where `vram > 0 || gfx > 0` are included. The list is sorted by VRAM descending.

| Field | Source key | Description |
|---|---|---|
| `vram` | `fdinfo[pid].usage.VRAM.value` | VRAM allocated (MiB) |
| `gfx` | `fdinfo[pid].usage.GFX.value` | Graphics engine time (%) |
| `cpu` | `fdinfo[pid].usage.CPU.value` | CPU usage by process (%) |
| `gtt` | `fdinfo[pid].usage.GTT.value` | GTT (Graphics Translation Table) memory |
| `compute` | `fdinfo[pid].usage.Compute.value` | Compute engine usage (%) |

Requires Linux kernel 5.14+ and AMDGPU driver with fdinfo support.

## Color Coding

Usage and temperature thresholds are centralized in `components/shared/CommonStyles.qml` and shared by all three popout styles:

| Range | Color | Meaning |
|---|---|---|
| < 70% | `Theme.primary` | Normal |
| 70–90% | `Theme.warning` | Warning |
| > 90% | `Theme.error` | Critical |

| Temperature | Color | Meaning |
|---|---|---|
| < 70°C | `Theme.info` | Normal |
| 70–85°C | `Theme.warning` | Warning |
| > 85°C | `Theme.error` | Critical |

All popout styles (Default, Alternative, Legacy) read the same thresholds, so changing `CommonStyles.qml` updates coloring everywhere consistently.

## Popout Visual Styles

| Style | Key | Components |
|---|---|---|
| **Default** | `"default"` | Three circular arc gauges (GPU %, VRAM, Temp+Power) + engine bars + process list |
| **Alternative** | `"alt"` | Two stat cards (GPU %, VRAM GiB) + chip badges (temp, power) + engine bars + process list |
| **Legacy** | `"legacy"` | Full-width horizontal progress bars + columnar text stats + process list |

## Shared UI Components

| File | Purpose |
|---|---|
| `components/shared/CircleGauge.qml` | Animated arc gauge with glow, label, sublabel, detail text, and auto-scaling fonts |
| `components/shared/EngineBar.qml` | Label + animated horizontal bar + percentage; used for GFX/Memory/Media rows |
| `components/shared/ProgressBar.qml` | Generic animated fill bar; configurable height, radius, colors |
| `components/shared/StatCard.qml` | Rounded card with icon, label, large bold value, and a thin progress bar |
| `components/shared/CommonStyles.qml` | Shared layout constants (`largePanelRadius: 16`, `mediumPanelRadius: 12`, `chipHeight: 48`, etc.) plus the shared usage/temperature color thresholds and `usageColor()`/`temperatureColor()` helpers |

## Animations

- Progress bars use `NumberAnimation` with `Easing.OutCubic` at 300 ms
- Circle gauges use `Theme.mediumDuration`

## Variant Detection and Matching

When the settings UI loads, the plugin runs `amdgpu_top -J -n 1` once and shows a loading spinner while detection is in progress. Detected GPUs are sorted by PCI address and stored as widget variants.

| Variant field | Source / purpose |
|---|---|
| `gpuPci` | PCI address from `amdgpu_top`; used as the stable identity for matching |
| `originalName` | The detected GPU name; used by the reset action |
| `name` / `icon` | User-editable display name and Material Symbol icon |
| `gpuType` | `APU`, `dGPU`, or empty for suspended devices that do not report a type |
| `description` | Human-readable description shown in **Add Widget** |

### Matching rules

- A variant with a matching `gpuPci` is reused; its `name` and `icon` are preserved unless the user resets them.
- Suspended GPUs report an empty `type`; the plugin keeps the previously stored `gpuType` instead of clearing it.
- Legacy variants that have `gpuIndex` are adopted by position the first time the matching GPU is detected, then matched by PCI on subsequent loads. They are labeled as `legacy` and can be removed in favour of auto-detected ones.

## Plugin Manifest (`plugin.json`)

| Key | Value |
|---|---|
| `id` | `amdGpuMonitor` |
| `version` | `4.1.0` |
| `capabilities` | `dankbar-widget`, `monitoring` |
| `permissions` | `settings_read`, `settings_write`, `process` |
| `requires` | `amdgpu_top` |
