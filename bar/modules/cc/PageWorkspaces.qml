import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." as Ito

// Workspaces: how the workspaces are drawn and how many are always shown.
ColumnLayout {
  id: page

  property var cc: null
  readonly property var pal: cc.pal
  readonly property var act: cc.actions
  readonly property color bone: pal.bone
  readonly property url art: Qt.resolvedUrl("../ito-art/")

  spacing: 10

  readonly property string marksTool: Qt.resolvedUrl("../bin/ito-marks").toString().replace("file://", "")
  readonly property string home: Quickshell.env("HOME")

  // One file dialog for whichever state was asked for; once a picture is in, the style switches to Custom and
  // the bar is told to reload it (the stamp is part of the picture's address).
  // Does the Custom style have a picture yet? Choosing it with none would leave the bar empty, so it asks for one instead.
  // A picker prints {"error": "..."} when it refuses a file (too heavy, not a picture); an empty answer means the dialog
  // was cancelled. Returns true only when a picture really was taken.
  property string pickError: ""
  function pickOk(reply) {
    var t = String(reply).trim()
    if (t === "") return false
    try {
      var r = JSON.parse(t)
      if (r.error) { page.pickError = r.error; return false }
    } catch (e) {}
    page.pickError = ""
    return true
  }

  // Which of the four pictures exist. Asking the disk (not loading a file that may not be there) keeps the log clean.
  property var wsHas: ({})
  Process {
    id: wsProbe
    command: ["sh", "-c", "for s in empty occupied active urgent; do [ -f \"$HOME/.cache/ito/marks/_ws-$s.png\" ] && echo $s; done; true"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var has = {}
        var names = String(text).split("\n")
        for (var k = 0; k < names.length; k++) if (names[k] !== "") has[names[k]] = true
        page.wsHas = has
      }
    }
  }
  readonly property int wsVersion: Number(pal.get("wsCustomVer", 0))
  onWsVersionChanged: probeSoon.restart()
  Timer { id: probeSoon; interval: 900; onTriggered: if (!wsProbe.running) wsProbe.running = true }

  Process {
    id: wsReset
    command: [page.marksTool, "reset-ws"]
    onExited: { page.act.set("wsCustomVer", Math.floor(Date.now() / 1000)); page.act.set("style", "orbs") }
  }

  Process {
    id: wsPicker
    property string state: "active"
    command: [page.marksTool, "pick", "--as", "_ws-" + state]
    stdout: StdioCollector {
      onStreamFinished: if (page.pickOk(text)) {
        page.act.set("wsCustomVer", Math.floor(Date.now() / 1000))
        page.act.set("style", "custom")
      }
    }
  }

  readonly property var styles: [
    { "key": "numerals", "art": "workspace-labels/ws-1-red.png",             "name": "Seals",
      "note": "Numbered rings: every workspace shows its digit, and the one you are on bleeds." },
    { "key": "orbs",     "art": "workspaces/workspace-2.png",                "name": "Rings",
      "note": "Concentric rings, no numbers. The red ring is where you are." },
    { "key": "eyes",     "art": "status-eyes/eye-red.png",                   "name": "Tomie",
      "note": "Eyes and lips alternate along the bar; the bloodshot eye is the active one." },
    { "key": "remina",   "art": "workspaces/ws-remina-3-active.png",            "name": "Remina",
      "note": "The planet with one eye: shut when empty, open when there is something, bloodshot on the one you are on. One tendril more for each workspace." },
    { "key": "uzumaki",  "art": "workspaces/ws-uzumaki-3-active.png",          "name": "Uzumaki",
      "note": "A spiral with one arm more for every workspace: you tell them apart by their arms. Blood on the one you are on." },
    { "key": "dots",     "art": "workspace-indicators/indicator-urgent.png", "name": "Marks",
      "note": "Blood marks: hollow when empty, inked when occupied, a bleeding target when active." },
    { "key": "halo",     "art": "workspaces/ws-halo-3-active.png",     "name": "Halo",
      "note": "Silent Hill 3's own save-point seal: as many spikes as the workspace number, lit blood on the one you are on." },
    { "key": "flauros",  "art": "workspaces/ws-flauros-3-active.png", "name": "Flauros",
      "note": "The puzzle's own seal: the coil winds one turn tighter per workspace, lit blood on the one you are on." },
    { "key": "custom",   "art": "",                                       "name": "Custom",
      "note": "Your own pictures, one for each state. Choose them under YOUR OWN below." }
  ]

  CcSection {
    host: page.cc
    startOpen: true
    pal: page.pal
    label: "STYLE"
    note: {
      for (var i = 0; i < page.styles.length; i++)
        if (page.styles[i].key === String(page.pal.get("style", "orbs"))) return page.styles[i].note
      return ""
    }


    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: page.styles

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 108
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: String(page.pal.get("style", "orbs")) === modelData.key
          visible: page.cc.match(modelData.name + " " + modelData.note + " workspace style")
          onActivated: {
            if (modelData.key === "custom" && !page.wsHas.active) {
              if (!wsPicker.running) { wsPicker.state = "active"; wsPicker.running = true }
            } else page.act.set("style", modelData.key)
          }

          Ito.ItoImage {
            palette: page.pal
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            width: 56
            height: 56
            source: modelData.art === "" ? "" : page.art + modelData.art
            opacity: parent.current ? 1 : 0.65
          }
          Text {
            visible: modelData.art === ""
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            text: "+"
            color: page.bone
            opacity: parent.current ? 1 : 0.65
            font.pixelSize: 30
          }
        }
      }
    }
  }


  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "YOUR OWN PICTURES"
    note: "Draw the workspaces your way. It takes three steps."


    Column {
      Layout.fillWidth: true
      spacing: 4
      Repeater {
        model: [
          "1.  Click a box below and choose a picture from your files (PNG, JPG, WebP or SVG; square, 256 × 256 px is the right size).",
          "2.  It is used on the bar straight away: the row under the boxes shows how it looks.",
          "3.  Change your mind? Click the box again to swap it, or press Remove my pictures."
        ]
        Text {
          required property string modelData
          width: parent.width
          wrapMode: Text.WordWrap
          text: modelData
          color: page.bone
          opacity: 0.8
          font.family: "Noto Serif"
          font.pixelSize: 12
        }
      }
    }


    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: [
          { "state": "empty",    "name": "Empty",  "what": "no windows" },
          { "state": "occupied", "name": "In use", "what": "has windows" },
          { "state": "active",   "name": "Active", "what": "the one you are on" },
          { "state": "urgent",   "name": "Urgent", "what": "asks for attention" }
        ]

        CcCard {
          id: slot
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.preferredHeight: 128
          host: page.cc
          pal: page.pal
          showCaption: false
          hint: "Choose the picture for a workspace that is: " + modelData.what + ". Opens a file dialog."
          onActivated: if (!wsPicker.running) { wsPicker.state = modelData.state; wsPicker.running = true }

          // the picture, or a dashed frame with a plus while none is chosen
          Item {
            id: frame
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            width: 48
            height: 48

            Rectangle {
              anchors.fill: parent
              radius: 10
              color: "transparent"
              visible: !page.wsHas[slot.modelData.state]
              border.width: 1
              border.color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.35)
              Text {
                anchors.centerIn: parent
                text: "+"
                color: page.bone
                opacity: 0.6
                font.pixelSize: 24
              }
            }
            Ito.ItoImage {
              id: pic
              palette: page.pal
              anchors.fill: parent
              source: page.wsHas[slot.modelData.state] ? "file://" + page.home + "/.cache/ito/marks/_ws-" + slot.modelData.state + ".png?v=" + page.wsVersion : ""
              fillMode: Image.PreserveAspectFit
              smooth: true
              mipmap: true
            }
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: frame.bottom
            anchors.topMargin: 8
            text: slot.modelData.name
            color: page.bone
            font.family: "Noto Serif"
            font.pixelSize: 12
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: frame.bottom
            anchors.topMargin: 25
            text: slot.modelData.what
            color: page.bone
            opacity: 0.55
            font.family: "Noto Serif"
            font.pixelSize: 10
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            text: page.wsHas[slot.modelData.state] ? "click to change" : "click to choose"
            color: page.pal.lit
            opacity: 0.8
            font.family: "Noto Serif"
            font.pixelSize: 10
          }
        }
      }
    }


    Text {
      visible: page.pickError !== ""
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      text: page.pickError
      color: page.pal.blood
      font.family: "Noto Serif"
      font.pixelSize: 12
    }

    // how the chosen pictures look along the bar: the one you are on, two with windows, two empty
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 56
      radius: 12
      color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.04)
      border.width: 1
      border.color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.14)

      Row {
        anchors.centerIn: parent
        spacing: 14
        Text { anchors.verticalCenter: parent.verticalCenter; text: "ON THE BAR"; color: page.bone; opacity: 0.55
               font.family: "Noto Serif"; font.pixelSize: 10; font.letterSpacing: 2 }
        Repeater {
          model: ["active", "occupied", "occupied", "empty", "empty"]
          Ito.ItoImage {
            required property string modelData
            required property int index
            palette: page.pal
            width: 30
            height: 30
            source: page.wsHas[modelData] ? "file://" + page.home + "/.cache/ito/marks/_ws-" + modelData + ".png?v=" + page.wsVersion : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: modelData === "empty" ? 0.6 : 1
          }
        }
      }
    }


    CcCard {
      Layout.preferredWidth: 220
      Layout.preferredHeight: 30
      radius: 15
      host: page.cc
      pal: page.pal
      showCaption: false
      hint: "Forget the four pictures and go back to the Rings style."
      onActivated: if (!wsReset.running) wsReset.running = true
      Text { anchors.centerIn: parent; text: "Remove my pictures"; color: page.bone; font.family: "Noto Serif"; font.pixelSize: 11 }
    }


    CcHelp {
      pal: page.pal
      title: "How to prepare your pictures (size, format, colours)"
      body: "<b>Size.</b> Every picture square, <b>256 × 256 px</b> (128 up to 1024 works; the file up to 25 MB). Give the four the same size so they line up. Each one is drawn about 29 px on the bar, so keep the subject big and centred with little empty margin.<br>"
          + "<b>Format.</b> PNG, JPG, WebP or SVG. A PNG with a transparent background is best.<br>"
          + "<b>Four states.</b> Empty, In use, Active and Urgent. Pick one and the rest borrow from the nearest; pick all four to tell them apart. "
          + "Make Active stand out (a red stroke, a brighter mark): that is what shows where you are.<br>"
          + "<b>Colours.</b> Dark lines on light paper, light lines on dark, or red strokes: it works out which. Red becomes your accent, everything else follows the theme.<br>"
          + "<b>Numbers.</b> Every workspace wears the same picture for its state, so the position in the row tells them apart. "
          + "Want a number on each? Bake it into a picture and use it as a mark instead.<br>"
          + "<b>Change it later.</b> Press the same button again and choose another picture. Pictures live in ~/.config/ito/marks/ as <i>_ws-empty</i>, <i>_ws-occupied</i>, <i>_ws-active</i>, <i>_ws-urgent</i>."
    }
  }


  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "WHICH ONES"
    note: "Every workspace up to the count, or only the ones with something in them."


    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: [
          { "key": "count", "name": "Always N", "note": "Always draw the first N workspaces, so the row never changes width." },
          { "key": "used",  "name": "Only in use", "note": "Draw only the workspaces with a window in them, and the one you are on." }
        ]

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 62
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: String(page.pal.get("workspaceShow", "count")) === modelData.key
          onActivated: page.act.set("workspaceShow", modelData.key)

          // a row of marks: five for Always N, three for Only in use
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 14
            spacing: 6

            Repeater {
              model: modelData.key === "count" ? 5 : 3

              Rectangle {
                required property int index
                width: 9
                height: 9
                radius: 4.5
                color: index === 1 ? page.pal.blood : "transparent"
                border.width: 1
                border.color: index === 1 ? page.pal.blood
                  : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, modelData.key === "count" && index > 2 ? 0.3 : 0.6)
              }
            }
          }
        }
      }
    }
  }


  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "COUNT"
    note: "Workspaces that are always shown, even empty. More appear by themselves as you open them."


    CcMeter { host: page.cc; pal: page.pal; actions: page.act; percent: false
      enabled: String(page.pal.get("workspaceShow", "count")) === "count"
      opacity: enabled ? 1 : 0.4
      label: "Always shown"; key: "workspaceCount"; fallback: 5; lo: 1; hi: 10
      hint: "The lowest number of workspaces the bar always draws." }
  }

}
