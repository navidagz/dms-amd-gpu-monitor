# AMD GPU Monitor

Real-time AMD GPU monitoring plugin (v2.0.0) for DankMaterialShell. Tracks usage, VRAM, temperature, power, and per-process GPU utilization.

![Screenshot](screenshot.png)

## Features

- GPU usage monitoring (GFX, Memory, Media Engine) — overall usage is the max of the three engines
- VRAM statistics with auto-scaling display (MiB or GiB)
- Temperature (edge sensor) and average power consumption tracking
- Per-process GPU metrics (VRAM, GFX, CPU, GTT, Compute) — filtered to active processes only
- Color-coded indicators (normal < 70% / warning 70–90% / critical > 90%)
- Smooth animations on all bars and gauges
- Three popout visual styles: Default (circle gauges), Alternative (stat cards), Legacy (text + bars)
- Configurable via DankMaterialShell settings UI — no manual file editing required

## Quick Start

**Requirements:** AMD GPU with AMDGPU driver, `amdgpu_top`, QuickShell, DankMaterialShell, Linux kernel 5.14+ (for per-process stats)

```bash
# Install amdgpu_top (Arch)
yay -S amdgpu_top
```

Install the plugin via the DankMaterialShell plugin store, or manually:

```bash
cp -r AmdGpuMonitor ~/.config/DankMaterialShell/plugins/
```

## Usage

**Bar Widget:** Always visible in the DankMaterialShell bar. Horizontal layout shows GPU usage % and VRAM (e.g. `45% | 6.2GiB`). Vertical layout shows icon and usage % only.

**Popout Panel:** Click the widget to open detailed metrics — device name, per-engine activity, temperature, power, and a sortable process list. Style is selectable from settings.

## Documentation

[Full Documentation](https://navidagz.github.io/dms-amd-gpu-monitor/docs/)

- [Installation Guide](https://navidagz.github.io/dms-amd-gpu-monitor/docs/installation)
- [Configuration](https://navidagz.github.io/dms-amd-gpu-monitor/docs/configuration)
- [Troubleshooting](https://navidagz.github.io/dms-amd-gpu-monitor/docs/troubleshooting)
- [Technical Details](https://navidagz.github.io/dms-amd-gpu-monitor/docs/technical-details)

## License

MIT License — Copyright 2026 Navid A.

## Credits

Built for [DankMaterialShell](https://github.com/DankMaterialShell) • Uses [amdgpu_top](https://github.com/Umio-Yasuno/amdgpu_top)

Special thanks to [@skrimix](https://github.com/skrimix) for contributions and feedback.
