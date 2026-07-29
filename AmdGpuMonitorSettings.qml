import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "amdGpuMonitor"

    // [{ name, pci, suspended }] as reported by amdgpu_top
    property var detectedGpus: []
    property string detectError: ""
    readonly property var gpuLabels: detectedGpus.map(g => g.suspended ? `${g.name} (suspended)` : g.name)
    property string selectedGpuLabel: ""

    function refreshVariants() {
        variantsModel.clear();
        for (let i = 0; i < variants.length; i++) {
            variantsModel.append(variants[i]);
        }
    }

    onVariantsChanged: refreshVariants()

    Component.onCompleted: {
        refreshVariants();
        detectGpusProcess.running = true;
    }

    Process {
        id: detectGpusProcess
        command: ["amdgpu_top", "-J", "-n", "1"]
        running: false

        onExited: exitCode => {
            if (exitCode !== 0)
                root.detectError = "Could not run amdgpu_top. Is it installed?";
        }

        stdout: StdioCollector {
            onStreamFinished: {
                let data;
                try {
                    data = JSON.parse(text.trim());
                } catch (e) {
                    root.detectError = "Could not parse amdgpu_top output.";
                    return;
                }

                const active = (data.devices || []).map(d => ({
                    name: d["Info"]?.["DeviceName"] || "AMD GPU",
                    pci: d["Info"]?.["PCI"] || "",
                    suspended: false
                }));
                // Suspended GPUs are listed separately and use flat keys.
                const asleep = (data.suspended_devices || []).map(d => ({
                    name: d.DeviceName || "AMD GPU",
                    pci: d.pci || "",
                    suspended: true
                }));

                const all = active.concat(asleep).filter(g => g.pci);
                all.sort((a, b) => a.pci.localeCompare(b.pci));
                root.detectedGpus = all;
                root.detectError = all.length ? "" : "No AMD GPUs detected.";
                if (all.length && !root.selectedGpuLabel)
                    root.selectedGpuLabel = root.gpuLabels[0];
            }
        }
    }

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
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "popoutStyle"
        label: "Popout Style"
        description: "Visual style for the popout panel"
        options: [
            { label: "Default", value: "default" },
            { label: "Alternative", value: "alt" },
            { label: "Legacy", value: "legacy" }
        ]
        defaultValue: "default"
    }

    SelectionSetting {
        settingKey: "updateInterval"
        label: "Update Interval"
        description: "How often amdgpu_top is polled. Lower values are more responsive but use more CPU."
        options: [
            { label: "1s", value: "1000" },
            { label: "2s", value: "2000" },
            { label: "4s", value: "4000" },
            { label: "8s", value: "8000" },
            { label: "15s", value: "15000" }
        ]
        defaultValue: "4000"
    }

    StringSetting {
        settingKey: "processListHeight"
        label: "Process List Height (px)"
        description: "Maximum height for the GPU process list. The widget clamps the effective value to its supported range."
        placeholder: "250"
        defaultValue: "250"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "GPU Variants"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Create per-GPU widget variants. Each variant appears as a separate widget in Add Widget and targets a detected GPU."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: variantCreator.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: variantCreator
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM

            Row {
                width: parent.width
                spacing: Theme.spacingM

                Column {
                    width: (parent.width - Theme.spacingM) / 2
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Variant Name"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    DankTextField {
                        id: variantNameField
                        width: parent.width
                        placeholderText: "GPU 1"
                    }
                }

                Column {
                    width: (parent.width - Theme.spacingM) / 2
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "GPU"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    DankDropdown {
                        width: parent.width
                        options: root.gpuLabels
                        currentValue: root.selectedGpuLabel
                        emptyText: "No GPUs detected"
                        onValueChanged: value => root.selectedGpuLabel = value
                    }
                }
            }

            StyledText {
                width: parent.width
                text: root.detectError
                visible: root.detectError !== ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.error
                wrapMode: Text.WordWrap
            }

            DankButton {
                text: "Create GPU Variant"
                iconName: "add"
                enabled: root.detectedGpus.length > 0
                onClicked: {
                    const gpu = root.detectedGpus[root.gpuLabels.indexOf(root.selectedGpuLabel)];
                    if (!gpu) {
                        ToastService.showError("Select a GPU");
                        return;
                    }

                    const variantName = variantNameField.text.trim() || gpu.name;
                    createVariant(variantName, {
                        gpuPci: gpu.pci,
                        description: `AMD GPU Monitor for ${gpu.name}`,
                        icon: "memory"
                    });
                    variantNameField.text = "";
                    ToastService.showInfo(`Created variant: ${variantName}`);
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: variantsListColumn.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: variantsListColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            StyledText {
                width: parent.width
                text: "Existing Variants"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Repeater {
                model: variantsModel

                Rectangle {
                    required property var modelData

                    width: parent.width
                    height: variantRow.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainer

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingS
                        spacing: Theme.spacingS

                        Column {
                            id: variantRow
                            width: parent.width - deleteVariantButton.width - Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS

                            StyledText {
                                width: parent.width
                                text: modelData.name || "Unnamed"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width
                                text: `${modelData.gpuPci || `GPU ${modelData.gpuIndex ?? 0}`} • ${modelData.fullId || modelData.id || ""}`
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.surfaceVariantText
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            id: deleteVariantButton
                            width: 28
                            height: 28
                            radius: 14
                            color: deleteVariantArea.containsMouse ? Theme.error : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: "delete"
                                size: 16
                                color: deleteVariantArea.containsMouse ? Theme.onError : Theme.surfaceVariantText
                            }

                            MouseArea {
                                id: deleteVariantArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    removeVariant(modelData.id);
                                    ToastService.showInfo(`Removed variant: ${modelData.name || modelData.id}`);
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                width: parent.width
                visible: variantsModel.count === 0
                text: "No GPU variants yet."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }
}
