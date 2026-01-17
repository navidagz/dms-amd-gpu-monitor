# AMD GPU Monitor Plugin

A QuickShell plugin for DankMaterialShell that provides real-time monitoring of AMD GPU statistics including usage, VRAM, temperature, power consumption, and per-process GPU utilization.

![Screenshot](screenshot.png)

## Features

- **GPU Usage Monitoring**: Tracks GFX, Memory, and Media Engine usage
- **VRAM Statistics**: Real-time VRAM usage with total capacity display
- **Temperature Monitoring**: Current GPU edge temperature with visual warnings
- **Power Consumption**: Real-time power usage in watts
- **Process List**: Displays all processes using the GPU with detailed metrics:
  - Process name and PID
  - VRAM usage per process
  - GPU (GFX) usage percentage
  - CPU usage percentage
- **Color-coded Indicators**: Visual feedback with different colors for usage levels
  - Normal: Primary theme color (< 70%)
  - Warning: Orange (70-90%)
  - Critical: Red (> 90%)
- **Smooth Animations**: Animated progress bars for visual appeal

## Requirements

- AMD GPU with AMDGPU driver support
- `amdgpu_top` utility installed and accessible in PATH
- QuickShell
- DankMaterialShell framework

### Installing amdgpu_top

```bash
# Arch Linux / AUR
yay -S amdgpu_top

# Or build from source
git clone https://github.com/Umio-Yasuno/amdgpu_top.git
cd amdgpu_top
cargo build --release
sudo cp target/release/amdgpu_top /usr/local/bin/
```

## Installation

1. Copy the plugin folder to your DankMaterialShell plugins directory:
   ```bash
   cp -r AmdGpuMonior ~/.config/DankMaterialShell/plugins/
   ```

2. The plugin should be automatically detected by DankMaterialShell

## Usage

### Bar Widget

The plugin displays a compact widget in your bar showing:
- GPU icon
- Current GPU usage percentage
- Current VRAM usage in GB

Example: `🎮 75% | 4.2GB`

### Popout Panel

Click on the bar widget to open a detailed popout showing:
- GPU device name
- Overall GPU usage with progress bar
- VRAM usage with progress bar
- Individual engine usage (GFX, MEM, Media)
- Temperature (°C)
- Power consumption (W)
- List of GPU processes with detailed metrics

## Configuration

### Update Interval

Modify the update interval (default: 4000ms) in the QML file:

```qml
property int updateInterval: 4000  // Change to desired milliseconds
```

### Color Thresholds

Adjust the usage color thresholds in the `getUsageColor` function:

```qml
function getUsageColor(percent) {
    if (percent > 90) return Theme.error;      // Critical threshold
    if (percent > 70) return "#ffa500";        // Warning threshold
    return Theme.primary;                       // Normal color
}
```

### Temperature Warning

Modify the temperature threshold for red warning color:

```qml
color: root.temperature > 80 ? Theme.error : Theme.surfaceText
```

## How It Works

The plugin uses `amdgpu_top` with JSON output mode to gather GPU statistics:

1. Executes `amdgpu_top -J -n 1` every update interval
2. Parses JSON output to extract:
   - Device information
   - GPU activity metrics (GFX, Memory, Media Engine)
   - VRAM usage statistics
   - Temperature sensors
   - Power consumption
   - Per-process fdinfo data
3. Updates the UI with smooth animations

## Troubleshooting

### Plugin not showing data

**Check if amdgpu_top is installed:**
```bash
which amdgpu_top
amdgpu_top -J -n 1
```

**Verify GPU is detected:**
```bash
ls /sys/class/drm/card*/device/vendor
```

### Permission issues

Some systems may require additional permissions to access GPU metrics:

```bash
# Add user to video group
sudo usermod -a -G video $USER
# Log out and back in for changes to take effect
```

### No process data

Process information (fdinfo) may require:
- Recent kernel version (5.14+)
- AMDGPU driver with fdinfo support
- Processes actually using the GPU

## Data Fields

### GPU Activity
- **GFX**: Graphics engine usage
- **Memory**: Memory controller usage  
- **MediaEngine**: Video encode/decode usage

### VRAM
- **Used**: Currently allocated VRAM
- **Total**: Total available VRAM

### Per-Process Metrics
- **VRAM**: VRAM allocated to process
- **GFX**: Graphics engine time
- **CPU**: CPU usage by process
- **GTT**: GTT (Graphics Translation Table) memory
- **Compute**: Compute engine usage

## License

Part of DankMaterialShell. Check the main repository for license information.

## Credits

- Built for [DankMaterialShell](https://github.com/DankMaterialShell)
- Uses [amdgpu_top](https://github.com/Umio-Yasuno/amdgpu_top) for GPU metrics
