# Changelog

All notable changes to this project are documented in this file.

## [4.2.0]

### Added

- **Process List Sort** setting in the plugin settings UI. Choose between VRAM Usage, GPU Usage (GFX), CPU Usage, Process Name, or PID.
- Column headers (Process / VRAM / GFX / CPU) above the process list in the `Default` and `Alternative` popout styles.
- Hover tooltip on process names that shows the full name when the text is elided.

### Fixed

- Long process names no longer overflow and slide under the VRAM badge in the `Default` popout style.

## [4.1.0]

### Added

- **Shared GPU stats service** (`AmdGpuService.qml`): a singleton that polls `amdgpu_top` once per update cycle and feeds every widget and the settings UI.
- GPU detection in the settings UI now works even when no AMD GPU Monitor widget has been added to the bar.

### Changed

- Widgets subscribe to `AmdGpuService` instead of running their own `amdgpu_top` process.
- The fastest update interval requested by any active widget drives the shared poll timer, so a widget set to 1s still updates every second.
- `statsError` is now a shared state surfaced by the service; all widgets reflect the same error condition.

### Performance

- Reduced `amdgpu_top` invocations from one per widget per screen to one per tick. On multi-monitor setups with multiple GPU widgets this cuts CPU and IO overhead significantly.

### Fixed

- Eliminated per-widget `Process` instances that could become stale on GPU suspend/reset.

## [4.0.0]

### Added

- **GPU auto-detection**: GPUs are discovered automatically via `amdgpu_top -J -n 1` and matched by PCI address. Each detected GPU gets its own widget variant automatically.
- **Inline variant editing**: Click the pencil icon on any configured widget to edit its display name and Material Symbol icon; use the reset button to restore the original detected name and icon.
- **Loading indicator**: "Detecting GPUs..." spinner shown in settings while GPUs are being discovered.
- `screenshots/settings.png` and `docs/images/settings.png` showing the new auto-detection and editing UI.

### Changed

- Multi-GPU workflow is now PCI-based instead of manual GPU index entry. Variants store `gpuPci` instead of `gpuIndex` for stable matching across reboots and hardware changes.
- README and docs updated to describe the new auto-detection and inline editing flow.

### Fixed

- Variant `name` and `icon` are now preserved across GPU resyncs instead of being reset to detected defaults.
- Legacy `gpuIndex`-only variants are automatically adopted and migrated to PCI-based variants.
- Variant sync no longer skips legacy variants when a widget already covers the GPU.
- Variant removal is restored and works correctly.

### Removed

- Manual **Create GPU Variant** form requiring a GPU index; variants are now created automatically from detected GPUs.
- `screenshots/gpu-variant.png` (replaced by `settings.png`).

## [3.1.0]

### Added

- Configurable **Update Interval** setting (1s / 2s / 4s / 8s / 15s, default 4s) so polling frequency no longer requires hand-editing `AmdGpuMonitorWidget.qml`.
- Red bar-icon indicator (`statsError`) when `amdgpu_top` fails — non-zero exit, stderr output, or invalid JSON — so failures are visible instead of silently freezing the last-known values.
- `docs/`: documented the previously-undocumented **GPU Variants** settings section, and added an Error Indication section describing the new red-icon behavior.

### Fixed

- `amdgpu_top` output is now parsed inside a `try`/`catch`; malformed or partial JSON can no longer throw inside the stats `Process`'s signal handler.
- The stats poll timer no longer starts an overlapping `amdgpu_top` invocation while a previous one is still running.
- The sysfs temperature fallback (`find .../hwmon/*/temp1_input`) now force-stops after a 3s timeout instead of hanging indefinitely and blocking future temperature updates.
- Usage and temperature color thresholds are now centralized in `components/shared/CommonStyles.qml` (`usageColor()`, `temperatureColor()`) instead of being duplicated across the widget and all three popout styles; fixes the non-themed hardcoded `#ffa500` warning color and an inconsistent 80°C vs 85°C temperature-critical threshold between styles.
- `DefaultStyle.qml`'s VRAM gauge now reuses `formatVram()` instead of a duplicated inline formatter, fixing sub-1GiB GPUs displaying as `"0.5 GiB"` instead of `"512 MiB"`.
- Fixed a garbled leftover badge-markdown fragment in the README's Legacy style bullet.
- `docs/index.md`: corrected stale `v2.0.0` version reference to `3.1.0` and refreshed the features list (update interval, GPU variants).
- `docs/technical-details.md`: corrected the Color Coding table (was still showing the removed `#ffa500` literal) and the temperature-threshold description (was documenting a stale 80°C critical value); updated the plugin manifest version and `CommonStyles.qml` description.
- Fixed the docs screenshot 404 on GitHub Pages: Pages publishes only `docs/` as the site root, so a path escaping it (`../screenshots/screenshot.png`) could never resolve. The screenshot is now copied into `docs/images/` and referenced with an in-tree relative path.
- Removed a stray hardcoded version number from the README description; corrected documentation links to point at local files instead of external ones; corrected a screenshot path in the README.

### Performance

- The GPU process list is now diffed (length + content comparison) before being reassigned, avoiding unnecessary `DankListView` delegate churn (hover-state resets, layout thrash) on polls where process usage hasn't changed.

## [3.0.0]

### Added

- Multi-GPU **widget variants**: create named, per-GPU widget instances (each with its own `gpuIndex`) from the settings UI, so multiple AMD GPU Monitor widgets can target different GPUs simultaneously.
- Variant creation/listing/deletion UI in `AmdGpuMonitorSettings.qml`.
- Screenshots (`overview.png`, `gpu-variant.png`) and expanded README documentation for the variants workflow.

### Fixed

- GPU fallback and bar-stability issues surfaced during review of the multi-GPU variants change.
- Screenshot path corrections in the README.
- Documentation links changed to point at local files instead of external URLs.

## [2.0.0]

### Added

- **DMS (Default) popout style** with animated circular arc gauges, made the default popout style.
- **Alternative popout layout** — stat-card style with chip badges for temperature/power.
- Reusable shared components (`CircleGauge`, `EngineBar`, `ProgressBar`, `StatCard`, `CommonStyles`) extracted for use across all popout styles.
- Configurable **Process List Height** setting, with the effective value clamped to a supported range.
- `DankListView` used for the process list (replacing a plain `Flickable`) for consistent scrolling/behavior with the rest of DankMaterialShell.

### Changed

- Component directories renamed/reorganized (`components/shared`, `components/styles`) as part of splitting monolithic styles into separate files.
- VRAM/memory values switched to IEC units (MiB/GiB) for correctness.
- Alt-style media bar recolored to use `Theme.info`.

### Fixed

- Unified default process-list height across styles.
- Various style/typo fixes from splitting the popout styles into per-style files.

### Removed

- Jekyll site configuration and related files removed from the plugin repository (moved out of the widget's concern).

## [1.0.0]

Initial public release.

### Added

- Core AMD GPU Monitor plugin: polls `amdgpu_top -J -n 1` on a timer and renders GPU usage (GFX/Memory/Media, overall = max of the three), VRAM usage with auto-scaling MiB/GiB display, temperature, and average power draw.
- Per-process GPU metrics via `fdinfo` (VRAM, GFX, CPU, GTT, Compute), filtered to actively-using processes and sorted by VRAM.
- Horizontal and vertical bar pills showing GPU% and VRAM at a glance.
- Popout panel with detailed metrics and a process list.
- `Force Padding` setting to keep the bar width stable as values change.
- Jekyll-based documentation site (`docs/`) with installation, configuration, and troubleshooting guides.
- MIT License.
