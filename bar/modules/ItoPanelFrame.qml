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
  // Set by the panel: `opened` (for the flash on opening), `alert` (something is wrong: the frame cracks), and
  // `memo` (one small line at the foot, in the voice of a note found in a drawer).
  property bool opened: false
  property bool alert: false
  property string memo: ""
  // Several notes: one is chosen each time the popup opens, so it does not always say the same thing.
  property var memos: []
  property string shownMemo: memo
  // The sign at the head (see ItoCrest): eye, spiral, waves, web, rune, flame, hourglass, bell, or a kind of sky.
  property string emblem: "eye"
  readonly property real amp: cfg && cfg.motionAmp !== undefined ? cfg.motionAmp : 1
  property url artBase: Qt.resolvedUrl("ito-art/")
  // A short popup (the player) has no free corner for the blood and the spiral.
  readonly property bool roomy: height >= 260
  readonly property bool on: cfg ? cfg.get("panelFrame", true) !== false : true

  // The card the shell draws around a popup's content is two levels up: content holder -> card.
  // Found once, at start: binding `parent` to a value that itself reads `parent` is a loop.
  property var card: null
  // Set `target` to frame any plain Item (the calendar, the forecast); left empty, the frame finds the card the
  // shell paints around a popup's content.
  property Item target: null
  // Only the shell's card has these to take over (a see-through fill, square corners, headroom for the eye).
  // Decided once at start: reading `topPadding` here while a Binding writes it would be a loop.
  property bool hostCard: false
  anchors.fill: card
  Component.onCompleted: {
    if (target) { parent = target; card = target; return }
    const holder = parent
    if (holder && holder.parent) {
      const c = holder.parent
      parent = c; card = c; holder.z = 1
      hostCard = ("topPadding" in c)
    }
  }
  Binding { target: root.card; property: "bottomPadding"; value: root.card ? root.card.padding + (root.cfg ? root.cfg.panelFootroom : 0) : 0; when: root.on && root.hostCard }
  z: 0
  visible: on

  readonly property color bone: cfg ? cfg.bone : "#c7ccd1"
  readonly property color ink: cfg ? cfg.ink : "#0b0d0e"

  Binding { target: root.card; property: "color"; value: "transparent"; when: root.on && root.hostCard }
  Binding { target: root.card; property: "radius"; value: 3; when: root.on && root.hostCard }
  // the content starts a little lower, so the eye at the top edge has room; the panel adds the same to its height
  Binding { target: root.card; property: "topPadding"; value: root.card ? root.card.padding + (root.cfg ? root.cfg.panelHeadroom : 0) : 0; when: root.on && root.hostCard }

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
    visible: root.roomy
    source: root.artBase + "misc/blood-splatter.png"
    width: 34; height: 40
    anchors { bottom: parent.bottom; left: parent.left; bottomMargin: 3; leftMargin: 3 }
    opacity: 0.55
    smooth: true
  }

  // the panel's rules: a firm outer line and a thin inner one
  Rectangle {
    anchors.fill: parent
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: root.alert && root.cfg ? Qt.rgba(root.cfg.blood.r, root.cfg.blood.g, root.cfg.blood.b, 0.75) : Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.6)
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
    visible: root.roomy
    source: root.artBase + "system/menu-uzumaki.png"
    width: 22; height: 22
    anchors { bottom: parent.bottom; right: parent.right; bottomMargin: 4; rightMargin: 12 }
    opacity: 0.2
    smooth: true
  }

  // A crack runs up the left edge while something is wrong: a hairline drawn in the accent, so it follows the theme
  // (a picture of one would not). It is painted when it appears or the size or colour changes, and never animates.
  Canvas {
    id: crack
    width: 46
    height: Math.min(root.height * 0.55, 240)
    anchors { left: parent.left; bottom: parent.bottom; leftMargin: 2; bottomMargin: 10 }
    opacity: root.alert ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 420 * Math.min(root.amp, 1.4) } }
    readonly property color line: root.cfg ? root.cfg.blood : "#c4162a"
    onLineChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    onPaint: {
      var c = getContext("2d")
      c.reset()
      var h = height
      // the main fault: a jagged run from the foot upwards, drifting a little in from the edge
      var pts = [[2, h], [9, h * 0.86], [5, h * 0.74], [16, h * 0.6], [10, h * 0.47], [21, h * 0.33], [15, h * 0.2], [24, h * 0.06]]
      c.lineJoin = "miter"; c.lineCap = "round"
      c.strokeStyle = Qt.rgba(line.r, line.g, line.b, 0.9); c.lineWidth = 1.4
      c.beginPath(); c.moveTo(pts[0][0], pts[0][1])
      for (var k = 1; k < pts.length; k++) c.lineTo(pts[k][0], pts[k][1])
      c.stroke()
      // three short branches, thinner
      c.lineWidth = 0.9; c.strokeStyle = Qt.rgba(line.r, line.g, line.b, 0.7)
      var br = [[5, h * 0.74, 1, h * 0.7], [16, h * 0.6, 32, h * 0.56], [10, h * 0.47, 3, h * 0.41], [21, h * 0.33, 38, h * 0.3]]
      for (var b = 0; b < br.length; b++) {
        c.beginPath(); c.moveTo(br[b][0], br[b][1]); c.lineTo(br[b][2], br[b][3]); c.stroke()
      }
    }
  }

  // a note left at the foot
  Text {
    visible: root.shownMemo !== ""
    text: root.shownMemo
    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 5 }
    color: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.38)
    font.family: "Noto Serif"
    font.pixelSize: 9
    font.italic: true
    font.letterSpacing: 0.6
    renderType: Text.NativeRendering
  }

  // torn corners, top left and bottom right
  ItoImage {
    palette: root.cfg
    source: root.artBase + "misc/corner.png"
    width: 36; height: 43
    anchors { top: parent.top; left: parent.left }
    opacity: 0.9
    smooth: true
  }
  ItoImage {
    palette: root.cfg
    source: root.artBase + "misc/corner.png"
    width: 36; height: 43
    anchors { bottom: parent.bottom; right: parent.right }
    rotation: 180
    opacity: 0.9
    smooth: true
  }

  // Opening flickers like a television changing channel: a burst of static that thins out in a fifth of a second.
  Image {
    id: staticFlash
    anchors { fill: parent; margins: 1 }
    source: root.artBase + "decor/static.png"
    fillMode: Image.Tile
    opacity: 0
    visible: opacity > 0.01
    smooth: false
  }
  SequentialAnimation {
    id: flash
    NumberAnimation { target: staticFlash; property: "opacity"; from: 0.5; to: 0.05; duration: 70 }
    NumberAnimation { target: staticFlash; property: "opacity"; to: 0.28; duration: 40 }
    NumberAnimation { target: staticFlash; property: "opacity"; to: 0; duration: 110 }
  }
  onOpenedChanged: {
    if (opened && memos.length > 0) shownMemo = String(memos[Math.floor(Math.random() * memos.length)])
    if (opened && amp > 0 && on) flash.restart()
  }
  onMemoChanged: if (memos.length === 0) shownMemo = memo

  // The emblem at the top edge, dim; the pointer near the head of the popup brings it up.
  Item {
    id: eye
    // small enough to sit inside the frame without touching the rule
    // The room the popup leaves under it is ItoConfig.panelHeadroom: keep the two in step.
    width: 92; height: 28
    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
    readonly property bool awake: headHover.hovered && root.amp > 0
    opacity: awake ? 1 : 0.85
    Behavior on opacity { NumberAnimation { duration: 240 * Math.min(root.amp, 1.4) } }
    // the eye's lid: squashed from the middle while it sleeps, full height once it is looked at
    transform: Scale {
      origin.x: eye.width / 2
      origin.y: eye.height / 2
      yScale: (eye.awake || root.emblem !== "eye") ? 1 : 0.86
      Behavior on yScale { NumberAnimation { duration: 260 * Math.min(root.amp, 1.4); easing.type: Easing.OutCubic } }
    }
    // Drawn as vector curves, so it stays sharp and takes the theme's colours.
    ItoCrest {
      anchors.fill: parent
      kind: root.emblem
      bone: root.bone
      blood: root.cfg ? root.cfg.blood : "#c4162a"
      ink: root.ink
    }
  }

  // the head of the popup: the top 64 px
  Item {
    id: head
    anchors { top: parent.top; left: parent.left; right: parent.right }
    height: 64
    HoverHandler { id: headHover; enabled: root.on }
  }
}

