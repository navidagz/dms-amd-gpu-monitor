import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "amdGpuMonitor"

    // [{ name, pci, type, suspended }] as reported by amdgpu_top
    property var detectedGpus: []
    property string detectError: ""
    property bool detecting: true

    function variantDescription(gpu) {
        const kind = gpu.type === "APU" ? "Integrated" : gpu.type === "dGPU" ? "Discrete" : "";
        return kind ? `Monitor your ${kind.toLowerCase()} ${gpu.name}` : `Monitor your ${gpu.name}`;
    }

    // Pre-PCI variants only carry gpuIndex. Adopt them by position so the sync
    // below doesn't duplicate them and orphan the originals. Returns the PCI
    // addresses adopted, whose names came from the user and must not be reset.
    function migrateLegacyVariants() {
        const adopted = [];
        const legacy = (variants || []).filter(v => !v.gpuPci && v.gpuIndex !== undefined);
        if (legacy.length === 0)
            return adopted;

        const claimed = (variants || []).map(v => v.gpuPci).filter(pci => pci);
        for (const variant of legacy) {
            const gpu = AmdGpuService.deviceByIndex(variant.gpuIndex);
            if (!gpu || !gpu.pci || claimed.indexOf(gpu.pci) !== -1)
                continue;
            claimed.push(gpu.pci);
            adopted.push(gpu.pci);
            updateVariant(variant.id, {
                gpuPci: gpu.pci,
                gpuType: gpu.type || "",
                description: variantDescription(gpu),
                icon: variant.icon || "memory"
            });
        }
        return adopted;
    }

    // Matched by PCI so a GPU that suspends and returns keeps its existing widget.
    function syncVariantsToGpus() {
        const adopted = migrateLegacyVariants();

        for (const gpu of detectedGpus) {
            const existing = (variants || []).find(v => v.gpuPci === gpu.pci);
            // Never clear a remembered type with the empty one a suspended
            // device reports.
            const gpuType = gpu.type || existing?.gpuType || "";
            // Custom = the user changed the name away from the detected one
            // (stored in originalName). Reset restores from originalName.
            const custom = !!(existing?.name && existing.originalName && existing.name !== existing.originalName);
            const keepName = custom || adopted.indexOf(gpu.pci) !== -1;
            const name = existing && keepName ? existing.name : gpu.name;
            const icon = existing?.icon ? existing.icon : "memory";
            const config = {
                gpuPci: gpu.pci,
                gpuType: gpuType,
                originalName: gpu.name,
                description: variantDescription({ name: name, type: gpuType }),
                icon: icon
            };
            if (!existing) {
                createVariant(gpu.name, config);
            } else if (existing.name !== name
                       || existing.description !== config.description
                       || existing.gpuType !== gpuType
                       || existing.icon !== config.icon
                       || existing.originalName !== config.originalName) {
                updateVariant(existing.id, Object.assign({ name: name }, config));
            }
        }
    }

    onDetectedGpusChanged: syncVariantsToGpus()

    function refreshDetectedGpus() {
        const all = AmdGpuService.devices.slice();
        all.sort((a, b) => a.pci.localeCompare(b.pci));
        root.detectedGpus = all;
        root.detecting = false;
        root.detectError = AmdGpuService.statsError && !all.length
            ? "Could not run amdgpu_top. Is it installed?"
            : all.length ? "" : "No AMD GPUs detected.";
    }

    // Detection has to work with no widget in the bar, so subscribe while open.
    Component.onCompleted: {
        AmdGpuService.request(root, 2000);
        if (AmdGpuService.devices.length)
            refreshDetectedGpus();
    }
    Component.onDestruction: AmdGpuService.release(root)

    Connections {
        target: AmdGpuService
        function onDevicesChanged() {
            root.refreshDetectedGpus();
        }
        function onStatsErrorChanged() {
            root.refreshDetectedGpus();
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
        text: "Your GPUs"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Each detected GPU gets its own widget automatically. Add them from Add Widget in the Dank Bar settings."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: Math.max(resultsColumn.implicitHeight + Theme.spacingM * 2,
                         root.detecting ? 56 : 0)
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Row {
            id: detectingRow
            visible: root.detecting && root.detectedGpus.length === 0
            anchors.centerIn: parent
            spacing: Theme.spacingM

            Item {
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    id: detectSpinner
                    name: "progress_activity"
                    size: 20
                    color: Theme.surfaceVariantText
                    anchors.centerIn: parent
                }

                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: root.detecting && root.detectedGpus.length === 0
                }
            }

            StyledText {
                text: "Detecting GPUs..."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Column {
            id: resultsColumn
            visible: !detectingRow.visible
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            Repeater {
                model: root.detectedGpus

                Rectangle {
                    required property var modelData

                    width: parent.width
                    height: gpuRow.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainer

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        spacing: Theme.spacingM

                        DankIcon {
                            id: gpuIcon
                            name: "memory"
                            size: 20
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            id: gpuRow
                            width: parent.width - gpuIcon.width - Theme.spacingM * 2
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS

                            StyledText {
                                width: parent.width
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width
                                text: modelData.suspended ? `${modelData.pci} (suspended)` : modelData.pci
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.surfaceVariantText
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            StyledText {
                width: parent.width
                visible: root.detectError !== ""
                text: root.detectError
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.error
                wrapMode: Text.WordWrap
            }
        }
    }

    StyledText {
        width: parent.width
        text: "Configured Widgets"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Widgets currently saved in your settings. Legacy items can be safely removed here (requires re-adding the widget to your bar)"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
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

            Repeater {
                model: root.variantsModel

                Rectangle {
                    id: variantEntry

                    required property var modelData

                    readonly property bool legacy: !variantEntry.modelData.gpuPci || variantEntry.modelData.gpuIndex !== undefined

                    property bool editing: false
                    property string pendingIcon: ""       // text-field value, empty = use picker
                    property string pickerIcon: "memory"   // last dropdown selection

                    function beginEdit() {
                        const current = variantEntry.modelData.icon || "memory";
                        nameEditField.text = variantEntry.modelData.name || "";
                        variantEntry.pendingIcon = current;
                        variantEntry.pickerIcon = current;
                        iconTextField.text = current;
                        variantEntry.editing = true;
                        nameEditField.forceActiveFocus();
                    }

                    function commitEdit() {
                        const variant = variantEntry.modelData;
                        const newName = nameEditField.text.trim() || variant.name || "AMD GPU";
                        // Text field wins if non-empty; otherwise the dropdown.
                        const newIcon = variantEntry.pendingIcon || variantEntry.pickerIcon || "memory";
                        root.updateVariant(variant.id, { name: newName, icon: newIcon });
                        variantEntry.editing = false;
                        ToastService.showInfo(`Updated widget: ${newName}`);
                    }

                    function resetEdit() {
                        const variant = variantEntry.modelData;
                        const originalName = variant.originalName || "AMD GPU";
                        root.updateVariant(variant.id, { name: originalName, icon: "memory" });
                        ToastService.showInfo(`Reset widget: ${originalName}`);
                    }

                    width: parent.width
                    height: editing ? editorColumn.implicitHeight + Theme.spacingM * 2
                                    : displayRow.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainer

                    Row {
                        id: displayRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingS
                        spacing: Theme.spacingS
                        visible: !variantEntry.editing

                        DankIcon {
                            id: variantIcon
                            name: variantEntry.modelData.icon || "memory"
                            size: 20
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            id: variantRow
                            width: parent.width - variantIcon.width - editVariantButton.width - deleteVariantButton.width - (resetVariantButton.visible ? resetVariantButton.width + Theme.spacingS : 0) - Theme.spacingS * 3
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS

                            StyledText {
                                width: parent.width
                                text: variantEntry.modelData.name || "Unnamed"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width
                                text: {
                                    const variant = variantEntry.modelData;
                                    const target = variant.gpuPci || (variant.gpuIndex !== undefined ? `GPU ${variant.gpuIndex}` : "unassigned");
                                    return variantEntry.legacy ? `${target} (legacy)` : target;
                                }
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: variantEntry.legacy ? Theme.warning : Theme.surfaceVariantText
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            id: editVariantButton
                            width: 28
                            height: 28
                            radius: 14
                            color: editVariantArea.containsMouse ? Theme.outline : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: "edit"
                                size: 16
                                color: editVariantArea.containsMouse ? Theme.surfaceText : Theme.surfaceVariantText
                            }

                            MouseArea {
                                id: editVariantArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: variantEntry.beginEdit()
                            }
                        }

                        Rectangle {
                            id: resetVariantButton
                            width: 28
                            height: 28
                            radius: 14
                            color: resetVariantArea.containsMouse ? Theme.outline : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            visible: variantEntry.modelData.name !== variantEntry.modelData.originalName

                            DankIcon {
                                anchors.centerIn: parent
                                name: "restart_alt"
                                size: 16
                                color: resetVariantArea.containsMouse ? Theme.surfaceText : Theme.surfaceVariantText
                            }

                            MouseArea {
                                id: resetVariantArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: variantEntry.resetEdit()
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
                                    const variant = variantEntry.modelData;
                                    root.removeVariant(variant.id);
                                    ToastService.showInfo(`Removed widget: ${variant.name || variant.id}`);
                                }
                            }
                        }
                    }

                    Column {
                        id: editorColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingS
                        visible: variantEntry.editing
                        spacing: Theme.spacingS

                        DankTextField {
                            id: nameEditField
                            width: parent.width
                            placeholderText: "Widget name"
                            maximumLength: 40
                            onAccepted: variantEntry.commitEdit()
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            DankIcon {
                                name: variantEntry.pendingIcon || variantEntry.pickerIcon || "memory"
                                size: 20
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                width: parent.width - 20 - Theme.spacingS
                                text: "Icon: pick from the dropdown or type a Material Symbol name. Leave the field empty to use the dropdown selection."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            DankTextField {
                                id: iconTextField
                                width: Math.max(120, parent.width - iconPicker.width - Theme.spacingS)
                                height: iconPicker.height
                                placeholderText: "e.g. shadow"
                                maximumLength: 60
                                anchors.verticalCenter: parent.verticalCenter
                                onTextEdited: {
                                    // Empty text = defer to the dropdown.
                                    variantEntry.pendingIcon = text.trim();
                                }
                                onAccepted: variantEntry.commitEdit()
                            }

                            DankIconPicker {
                                id: iconPicker
                                width: 200
                                height: 36
                                currentIcon: variantEntry.pickerIcon
                                anchors.verticalCenter: parent.verticalCenter
                                onIconSelected: (iconName, iconType) => {
                                    variantEntry.pickerIcon = iconName;
                                    // If the text field is empty, the dropdown
                                    // selection is the effective icon.
                                    if (!iconTextField.text.trim())
                                        variantEntry.pendingIcon = iconName;
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingXS

                            DankIcon {
                                name: "open_in_new"
                                size: Theme.fontSizeSmall
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "Browse all Material Symbols"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primary
                                linkColor: Theme.primary

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("https://fonts.google.com/icons?icon.set=Material+Symbols")
                                }
                            }
                        }

                        Row {
                            spacing: Theme.spacingS

                            DankButton {
                                text: "Save"
                                iconName: "save"
                                onClicked: variantEntry.commitEdit()
                            }

                            DankButton {
                                text: "Cancel"
                                onClicked: variantEntry.editing = false
                            }
                        }
                    }
                }
            }

            StyledText {
                width: parent.width
                visible: (root.variants || []).length === 0
                text: "No widgets configured yet."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }
}
