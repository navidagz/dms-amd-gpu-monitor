function processIcon(name) {
    const process = (name || "").toLowerCase().split("/").pop();
    if (["kitty", "alacritty", "wezterm", "konsole", "gnome-terminal", "foot", "xterm", "ghostty", "tilix"].some(terminal => process.includes(terminal))) return "terminal";
    if (/^(firefox|chrome|chromium|google-chrome|brave|vivaldi|opera)(?:[-_.]|$)/.test(process)) return "web";
    if (/^(steam|steamwebhelper|lutris|heroic|gamescope|wine|proton)(?:[-_.]|$)/.test(process)) return "sports_esports";
    if (/^blender(?:[-_.]|$)/.test(process)) return "view_in_ar";
    if (/^(obs|ffmpeg|mpv|vlc|kdenlive|davinci)(?:[-_.]|$)/.test(process)) return "movie";
    if (/^(gimp|krita|inkscape)(?:[-_.]|$)/.test(process)) return "palette";
    if (/^(code|codium|zed|idea|pycharm|clion)(?:[-_.]|$)/.test(process)) return "code";
    if (/^(kwin|gnome-shell|hyprland|sway|wayfire|xorg)(?:[-_.]|$)/.test(process)) return "desktop_windows";
    return "deployed_code";
}
