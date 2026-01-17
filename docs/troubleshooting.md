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

### Verify GPU is detected
```bash
ls /sys/class/drm/card*/device/vendor
```

## Permission issues

Some systems may require additional permissions to access GPU metrics:

```bash
# Add user to video group
sudo usermod -a -G video $USER
# Log out and back in for changes to take effect
```

## No process data

Process information (fdinfo) may require:
- Recent kernel version (5.14+)
- AMDGPU driver with fdinfo support
- Processes actually using the GPU

## Common Issues

### Widget shows 0% usage despite GPU activity
- Ensure `amdgpu_top` has proper permissions
- Check if the AMDGPU driver is loaded: `lsmod | grep amdgpu`
- Verify the JSON output format: `amdgpu_top -J -n 1`

### High CPU usage
- Increase the `updateInterval` property to reduce polling frequency
- Default is 4000ms (4 seconds)
