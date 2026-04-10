import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "amdGpuMonitor"

    function refreshVariants() {
        variantsModel.clear();
        for (let i = 0; i < variants.length; i++) {
            variantsModel.append(variants[i]);
        }
    }

    onVariantsChanged: refreshVariants()

    Component.onCompleted: {
        refreshVariants();
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
        defaultValue: false
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

    StringSetting {
        settingKey: "processListHeight"
        label: "Process List Height (px)"
        description: "Maximum height for the GPU process list. Enter a value between 100 and 750."
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
        text: "Create per-GPU widget variants. Each variant appears as a separate widget in Add Widget and can target a different GPU index."
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
                        text: "GPU Index"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    DankTextField {
                        id: variantGpuIndexField
                        width: parent.width
                        placeholderText: "1"
                    }
                }
            }

            DankButton {
                text: "Create GPU Variant"
                iconName: "add"
                onClicked: {
                    const rawIndex = variantGpuIndexField.text.trim();
                    const parsedIndex = parseInt(rawIndex);
                    if (rawIndex === "" || isNaN(parsedIndex) || parsedIndex < 0) {
                        ToastService.showError("Enter a valid GPU index");
                        return;
                    }

                    const variantName = variantNameField.text.trim() || `GPU ${parsedIndex}`;
                    createVariant(variantName, {
                        gpuIndex: parsedIndex,
                        description: `AMD GPU Monitor for GPU ${parsedIndex}`,
                        icon: "memory"
                    });
                    variantNameField.text = "";
                    variantGpuIndexField.text = "";
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
                    height: 44
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainer

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingS
                        spacing: Theme.spacingS

                        Column {
                            width: parent.width - deleteVariantButton.width - Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

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
                                text: `GPU ${modelData.gpuIndex ?? 0} • ${modelData.fullId || modelData.id || ""}`
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
