import QtQuick

// A popup drawn as a manga panel: ink, a ruled frame with a second thin rule inside it, torn corners, a
// spatter of blood in one corner and a screentone patch in another, and a faint mist along the bottom.
//
// Drop one inside a Panel's content (it draws over the card the shell paints and under the content (a negative z would sink it below the card's own fill, so the content holder is lifted one step instead), and it
// takes that card's place: the card is made see-through and square so the frame is the only edge). Colours
// come from the shell's palette, so it follows the theme. It is all static: nothing here repaints or runs
// while the popup is open or shut, and `look` = false hands the plain card back.
Item {
  id: root

  property var cfg: null
  property url artBase: Qt.resolvedUrl("ito-art/")
  readonly property bool on: cfg ? cfg.get("panelFrame", true) !== false : true

  // The card the shell draws around a popup's content is two levels up: content holder -> card.
  // Found once, at start: binding `parent` to a value that itself reads `parent` is a loop.
  property var card: null
  anchors.fill: card
  Component.onCompleted: {
    const holder = parent
    if (holder && holder.parent) { const c = holder.parent; parent = c; card = c; holder.z = 1 }
  }
  z: 0
  visible: on

  readonly property color bone: cfg ? cfg.bone : "#c7ccd1"
  readonly property color ink: cfg ? cfg.ink : "#0b0d0e"

  Binding { target: root.card; property: "color"; value: "transparent"; when: root.on && root.card }
  Binding { target: root.card; property: "radius"; value: 3; when: root.on && root.card }

  // the paper
  Rectangle {
    anchors.fill: parent
    radius: 3
    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.97)
  }

  // mist thickening towards the foot, the way Silent Hill's fog lies low
  Rectangle {
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
    height: parent.height * 0.35
    gradient: Gradient {
      GradientStop { position: 0; color: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0) }
      GradientStop { position: 1; color: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.05) }
    }
  }

  // screentone patch, top right
  ItoImage {
    palette: root.cfg
    source: root.artBase + "misc/screentone.png"
    width: 64; height: 73
    anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 6 }
    opacity: 0.32
    smooth: true
  }

  // blood, bottom left
  ItoImage {
    palette: root.cfg
    source: root.artBase + "misc/blood-splatter.png"
    width: 52; height: 60
    anchors { bottom: parent.bottom; left: parent.left; bottomMargin: 4; leftMargin: 4 }
    opacity: 0.55
    smooth: true
  }

  // the panel's rules: a firm outer line and a thin inner one
  Rectangle {
    anchors.fill: parent
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.6)
  }
  Rectangle {
    anchors { fill: parent; margins: 5 }
    radius: 1
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.24)
  }

  // a spiral, faint, low in the corner where nothing else lives
  ItoImage {
    palette: root.cfg
    source: root.artBase + "system/menu-uzumaki.png"
    width: 34; height: 34
    anchors { bottom: parent.bottom; right: parent.right; bottomMargin: 16; rightMargin: 16 }
    opacity: 0.2
    smooth: true
  }

  // torn corners, top left and bottom right
  ItoImage {
    palette: root.cfg
    source: root.artBase + "misc/corner.png"
    width: 50; height: 60
    anchors { top: parent.top; left: parent.left }
    opacity: 0.9
    smooth: true
  }
  ItoImage {
    palette: root.cfg
    source: root.artBase + "misc/corner.png"
    width: 50; height: 60
    anchors { bottom: parent.bottom; right: parent.right }
    rotation: 180
    opacity: 0.9
    smooth: true
  }
}
