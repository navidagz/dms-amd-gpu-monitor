---
layout: default
title: Documentation
---

# AMD GPU Monitor Documentation

Welcome to the AMD GPU Monitor documentation. This plugin (v4.2.0) provides real-time monitoring of AMD GPU statistics for DankMaterialShell.

## Quick Navigation

### Getting Started

- [**Installation Guide**](installation) - Set up the plugin and dependencies
- [**Configuration**](configuration) - Customize behavior and appearance

### Help & Reference

- [**Troubleshooting**](troubleshooting) - Common issues and solutions
- [**Technical Details**](technical-details) - How it works and data fields

## Overview

AMD GPU Monitor tracks:

- GPU usage — overall % is the max of GFX, Memory, and Media Engine activity
- VRAM statistics with auto-scaling display (MiB or GiB)
- Temperature (edge sensor, °C) and average power consumption (W)
- Per-process GPU metrics, filtered to processes actively using the GPU

## Screenshots

![AMD GPU Monitor](images/screenshot.png)

## Quick Links

- [GitHub Repository](https://github.com/navidagz/dms-amd-gpu-monitor)
- [Report an Issue](https://github.com/navidagz/dms-amd-gpu-monitor/issues)
- [DankMaterialShell](https://github.com/DankMaterialShell)

## Features at a Glance

- Real-time GPU monitoring
- VRAM usage tracking
- Temperature and power metrics
- Per-process statistics
- Color-coded indicators
- Smooth animations
- Three popout visual styles (Default, Alternative, Legacy)
- Configurable update interval (1s–15s)
- Configurable process list sort order (VRAM, GFX, CPU, Name, PID)
- Multi-GPU widget variants with automatic PCI-based detection
- Inline editing of widget display names and icons
- Loading indicator while GPUs are detected
- Process list column headers and hover tooltips for long names
- Settings UI — no manual file editing required
- Shared GPU stats service polls `amdgpu_top` once per tick for all widgets and screens
