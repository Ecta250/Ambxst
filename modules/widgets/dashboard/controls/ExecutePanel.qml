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
    readonly property real sideMargin: (width - contentWidth) / 2
    property string currentSection: ""

    component MiniToggle: RowLayout {
        id: toggle
        required property string label
        required property bool checked
        required property var toggleCallback
        spacing: 6

        Text {
            text: toggle.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-1)
            color: Colors.overSurfaceVariant
        }

        Item {
            width: 22; height: 22

            Rectangle {
                anchors.fill: parent
                radius: Styling.radius(-4)
                color: Colors.background
                visible: !toggle.checked
            }

            StyledRect {
                variant: "primary"
                anchors.fill: parent
                radius: Styling.radius(-4)
                visible: toggle.checked

                Text {
                    anchors.centerIn: parent
                    text: Icons.accept
                    color: Styling.srItem("primary")
                    font.family: Icons.font
                    font.pixelSize: 12
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: toggle.toggleCallback()
            }
        }
    }

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

    component EntryCard: StyledRect {
        id: entryCard
        required property var entry
        required property int entryIndex
        required property string entryType

        variant: "pane"
        Layout.fillWidth: true
        Layout.preferredHeight: cardContent.implicitHeight + 24
        radius: Styling.radius(0)

        function updateEntry(field, value) {
            let key = entryCard.entryType === "hyprland" ? "hyprland"
                    : entryCard.entryType === "snippets" ? "snippets" : "autostart";
            let list = (Config.execute[key] || []).slice();
            list[entryCard.entryIndex] = Object.assign({}, list[entryCard.entryIndex], { [field]: value });
            Config.execute[key] = list;
        }

        function removeEntry() {
            let key = entryCard.entryType === "hyprland" ? "hyprland"
                    : entryCard.entryType === "snippets" ? "snippets" : "autostart";
            let list = (Config.execute[key] || []).slice();
            list.splice(entryCard.entryIndex, 1);
            Config.execute[key] = list;
        }

        ColumnLayout {
            id: cardContent
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: Icons.circle
                    font.family: Icons.font
                    font.pixelSize: 8
                    color: Styling.srItem("overprimary")
                }

                StyledRect {
                    variant: "common"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Styling.radius(-2)

                    TextInput {
                        id: nameInput
                        anchors.fill: parent
                        anchors.margins: 8
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(0)
                        font.bold: true
                        color: Colors.overBackground
                        selectByMouse: true
                        clip: true
                        verticalAlignment: TextInput.AlignVCenter
                        text: entryCard.entry.name || ""

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Name"
                            font: nameInput.font
                            color: Colors.overSurfaceVariant
                            visible: nameInput.text === ""
                        }

                        onEditingFinished: entryCard.updateEntry("name", text)
                    }
                }

                StyledRect {
                    id: deleteBtn
                    variant: deleteArea.containsMouse ? "error" : "common"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: Styling.radius(-2)

                    Text {
                        anchors.centerIn: parent
                        text: Icons.trash
                        font.family: Icons.font
                        font.pixelSize: 13
                        color: deleteArea.containsMouse ? deleteBtn.item : Colors.error
                    }

                    MouseArea {
                        id: deleteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: entryCard.removeEntry()
                    }

                    StyledToolTip { visible: deleteArea.containsMouse; tooltipText: "Remove" }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: entryCard.entryType === "hyprland" ? "dispatch" : "bash -c"
                    font.family: Config.theme.monoFont
                    font.pixelSize: Styling.monoFontSize(-1)
                    color: Styling.srItem("overprimary")
                    opacity: 0.7
                    Layout.preferredWidth: 68
                    horizontalAlignment: Text.AlignRight
                }

                StyledRect {
                    variant: "common"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Styling.radius(-2)

                    TextInput {
                        id: cmdInput
                        anchors.fill: parent
                        anchors.margins: 8
                        font.family: Config.theme.monoFont
                        font.pixelSize: Styling.monoFontSize(0)
                        color: Colors.overBackground
                        selectByMouse: true
                        clip: true
                        verticalAlignment: TextInput.AlignVCenter
                        text: entryCard.entry.command || ""

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: entryCard.entryType === "hyprland" ? "e.g. exec discord" : "e.g. discord --start-minimized"
                            font: cmdInput.font
                            color: Colors.overSurfaceVariant
                            visible: cmdInput.text === ""
                        }

                        onEditingFinished: entryCard.updateEntry("command", text)
                    }
                }

                StyledRect {
                    id: runBtn
                    variant: runArea.containsMouse ? "primaryfocus" : "common"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: Styling.radius(-2)

                    Text {
                        anchors.centerIn: parent
                        text: Icons.play
                        font.family: Icons.font
                        font.pixelSize: 13
                        color: runArea.containsMouse ? runBtn.item : Styling.srItem("overprimary")
                    }

                    MouseArea {
                        id: runArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let cmd = entryCard.entry.command || "";
                            if (cmd) ExecuteService.runNow(cmd, entryCard.entryType === "hyprland" ? "hyprland" : "bash");
                        }
                    }

                    StyledToolTip { visible: runArea.containsMouse; tooltipText: "Run now" }
                }
            }

            // Autostart options: enabled, once, execOnPreset, delay
            RowLayout {
                visible: entryCard.entryType === "autostart"
                Layout.fillWidth: true
                spacing: 12

                MiniToggle {
                    label: "Enabled"
                    checked: entryCard.entry.enabled !== false
                    toggleCallback: () => entryCard.updateEntry("enabled", !(entryCard.entry.enabled !== false))
                }

                Rectangle { width: 1; height: 16; color: Colors.surfaceBright }

                MiniToggle {
                    label: "Run once"
                    checked: entryCard.entry.once !== false
                    toggleCallback: () => entryCard.updateEntry("once", entryCard.entry.once === false)
                }

                Rectangle { width: 1; height: 16; color: Colors.surfaceBright }

                MiniToggle {
                    label: "Exec on preset"
                    checked: !!entryCard.entry.execOnPreset
                    toggleCallback: () => entryCard.updateEntry("execOnPreset", !entryCard.entry.execOnPreset)
                }

                Rectangle { width: 1; height: 16; color: Colors.surfaceBright }

                RowLayout {
                    spacing: 6

                    Text {
                        text: "Delay"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: Colors.overSurfaceVariant
                    }

                    StyledRect {
                        variant: "common"
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 24
                        radius: Styling.radius(-2)

                        TextInput {
                            id: delayInput
                            anchors.fill: parent
                            anchors.margins: 4
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: Colors.overBackground
                            selectByMouse: true
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            validator: IntValidator { bottom: 0; top: 3600 }
                            text: (entryCard.entry.delay || 0).toString()
                            onEditingFinished: entryCard.updateEntry("delay", parseInt(text) || 0)
                        }
                    }

                    Text {
                        text: "s"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: Colors.overSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Hyprland options: enabled, delay
            RowLayout {
                visible: entryCard.entryType === "hyprland"
                Layout.fillWidth: true
                spacing: 12

                MiniToggle {
                    label: "Enabled"
                    checked: entryCard.entry.enabled !== false
                    toggleCallback: () => entryCard.updateEntry("enabled", !(entryCard.entry.enabled !== false))
                }

                Rectangle { width: 1; height: 16; color: Colors.surfaceBright }

                RowLayout {
                    spacing: 6

                    Text {
                        text: "Delay"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: Colors.overSurfaceVariant
                    }

                    StyledRect {
                        variant: "common"
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 24
                        radius: Styling.radius(-2)

                        TextInput {
                            id: hyprDelayInput
                            anchors.fill: parent
                            anchors.margins: 4
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: Colors.overBackground
                            selectByMouse: true
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            validator: IntValidator { bottom: 0; top: 3600 }
                            text: (entryCard.entry.delay || 0).toString()
                            onEditingFinished: entryCard.updateEntry("delay", parseInt(text) || 0)
                        }
                    }

                    Text {
                        text: "s"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: Colors.overSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }
            }
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
                        if (root.currentSection === "autostart") return "Autostart";
                        if (root.currentSection === "hyprland") return "Hyprland";
                        if (root.currentSection === "snippets") return "Snippets";
                        return "Execute";
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

                    ColumnLayout {
                        visible: root.currentSection === ""
                        Layout.fillWidth: true
                        spacing: 8

                        SectionButton { text: "Autostart"; sectionId: "autostart"; description: "Bash commands that run automatically at shell startup" }
                        SectionButton { text: "Hyprland"; sectionId: "hyprland"; description: "Hyprland dispatcher commands run at startup" }
                        SectionButton { text: "Snippets"; sectionId: "snippets"; description: "Named bash commands you can trigger on demand" }
                    }

                    ColumnLayout {
                        visible: root.currentSection === "autostart"
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Autostart"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        Text {
                            text: "These commands run when the shell starts. Use \"Run once\" to prevent restarts."
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: Colors.overSurfaceVariant
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: Config.execute.autostart || []
                            delegate: EntryCard {
                                required property var modelData
                                required property int index
                                entry: modelData
                                entryIndex: index
                                entryType: "autostart"
                                Layout.fillWidth: true
                            }
                        }

                        StyledRect {
                            id: addAutostartBtn
                            variant: addAutostartArea.containsMouse ? "primaryfocus" : "primary"
                            Layout.preferredHeight: 36
                            Layout.preferredWidth: addAutostartRow.implicitWidth + 24
                            radius: Styling.radius(-2)

                            Row {
                                id: addAutostartRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: Icons.plus
                                    font.family: Icons.font
                                    font.pixelSize: 14
                                    color: addAutostartBtn.item
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Add Command"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: addAutostartBtn.item
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: addAutostartArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let list = (Config.execute.autostart || []).slice();
                                    list.push({ name: "", command: "", enabled: true, once: true, delay: 0 });
                                    Config.execute.autostart = list;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: root.currentSection === "hyprland"
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Hyprland"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        Text {
                            text: "Dispatched via \"hyprctl dispatch exec\" at startup. Use for apps that need Hyprland's environment."
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: Colors.overSurfaceVariant
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: Config.execute.hyprland || []
                            delegate: EntryCard {
                                required property var modelData
                                required property int index
                                entry: modelData
                                entryIndex: index
                                entryType: "hyprland"
                                Layout.fillWidth: true
                            }
                        }

                        StyledRect {
                            id: addHyprBtn
                            variant: addHyprArea.containsMouse ? "primaryfocus" : "primary"
                            Layout.preferredHeight: 36
                            Layout.preferredWidth: addHyprRow.implicitWidth + 24
                            radius: Styling.radius(-2)

                            Row {
                                id: addHyprRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: Icons.plus
                                    font.family: Icons.font
                                    font.pixelSize: 14
                                    color: addHyprBtn.item
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Add Command"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: addHyprBtn.item
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: addHyprArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let list = (Config.execute.hyprland || []).slice();
                                    list.push({ name: "", command: "", enabled: true, delay: 0 });
                                    Config.execute.hyprland = list;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: root.currentSection === "snippets"
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Snippets"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        Text {
                            text: "Named commands you can fire on demand. Hit the play button to run one now."
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: Colors.overSurfaceVariant
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: Config.execute.snippets || []
                            delegate: EntryCard {
                                required property var modelData
                                required property int index
                                entry: modelData
                                entryIndex: index
                                entryType: "snippets"
                                Layout.fillWidth: true
                            }
                        }

                        StyledRect {
                            id: addSnippetBtn
                            variant: addSnippetArea.containsMouse ? "primaryfocus" : "primary"
                            Layout.preferredHeight: 36
                            Layout.preferredWidth: addSnippetRow.implicitWidth + 24
                            radius: Styling.radius(-2)

                            Row {
                                id: addSnippetRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: Icons.plus
                                    font.family: Icons.font
                                    font.pixelSize: 14
                                    color: addSnippetBtn.item
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Add Snippet"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: addSnippetBtn.item
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: addSnippetArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let list = (Config.execute.snippets || []).slice();
                                    list.push({ name: "", command: "" });
                                    Config.execute.snippets = list;
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; Layout.preferredHeight: 16 }
                }
            }
        }
    }
}
