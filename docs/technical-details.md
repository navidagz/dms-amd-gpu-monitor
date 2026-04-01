---
layout: default
title: Technical Details
---

# Technical Details

## How It Works

The plugin uses `amdgpu_top` with JSON output mode to gather GPU statistics:

1. A `Timer` fires every `updateInterval` ms (default: 4000 ms)
2. It launches `Process { command: ["amdgpu_top", "-J", "-n", "1"] }`
3. A `StdioCollector` captures stdout; when the stream finishes the JSON is parsed inline in QML JavaScript
4. State properties are updated and the UI re-renders reactively via QML bindings

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

| Range | Color | Meaning |
|---|---|---|
| < 70% | `Theme.primary` | Normal |
| 70–90% | `#ffa500` (orange) | Warning |
| > 90% | `Theme.error` (red) | Critical |

Temperature thresholds differ slightly by style:
- **Default style (gauges):** warning at 70°C, critical at 85°C
- **Alt and Legacy styles:** critical at 80°C

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
| `components/shared/CommonStyles.qml` | Shared layout constants (`largePanelRadius: 16`, `mediumPanelRadius: 12`, `chipHeight: 48`, etc.) |

## Animations

- Progress bars use `NumberAnimation` with `Easing.OutCubic` at 300 ms
- Circle gauges use `Theme.mediumDuration`

## Plugin Manifest (`plugin.json`)

| Key | Value |
|---|---|
| `id` | `amdGpuMonitor` |
| `version` | `2.0.0` |
| `capabilities` | `dankbar-widget`, `monitoring` |
| `permissions` | `settings_read`, `settings_write`, `process` |
| `requires` | `amdgpu_top` |
