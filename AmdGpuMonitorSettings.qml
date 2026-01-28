import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "amdGpuMonitor"

    StyledText {
        width: parent.width
        text: "AMD GPU Monitor"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Monitor AMD GPU usage, VRAM, temperature and power consumption."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "minimumWidth"
        label: "Force Padding"
        description: "Prevent widget width from changing as values update"
        defaultValue: false
    }
}
