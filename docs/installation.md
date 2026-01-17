---
layout: default
title: Installation Guide
---

# Installation Guide

## Requirements

- AMD GPU with AMDGPU driver support
- `amdgpu_top` utility installed and accessible in PATH
- QuickShell
- DankMaterialShell framework

## Installing amdgpu_top

### Arch Linux / AUR
```bash
yay -S amdgpu_top
```

### Build from Source
```bash
git clone https://github.com/Umio-Yasuno/amdgpu_top.git
cd amdgpu_top
cargo build --release
sudo cp target/release/amdgpu_top /usr/local/bin/
```

## Installing the Plugin

1. Copy the plugin folder to your DankMaterialShell plugins directory:
   ```bash
   cp -r AmdGpuMonior ~/.config/DankMaterialShell/plugins/
   ```

2. The plugin should be automatically detected by DankMaterialShell

## Permissions

Some systems may require additional permissions to access GPU metrics:

```bash
# Add user to video group
sudo usermod -a -G video $USER
# Log out and back in for changes to take effect
```
