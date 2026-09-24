import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Setup: your saved setups (the bar as you made it, kept under a name), and every desktop shell installed on this
// machine with the one that is running.
//
// Ito-verse is one shell among whatever else the person has (Omarchy's own, Shibumi, Caelestia, Waybar…).
// bin/ito-shells finds them from three kinds of evidence — the user's own switcher, the Omarchy variant
// files, and known shells on PATH — and switching goes back through their switcher when they have one, so
// keybindings and GTK authority move with it.
ColumnLayout {
  id: page

  property var cc: null
  readonly property var pal: cc.pal
  readonly property color bone: pal.bone

  property var shells: []
  property bool hasSwitcher: false
  property string pending: ""

  spacing: 10

  readonly property string profileTool: Qt.resolvedUrl("../bin/ito-profile").toString().replace("file://", "")
  property var setups: []
  property string setupMessage: ""

  Process {
    id: setupList
    command: [page.profileTool, "list"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: { try { page.setups = JSON.parse(this.text) } catch (e) { page.setups = [] } }
    }
  }
  Process {
    id: setupSave
    property string name: ""
    command: [page.profileTool, "save", name]
    onExited: function(code) {
      page.setupMessage = code === 0 ? "Saved “" + name + "”." : "It could not be saved."
      setupList.running = true
    }
  }
  Process {
    id: setupLoad
    property string name: ""
    command: [page.profileTool, "load", name]
  }
  Process {
    id: setupDelete
    property string name: ""
    command: [page.profileTool, "delete", name]
    onExited: setupList.running = true
  }

  Process {
    id: scan
    command: [Qt.resolvedUrl("../bin/ito-shells").toString().replace("file://", "")]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(this.text)
          page.shells = parsed.shells || []
          page.hasSwitcher = parsed.switcher === true
        } catch (e) {
          page.shells = []
        }
      }
    }
  }

  Process { id: switcher }

  function switchTo(id) {
    page.pending = id
    switcher.command = [Qt.resolvedUrl("../bin/ito-shells").toString().replace("file://", ""), "--switch", id]
    switcher.running = true
    page.cc.close()
  }

  CcSection {
    host: page.cc
    startOpen: true
    pal: page.pal
    label: "MY SETUPS"
    note: "Everything you change is remembered by itself. Save a copy under a name to come back to it later: your colours, effects, widgets and where they sit, and your own pictures."

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        radius: 17
        color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.05)
        border.width: 1
        border.color: nameInput.activeFocus ? page.pal.blood : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.2)

        TextInput {
          id: nameInput
          anchors.fill: parent
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          verticalAlignment: TextInput.AlignVCenter
          color: page.bone
          font.family: "Noto Serif"
          font.pixelSize: 12
          maximumLength: 40
          clip: true
          selectByMouse: true
          Text {
            visible: nameInput.text === "" && !nameInput.activeFocus
            anchors.verticalCenter: parent.verticalCenter
            text: "Name this setup, for example “Evening”"
            color: page.bone
            opacity: 0.4
            font.family: "Noto Serif"
            font.pixelSize: 12
          }
          onAccepted: saveButton.activated()
        }
      }

      CcCard {
        id: saveButton
        Layout.preferredWidth: 140
        Layout.preferredHeight: 34
        radius: 17
        host: page.cc
        pal: page.pal
        showCaption: false
        current: true
        hint: "Save the bar as it is now under this name."
        onActivated: {
          var n = nameInput.text.trim()
          if (n === "") { page.setupMessage = "Type a name first."; return }
          if (!setupSave.running) { setupSave.name = n; setupSave.running = true; nameInput.text = "" }
        }
        Text { anchors.centerIn: parent; text: "Save setup"; color: page.pal.lit; font.family: "Noto Serif"; font.pixelSize: 12 }
      }
    }

    Text {
      visible: page.setupMessage !== ""
      text: page.setupMessage
      color: page.bone
      opacity: 0.7
      font.family: "Noto Serif"
      font.pixelSize: 11
    }

    Text {
      visible: page.setups.length === 0
      text: "Nothing saved yet."
      color: page.bone
      opacity: 0.45
      font.family: "Noto Serif"
      font.pixelSize: 11
    }

    Repeater {
      model: page.setups

      Rectangle {
        required property var modelData
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: 12
        color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.035)
        border.width: 1
        border.color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.12)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 10
          spacing: 10

          Column {
            Layout.fillWidth: true
            spacing: 1
            Text { text: modelData.name; color: page.bone; font.family: "Noto Serif"; font.pixelSize: 13 }
            Text { text: "Saved " + modelData.saved; color: page.bone; opacity: 0.45; font.family: "Noto Serif"; font.pixelSize: 10 }
          }

          CcCard {
            Layout.preferredWidth: 78
            Layout.preferredHeight: 30
            radius: 15
            host: page.cc
            pal: page.pal
            showCaption: false
            hint: "Put the bar back the way this setup was. It restarts for a few seconds."
            onActivated: if (!setupLoad.running) { setupLoad.name = modelData.name; setupLoad.running = true; page.cc.close() }
            Text { anchors.centerIn: parent; text: "Load"; color: page.pal.lit; font.family: "Noto Serif"; font.pixelSize: 11 }
          }
          CcCard {
            Layout.preferredWidth: 78
            Layout.preferredHeight: 30
            radius: 15
            host: page.cc
            pal: page.pal
            showCaption: false
            hint: "Delete this saved setup. The bar itself does not change."
            onActivated: if (!setupDelete.running) { setupDelete.name = modelData.name; setupDelete.running = true }
            Text { anchors.centerIn: parent; text: "Delete"; color: page.bone; font.family: "Noto Serif"; font.pixelSize: 11 }
          }
        }
      }
    }
  }

  CcSection {
    host: page.cc
    startOpen: true
    pal: page.pal
    label: "SHELLS"
    note: page.hasSwitcher
      ? "Switching goes through your own shell-switch, so keybindings and GTK follow along."
      : "Switching starts the other shell and stops this one."


    Repeater {
      model: page.shells

      Rectangle {
        id: row
        required property var modelData
        readonly property bool active: modelData.active

        Layout.fillWidth: true
        Layout.preferredHeight: 62
        radius: 12
        color: hover.hovered ? Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.08)
          : (active ? Qt.rgba(page.pal.blood.r, page.pal.blood.g, page.pal.blood.b, 0.12)
                    : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.03))
        border.width: 1
        border.color: active ? Qt.rgba(page.pal.blood.r, page.pal.blood.g, page.pal.blood.b, 0.7)
          : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.12)
        visible: page.cc.match(modelData.name + " " + modelData.id + " shell")
        Behavior on color { ColorAnimation { duration: 130 } }

        // Fixed places, so every row lines up: the mark at the left, the names after it, and the button (or RUNNING)
        // in a column of its own at the right edge. Left to a RowLayout, the button drifted with the width of the text.
        Item {
          anchors.fill: parent

          Rectangle {
            id: mark
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            rotation: 45
            radius: 2
            color: row.active ? page.pal.blood : "transparent"
            border.width: 1.2
            border.color: row.active ? page.pal.blood : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.45)
          }

          Column {
            anchors.left: mark.right
            anchors.leftMargin: 18
            anchors.right: action.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Row {
              spacing: 8
              Text {
                text: row.modelData.name
                color: row.modelData.ours ? page.pal.lit : page.bone
                font.family: "Noto Serif"
                font.pixelSize: 14
              }
              Text {
                visible: row.modelData.ours
                topPadding: 4
                text: "this one"
                color: page.pal.blood
                opacity: 0.8
                font.family: "Noto Serif"
                font.pixelSize: 10
                font.letterSpacing: 1
              }
            }

            Text {
              width: parent.width
              elide: Text.ElideRight
              text: row.modelData.barId !== "" ? row.modelData.barId
                : (row.modelData.variant ? "Omarchy variant" : "installed")
              color: page.bone
              opacity: 0.45
              font.family: "Noto Serif"
              font.pixelSize: 10
            }
          }

          Item {
            id: action
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 104
            height: 32

            Text {
              visible: row.active
              anchors.centerIn: parent
              text: "RUNNING"
              color: page.pal.blood
              font.family: "Noto Serif"
              font.pixelSize: 10
              font.letterSpacing: 2
            }

            Rectangle {
              visible: !row.active
              anchors.fill: parent
              radius: 16
              color: go.hovered ? Qt.rgba(page.pal.blood.r, page.pal.blood.g, page.pal.blood.b, 0.32) : "transparent"
              border.width: 1
              border.color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.25)
              Behavior on color { ColorAnimation { duration: 120 } }

              Text {
                anchors.centerIn: parent
                text: page.pending === row.modelData.id ? "starting…" : "Switch"
                color: page.bone
                font.family: "Noto Serif"
                font.pixelSize: 12
              }

              HoverHandler {
                id: go
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: page.cc.hint = hovered
                  ? "Stop this shell and start " + row.modelData.name + "." : ""
              }
              TapHandler { onTapped: page.switchTo(row.modelData.id) }
            }
          }
        }

        HoverHandler {
          id: hover
          onHoveredChanged: page.cc.hint = hovered && row.active
            ? row.modelData.name + " is the shell you are looking at." : page.cc.hint
        }
      }
    }


    CcCard {
      Layout.preferredWidth: 130
      Layout.preferredHeight: 34
      Layout.topMargin: 4
      radius: 17
      host: page.cc
      pal: page.pal
      showCaption: false
      hint: "Look for installed shells again."
      onActivated: scan.running = true

      Text {
        anchors.centerIn: parent
        text: "Rescan"
        color: page.bone
        font.family: "Noto Serif"
        font.pixelSize: 12
      }
    }
  }


  CcSection {
    host: page.cc
    pal: page.pal
    label: "ABOUT"
    note: "Ito-verse, made by davidxap. The bar engine is a fork of Shibumi-Shell by HANCORE (MIT); five widgets are Omarchy's own, re-skinned. Free for non-commercial use: see LICENSE and NOTICE in the repository."

    Text {
      text: "github.com/Davidxap/ito-verse-shell"
      color: page.pal.lit
      font.family: "Noto Serif"
      font.pixelSize: 12
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/Davidxap/ito-verse-shell"])
      }
    }
  }
}
