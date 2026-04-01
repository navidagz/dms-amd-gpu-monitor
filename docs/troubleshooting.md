---
layout: default
title: Troubleshooting
---

# Troubleshooting

## Plugin not showing data

### Check if amdgpu_top is installed
```bash
which amdgpu_top
amdgpu_top -J -n 1
```

The second command should produce valid JSON output. If it errors or hangs, the plugin will not work.

### Verify GPU is detected
```bash
ls /sys/class/drm/card*/device/vendor
```

### Check amdgpu driver is loaded
```bash
lsmod | grep amdgpu
```

## Permission issues

Some systems may require additional permissions to access GPU metrics:

```bash
# Add user to video group
sudo usermod -a -G video $USER
# Log out and back in for changes to take effect
```

## No process data

The per-process list will be empty if:

- Your kernel is older than 5.14 (fdinfo support is required)
- The AMDGPU driver does not include fdinfo support
- No processes are actively using the GPU (only processes with `vram > 0` or `gfx > 0` are shown)

## Common Issues

### Widget shows 0% usage despite GPU activity

- Ensure `amdgpu_top` has proper permissions
- Verify the driver is loaded: `lsmod | grep amdgpu`
- Test the JSON output directly: `amdgpu_top -J -n 1`
- Check if the user is in the `video` group: `groups $USER`

### Bar widget keeps resizing

Enable **Force Padding** in the plugin settings. This pads the widget to a fixed minimum width so it does not resize as values update.

### High CPU usage from the plugin

Increase the `updateInterval` property in `AmdGpuMonitorWidget.qml` to reduce polling frequency. The default is 4000 ms (4 seconds); setting it to 8000 ms or higher will halve the overhead.

### Popout panel is blank or fails to load

A mismatch between the selected `popoutStyle` and the available style files can cause the loader to fail silently. Reset the **Popout Style** setting to `default` in the settings UI.
