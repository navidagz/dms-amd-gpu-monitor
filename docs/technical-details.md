---
layout: default
title: Technical Details
---

# Technical Details

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

## Color Coding

The plugin uses color-coded indicators for visual feedback:
- **Normal**: Primary theme color (< 70%)
- **Warning**: Orange (70-90%)
- **Critical**: Red (> 90%)
