# Changelog

All notable changes to this project are documented in this file.

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

### Performance
- The GPU process list is now diffed (length + content comparison) before being reassigned, avoiding unnecessary `DankListView` delegate churn (hover-state resets, layout thrash) on polls where process usage hasn't changed.
