# AMD GPU Monitor

Real-time AMD GPU monitoring for DankMaterialShell. Tracks usage, VRAM, temperature, power, and per-process GPU utilization.

![Screenshot](screenshot.png)

## Features

- GPU usage monitoring (GFX, Memory, Media Engine)
- VRAM statistics with capacity display
- Temperature and power consumption tracking
- Per-process GPU metrics (VRAM, GFX, CPU usage)
- Color-coded indicators (normal/warning/critical)
- Animated progress bars

## Quick Start

**Requirements:** AMD GPU with AMDGPU driver, `amdgpu_top`, QuickShell, DankMaterialShell

```bash
# Install amdgpu_top (Arch)
yay -S amdgpu_top

# Install plugin
cp -r AmdGpuMonior ~/.config/DankMaterialShell/plugins/
```

## Usage

**Bar Widget:** Compact display showing GPU usage % and VRAM (GB)

**Popout Panel:** Click widget for detailed metrics including device name, engine usage, temperature, power, and process list

## Documentation

📖 **[Full Documentation](https://navidagz.github.io/dms-amd-gpu-monitor/docs/)**

- [Installation Guide](https://navidagz.github.io/dms-amd-gpu-monitor/docs/installation)
- [Configuration](https://navidagz.github.io/dms-amd-gpu-monitor/docs/configuration)
- [Troubleshooting](https://navidagz.github.io/dms-amd-gpu-monitor/docs/troubleshooting)
- [Technical Details](https://navidagz.github.io/dms-amd-gpu-monitor/docs/technical-details)

## License

Part of DankMaterialShell. Check the main repository for license information.

## Credits

Built for [DankMaterialShell](https://github.com/DankMaterialShell) • Uses [amdgpu_top](https://github.com/Umio-Yasuno/amdgpu_top)
