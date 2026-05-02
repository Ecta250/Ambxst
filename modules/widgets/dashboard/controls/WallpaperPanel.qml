pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.modules.globals
import qs.config

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    property string currentSection: ""

    component SectionButton: StyledRect {
        id: sectionBtn
        required property string text
        required property string sectionId
        required property string description

        property bool isHovered: false
        variant: isHovered ? "focus" : "pane"
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: Styling.radius(0)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: sectionBtn.text
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(0)
                    font.bold: true
                    color: Colors.overBackground
                }

                Text {
                    text: sectionBtn.description
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    color: Colors.overSurfaceVariant
                    opacity: 0.8
                }
            }

            Text {
                text: Icons.caretRight
                font.family: Icons.font
                font.pixelSize: 20
                color: Colors.overSurfaceVariant
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: sectionBtn.isHovered = true
            onExited: sectionBtn.isHovered = false
            onClicked: root.currentSection = sectionBtn.sectionId
        }
    }

    component ToggleRow: RowLayout {
        id: toggleRow
        required property string label
        required property bool checked
        required property var toggleCallback
        property string description: ""
        Layout.fillWidth: true
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: toggleRow.label
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                color: Colors.overBackground
            }

            Text {
                visible: toggleRow.description !== ""
                text: toggleRow.description
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.overSurfaceVariant
                opacity: 0.75
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        StyledRect {
            width: 40
            height: 24
            radius: Styling.radius(-1)
            variant: toggleRow.checked ? "primary" : "common"

            Text {
                anchors.centerIn: parent
                text: toggleRow.checked ? Icons.accept : Icons.cancel
                font.family: Icons.font
                font.pixelSize: 12
                color: toggleRow.checked ? Styling.srItem("primary") : Colors.overSurfaceVariant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: toggleRow.toggleCallback()
            }
        }
    }

    component ModeButton: StyledRect {
        id: modeBtn
        required property string label
        required property bool active
        required property var onClicked

        variant: active ? "primary" : "common"
        Layout.preferredHeight: 32
        Layout.fillWidth: true
        radius: Styling.radius(-2)

        Text {
            anchors.centerIn: parent
            text: modeBtn.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-1)
            font.weight: modeBtn.active ? Font.Bold : Font.Normal
            color: modeBtn.active ? Styling.srItem("primary") : Colors.overSurfaceVariant
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: modeBtn.onClicked()
        }
    }

    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainColumn
            width: mainFlickable.width
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: titlebar.height

                PanelTitlebar {
                    id: titlebar
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    title: {
                        if (root.currentSection === "preset") return "Preset Wallpaper";
                        if (root.currentSection === "rotation") return "Rotation";
                        return "Wallpaper";
                    }
                    statusText: ""
                    actions: root.currentSection !== "" ? [
                        { icon: Icons.arrowLeft, tooltip: "Back", onClicked: function() { root.currentSection = ""; } }
                    ] : []
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: contentColumn.implicitHeight

                ColumnLayout {
                    id: contentColumn
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    // ─── Main menu ────────────────────────────────────────
                    ColumnLayout {
                        visible: root.currentSection === ""
                        Layout.fillWidth: true
                        spacing: 12

                        ToggleRow {
                            label: "Export as ~/bg.png"
                            description: "Copy the current wallpaper to ~/bg.png every time it changes (uses ImageMagick/ffmpeg)"
                            checked: Config.wallpaper.exportBg
                            toggleCallback: function() { Config.wallpaper.exportBg = !Config.wallpaper.exportBg; }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Colors.surfaceBright
                            opacity: 0.5
                        }

                        SectionButton {
                            text: "Preset Wallpaper"
                            sectionId: "preset"
                            description: "Apply a specific wallpaper when this preset is loaded"
                        }
                        SectionButton {
                            text: "Rotation"
                            sectionId: "rotation"
                            description: "Automatically cycle wallpapers from a folder"
                        }
                    }

                    // ─── Preset Wallpaper ─────────────────────────────────
                    ColumnLayout {
                        visible: root.currentSection === "preset"
                        Layout.fillWidth: true
                        spacing: 16

                        ToggleRow {
                            label: "Enable preset wallpaper"
                            description: "When this preset loads, the wallpaper below is applied (ignored if rotation is on)"
                            checked: Config.wallpaper.enabled
                            toggleCallback: function() { Config.wallpaper.enabled = !Config.wallpaper.enabled; }
                        }

                        ColumnLayout {
                            visible: Config.wallpaper.enabled
                            Layout.fillWidth: true
                            spacing: 8

                            StyledRect {
                                variant: "internalbg"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 120
                                radius: Styling.radius(0)
                                clip: true

                                Image {
                                    id: wallpaperPreview
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    source: {
                                        var wp = Config.wallpaper.wallpaper;
                                        if (!wp || !GlobalStates.wallpaperManager) return "";
                                        return "file://" + GlobalStates.wallpaperManager.getThumbnailPath(wp);
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: wallpaperPreview.status !== Image.Ready
                                    text: Icons.image
                                    font.family: Icons.font
                                    font.pixelSize: 32
                                    color: Colors.overSurfaceVariant
                                    opacity: 0.4
                                }
                            }

                            StyledRect {
                                variant: "common"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: Styling.radius(-2)

                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    verticalAlignment: Text.AlignVCenter
                                    text: Config.wallpaper.wallpaper || "No wallpaper saved"
                                    font.family: Config.theme.monoFont
                                    font.pixelSize: Styling.fontSize(-2)
                                    color: Config.wallpaper.wallpaper ? Colors.overBackground : Colors.overSurfaceVariant
                                    elide: Text.ElideLeft
                                    opacity: Config.wallpaper.wallpaper ? 1.0 : 0.5
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                StyledRect {
                                    id: useCurrentBtn
                                    variant: useCurrentArea.containsMouse ? "primaryfocus" : "primary"
                                    Layout.preferredHeight: 34
                                    Layout.fillWidth: true
                                    radius: Styling.radius(-2)

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: Icons.image
                                            font.family: Icons.font
                                            font.pixelSize: 13
                                            color: useCurrentBtn.item
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: "Save current"
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            color: useCurrentBtn.item
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: useCurrentArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (GlobalStates.wallpaperManager)
                                                Config.wallpaper.wallpaper = GlobalStates.wallpaperManager.currentWallpaper;
                                        }
                                    }
                                }

                                StyledRect {
                                    id: clearBtn
                                    visible: Config.wallpaper.wallpaper !== ""
                                    variant: clearArea.containsMouse ? "error" : "common"
                                    Layout.preferredHeight: 34
                                    Layout.preferredWidth: 34
                                    radius: Styling.radius(-2)

                                    Text {
                                        anchors.centerIn: parent
                                        text: Icons.cancel
                                        font.family: Icons.font
                                        font.pixelSize: 13
                                        color: clearArea.containsMouse ? clearBtn.item : Colors.overSurfaceVariant
                                    }

                                    MouseArea {
                                        id: clearArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.wallpaper.wallpaper = ""
                                    }

                                    StyledToolTip { visible: clearArea.containsMouse; tooltipText: "Clear" }
                                }
                            }
                        }
                    }

                    // ─── Rotation ─────────────────────────────────────────
                    ColumnLayout {
                        visible: root.currentSection === "rotation"
                        Layout.fillWidth: true
                        spacing: 16

                        ToggleRow {
                            label: "Enable rotation"
                            description: "Automatically cycle through wallpapers. Overrides preset wallpaper when active."
                            checked: Config.wallpaper.rotationEnabled
                            toggleCallback: function() { Config.wallpaper.rotationEnabled = !Config.wallpaper.rotationEnabled; }
                        }

                        ColumnLayout {
                            visible: Config.wallpaper.rotationEnabled
                            Layout.fillWidth: true
                            spacing: 16

                            // Mode
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: "Pick mode"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-1)
                                    font.weight: Font.Medium
                                    color: Colors.overSurfaceVariant
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    ModeButton {
                                        label: "Random"
                                        active: Config.wallpaper.rotationMode === "random"
                                        onClicked: function() { Config.wallpaper.rotationMode = "random"; }
                                    }

                                    ModeButton {
                                        label: "Sequential"
                                        active: Config.wallpaper.rotationMode === "sequential"
                                        onClicked: function() { Config.wallpaper.rotationMode = "sequential"; }
                                    }
                                }
                            }

                            // Triggers
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "Triggers"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-1)
                                    font.weight: Font.Medium
                                    color: Colors.overSurfaceVariant
                                }

                                ToggleRow {
                                    label: "On startup"
                                    description: "Rotate once when Ambxst starts"
                                    checked: Config.wallpaper.rotationOnStartup
                                    toggleCallback: function() { Config.wallpaper.rotationOnStartup = !Config.wallpaper.rotationOnStartup; }
                                }

                                // Interval
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    ToggleRow {
                                        label: "Every X seconds"
                                        description: "Rotate on a recurring timer"
                                        checked: Config.wallpaper.rotationInterval > 0
                                        toggleCallback: function() {
                                            Config.wallpaper.rotationInterval = Config.wallpaper.rotationInterval > 0 ? 0 : 300;
                                        }
                                    }

                                    RowLayout {
                                        visible: Config.wallpaper.rotationInterval > 0
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: "Interval"
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(-1)
                                            color: Colors.overSurfaceVariant
                                        }

                                        StyledRect {
                                            variant: "common"
                                            Layout.preferredWidth: 72
                                            Layout.preferredHeight: 28
                                            radius: Styling.radius(-2)

                                            TextInput {
                                                id: intervalInput
                                                anchors.fill: parent
                                                anchors.margins: 6
                                                font.family: Config.theme.font
                                                font.pixelSize: Styling.fontSize(0)
                                                color: Colors.overBackground
                                                selectByMouse: true
                                                clip: true
                                                verticalAlignment: TextInput.AlignVCenter
                                                horizontalAlignment: TextInput.AlignHCenter
                                                validator: IntValidator { bottom: 10; top: 86400 }
                                                text: Config.wallpaper.rotationInterval.toString()
                                                onEditingFinished: {
                                                    var v = parseInt(text);
                                                    if (!isNaN(v) && v >= 10) Config.wallpaper.rotationInterval = v;
                                                }
                                            }
                                        }

                                        Text {
                                            text: "seconds"
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(-1)
                                            color: Colors.overSurfaceVariant
                                        }
                                    }
                                }
                            }

                            // Source folder
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: "Source"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-1)
                                    font.weight: Font.Medium
                                    color: Colors.overSurfaceVariant
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    ModeButton {
                                        label: "Wallpaper dir"
                                        active: Config.wallpaper.rotationFolder === ""
                                        onClicked: function() { Config.wallpaper.rotationFolder = ""; }
                                    }

                                    ModeButton {
                                        label: "Custom folder"
                                        active: Config.wallpaper.rotationFolder !== ""
                                        onClicked: function() {
                                            if (Config.wallpaper.rotationFolder === "" && GlobalStates.wallpaperManager)
                                                Config.wallpaper.rotationFolder = GlobalStates.wallpaperManager.wallpaperDir || "";
                                        }
                                    }
                                }

                                ColumnLayout {
                                    visible: Config.wallpaper.rotationFolder !== ""
                                    Layout.fillWidth: true
                                    spacing: 4

                                    StyledRect {
                                        variant: "common"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        radius: Styling.radius(-2)

                                        TextInput {
                                            id: folderInput
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            font.family: Config.theme.monoFont
                                            font.pixelSize: Styling.fontSize(-1)
                                            color: Colors.overBackground
                                            selectByMouse: true
                                            clip: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            text: Config.wallpaper.rotationFolder

                                            Text {
                                                anchors.fill: parent
                                                verticalAlignment: Text.AlignVCenter
                                                text: "/path/to/folder"
                                                font: folderInput.font
                                                color: Colors.overSurfaceVariant
                                                opacity: 0.5
                                                visible: folderInput.text === ""
                                            }

                                            onEditingFinished: Config.wallpaper.rotationFolder = text
                                        }
                                    }

                                    Text {
                                        text: "Absolute path to a folder containing wallpapers"
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-3)
                                        color: Colors.overSurfaceVariant
                                        opacity: 0.6
                                    }
                                }
                            }
                        }
                    }

                    Item { height: 8 }
                }
            }
        }
    }
}
