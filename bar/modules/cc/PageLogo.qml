import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." as Ito
import "../ItoMarks.js" as Marks

// Logo: the two marks that stand for the shell, the seal in the middle of the bar and the button that opens
// the menu. Both come from the works this is made from, and each says what it is.
ColumnLayout {
  id: page

  property var cc: null
  readonly property var pal: cc.pal
  readonly property var act: cc.actions
  readonly property color bone: pal.bone
  readonly property url art: Qt.resolvedUrl("../ito-art/")

  spacing: 10

  Text {
    visible: page.pickError !== ""
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    text: page.pickError
    color: page.pal.blood
    font.family: "Noto Serif"
    font.pixelSize: 12
  }

  readonly property var seals: Marks.seals
  readonly property var marks: Marks.menuMarks
  readonly property string home: Quickshell.env("HOME")
  readonly property string markKey: String(pal.get("menuMark", "uzumaki"))

  // Pictures the user added (bin/ito-marks). Listing adapts any new one, so dropping a file in the folder
  // and pressing Refresh is all it takes.
  property var custom: []
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
  readonly property string marksTool: Qt.resolvedUrl("../bin/ito-marks").toString().replace("file://", "")

  Process {
    id: lister
    command: [page.marksTool, "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { page.custom = JSON.parse(text) } catch (e) { page.custom = [] }
      }
    }
  }
  // Choosing a picture opens a file dialog; when it is done the list is read again, so the new mark appears.
  Process {
    id: picker
    command: [page.marksTool, "pick"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (!page.pickOk(text)) return
        lister.running = true
        try { var r = JSON.parse(text); if (r.key) page.act.set("menuMark", r.key) } catch (e) {}
      }
    }
  }

  // Your own picture for the seal's letters, or for what stands beside the seal: a file dialog, and if one was chosen
  // it is used at once.
  Process {
    id: sealPicker
    command: [page.marksTool, "pick", "--as", "_seal"]
    stdout: StdioCollector { onStreamFinished: if (page.pickOk(text)) page.act.set("seal", "custom") }
  }
  Process {
    id: decoPicker
    command: [page.marksTool, "pick", "--as", "_deco"]
    stdout: StdioCollector { onStreamFinished: if (page.pickOk(text)) page.act.set("sealDeco", "custom") }
  }

  // A small pill button: choosing a picture from the files.
  component PickButton: CcCard {
    id: pickRoot
    property string label: ""
    Layout.preferredWidth: 190
    Layout.preferredHeight: 30
    radius: 15
    host: page.cc
    pal: page.pal
    showCaption: false

    Text {
      anchors.centerIn: parent
      // A direct id, not `parent.label`: the scene-graph parent isn't guaranteed attached the moment this
      // binding first evaluates, which was logging "Unable to assign [undefined]" once per load.
      text: pickRoot.label
      color: page.bone
      font.family: "Noto Serif"
      font.pixelSize: 11
    }
  }

  Component.onCompleted: lister.running = true

  // ---------------------------------------------------------------- seal
  CcSection {
    host: page.cc
    startOpen: true
    pal: page.pal
    label: "SEAL"
    note: {
      for (var i = 0; i < page.seals.length; i++)
        if (page.seals[i].key === String(page.pal.get("seal", "tomie"))) return page.seals[i].note
      return ""
    }


    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: page.seals

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 112
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: String(page.pal.get("seal", "tomie")) === modelData.key
          visible: page.cc.match(modelData.name + " " + modelData.note + " seal logo")
          onActivated: page.act.set("seal", modelData.key)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            text: modelData.text
            color: parent.current ? page.pal.lit : page.bone
            opacity: parent.current ? 1 : 0.7
            font.family: "Noto Serif CJK JP"
            font.weight: Font.Bold
            font.pixelSize: Math.round(28 * modelData.scale)
            lineHeight: 0.8
            lineHeightMode: Text.ProportionalHeight
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }


    PickButton {
      label: "Choose picture for the seal"
      hint: "Put your own picture where the seal's letters are. It is adapted to the shell's colours."
      onActivated: if (!sealPicker.running) sealPicker.running = true
    }


    CcHelp {
      pal: page.pal
      title: "How to prepare the seal's picture"
      body: "<b>Size.</b> Square, <b>256 × 256 px</b> (anything from 128 up to 1024 works). It takes the place of the seal's letters, about 34 px tall on the bar. The file can be up to 25 MB, though a few hundred KB is plenty.<br>"
          + "<b>Drawing.</b> One bold subject, centred: a glyph, an eye, a small symbol. Fine detail is lost at that size.<br>"
          + "<b>Format and colours.</b> PNG (transparent is best), JPG, WebP or SVG. Light or dark lines both work; red becomes your accent."
    }
  }

  // ---------------------------------------------------------------- menu mark
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "MENU MARK"
    note: {
      for (var i = 0; i < page.marks.length; i++)
        if (page.marks[i].key === page.markKey) return page.marks[i].note
      return Marks.customArt(page.markKey) !== "" ? "Your own picture, adapted to the shell's colours." : ""
    }


    GridLayout {
      Layout.fillWidth: true
      columns: 5
      rowSpacing: 8
      columnSpacing: 8

      Repeater {
        model: page.marks

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.preferredHeight: 108
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: page.markKey === modelData.key
          visible: page.cc.match(modelData.name + " " + modelData.note + " menu mark logo")
          onActivated: page.act.set("menuMark", modelData.key)

          Ito.ItoImage {
            palette: page.pal
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            width: 60
            height: 60
            source: Marks.source(page.art.toString(), modelData.key, page.home, page.pal.markOverrides)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: parent.current ? 1 : 0.8
          }
        }
      }
    }


    PickButton {
      label: "Choose picture for the menu mark"
      hint: "Use your own picture as the menu button. It is added to the list of marks below and used at once."
      onActivated: if (!picker.running) picker.running = true
    }


    CcHelp {
      pal: page.pal
      title: "How to prepare the menu mark's picture"
      body: "<b>Size.</b> Square, <b>512 × 512 px</b> (from 128 up to 2048 works; never more than 8000). It is drawn about 29 px on the bar, so keep one bold subject, centred, with little empty margin. Up to 25 MB.<br>"
          + "<b>Format.</b> PNG (transparent background is best), JPG, WebP or SVG.<br>"
          + "<b>After choosing.</b> It appears under YOUR OWN below; click it to use it. To take it away, delete it from the marks folder."
    }
  }

  // ---------------------------------------------------------------- seal decoration
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "SEAL DECORATION"
    note: {
      var d = Marks.decoration(page.pal)
      return d.note + " It stands on both sides of the seal; Effects makes it pulse, breathe or flicker."
    }


    GridLayout {
      Layout.fillWidth: true
      columns: 5
      rowSpacing: 8
      columnSpacing: 8

      Repeater {
        model: Marks.decorations

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.preferredHeight: 108
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: Marks.decoration(page.pal).key === modelData.key
          visible: page.cc.match(modelData.name + " " + modelData.note + " decoration seal veins")
          onActivated: page.act.set("sealDeco", modelData.key)

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            spacing: 10
            visible: modelData.art !== ""

            Ito.ItoImage {
              palette: page.pal
              width: 26 * modelData.wide
              height: 58
              source: modelData.art === "" ? "" : page.art + modelData.art
              fillMode: Image.PreserveAspectFit
              smooth: true
              mipmap: true
              opacity: parent.parent.current ? 1 : 0.8
            }
            Ito.ItoImage {
              palette: page.pal
              width: 26 * modelData.wide
              height: 58
              mirror: true
              source: modelData.art === "" ? "" : page.art + modelData.art
              fillMode: Image.PreserveAspectFit
              smooth: true
              mipmap: true
              opacity: parent.parent.current ? 1 : 0.8
            }
          }

          Text {
            visible: modelData.art === ""
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 26
            text: "—"
            color: page.bone
            opacity: 0.5
            font.pixelSize: 22
          }
        }
      }
    }


    PickButton {
      label: "Choose picture for the decoration"
      hint: "Put your own picture where the veins are; the other side is its mirror."
      onActivated: if (!decoPicker.running) decoPicker.running = true
    }


    CcHelp {
      pal: page.pal
      title: "How to prepare the decoration's picture"
      body: "<b>Size.</b> Wide and short, <b>600 × 200 px (3 : 1)</b>; anything up to 1800 × 600 is fine. It is shown near 34 px tall beside the seal, and its mirror is drawn on the other side. Up to 25 MB.<br>"
          + "<b>Drawing.</b> Fine lines that reach out from the left edge towards the seal; keep the seal side of the picture on the right.<br>"
          + "<b>Format and colours.</b> PNG with a transparent background is best. Light lines on nothing, with red only where it bleeds."
    }
  }

  // ---------------------------------------------------------------- the user's own
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "YOUR OWN"
    note: "Any picture becomes a menu mark. Put it in the marks folder and press Refresh."


    // What to prepare, said plainly -- folded until asked for.
    CcHelp {
      pal: page.pal
      title: "How to prepare your picture (size, format, colours)"
      body: "<b>Size.</b> Square, <b>512 × 512 px</b> (1024 is plenty; the file up to 25 MB). The mark is drawn 29 px on the bar and 60 px here, "
          + "so it is scaled down: keep the subject big and centred, with little empty margin.<br>"
          + "<b>Format.</b> PNG, JPG, WebP or SVG. A PNG with a transparent background is best; a photo or a scan works too.<br>"
          + "<b>Drawing.</b> Bold, high-contrast pictures read best at 29 px. Fine hatching turns to grey; a face or an eye reads better than a whole scene.<br>"
          + "<b>Colours.</b> Dark lines on light paper, light lines on dark, or red strokes: it works out which. Red becomes your accent, everything else follows the theme.<br>"
          + "<b>Name.</b> The file name is the mark's name. Call it <i>tomie</i>, <i>remina</i>, <i>uzumaki</i>, <i>amigara</i>, <i>halo</i>, <i>flauros</i> or <i>metatron</i> to replace that mark.<br>"
          + "<b>Easiest.</b> Press <i>Choose picture</i>, pick the file, and it appears in the list. Click it to use it.<br>"
          + "<b>Framing a portrait.</b> From a terminal: <i>ito-marks import FILE NAME --crop X,Y,SIDE --tone --disc</i>. "
          + "<i>--crop</i> takes a square (left, top, side in pixels), <i>--tone</i> keeps the shading, <i>--disc</i> sets it in a round badge, "
          + "<i>--gamma 0.7</i> brightens a dark picture."
    }


    GridLayout {
      Layout.fillWidth: true
      columns: 5
      rowSpacing: 8
      columnSpacing: 8

      Repeater {
        model: page.custom

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.preferredHeight: 108
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: "Your picture, adapted. Remove it by deleting the file from the marks folder."
          current: page.markKey === modelData.key
          onActivated: page.act.set("menuMark", modelData.key)

          Ito.ItoImage {
            palette: page.pal
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            width: 60
            height: 60
            source: "file://" + modelData.file
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: parent.current ? 1 : 0.8
          }
        }
      }

      Repeater {
        model: [
          { "label": "Choose picture", "tip": "Pick a picture from your files. It becomes a mark, adapted to the shell's colours.", "act": "pick" },
          { "label": "Open folder", "tip": "Open the marks folder to drop pictures into.", "act": "open" },
          { "label": "Refresh", "tip": "Look for new pictures in the folder.", "act": "refresh" }
        ]

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.preferredHeight: 108
          host: page.cc
          pal: page.pal
          showCaption: false
          hint: modelData.tip
          onActivated: {
            if (modelData.act === "open") Quickshell.execDetached(["xdg-open", page.home + "/.config/ito/marks"])
            else if (modelData.act === "pick") { if (!picker.running) picker.running = true }
            else lister.running = true
          }

          Text {
            anchors.centerIn: parent
            text: modelData.label
            color: page.bone
            font.family: "Noto Serif"
            font.pixelSize: 12
          }
        }
      }
    }
  }

}
