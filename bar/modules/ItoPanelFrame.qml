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
  readonly property real amp: cfg && cfg.motionAmp !== undefined ? cfg.motionAmp : 1
  property url artBase: Qt.resolvedUrl("ito-art/")
  // A short popup (the player) has no free corner for the blood and the spiral.
  readonly property bool roomy: height >= 260
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
  // the content starts a little lower, so the eye at the top edge has room; the panel adds the same to its height
  Binding { target: root.card; property: "topPadding"; value: root.card ? root.card.padding + (root.cfg ? root.cfg.panelHeadroom : 0) : 0; when: root.on && root.card }

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
    width: 34; height: 34
    anchors { bottom: parent.bottom; right: parent.right; bottomMargin: 16; rightMargin: 16 }
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
    visible: root.memo !== ""
    text: root.memo
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
  onOpenedChanged: if (opened && amp > 0 && on) flash.restart()

  // An eye that watches from the top edge, half-lidded and dim; the pointer near the head of the popup opens it.
  Item {
    id: eye
    // 2.6 : 1, like the eye artwork, small enough to sit inside the frame without touching the rule
    width: 84; height: 32
    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 7 }
    readonly property bool awake: headHover.hovered && root.amp > 0
    opacity: awake ? 1 : 0.55
    Behavior on opacity { NumberAnimation { duration: 240 * Math.min(root.amp, 1.4) } }
    // the lid: squashed from the middle while it sleeps, full height once it is looked at
    transform: Scale {
      origin.x: eye.width / 2
      origin.y: eye.height / 2
      yScale: eye.awake ? 1 : 0.7
      Behavior on yScale { NumberAnimation { duration: 260 * Math.min(root.amp, 1.4); easing.type: Easing.OutCubic } }
    }
    // Drawn, not pictured: an almond lid, a bloodshot iris and a spiral for a pupil. Painted once and again only when
    // the palette changes.
    Canvas {
      id: eyeCanvas
      anchors.fill: parent
      readonly property color boneC: root.bone
      readonly property color bloodC: root.cfg ? root.cfg.blood : "#c4162a"
      onBoneCChanged: requestPaint()
      onBloodCChanged: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.reset()
        var w = width, h = height, cx = w / 2, cy = h / 2
        // lid
        c.beginPath()
        c.moveTo(2, cy)
        c.quadraticCurveTo(cx, -h * 0.35, w - 2, cy)
        c.quadraticCurveTo(cx, h * 1.35, 2, cy)
        c.closePath()
        c.fillStyle = Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 1)
        c.fill()
        c.lineWidth = 1.1
        c.strokeStyle = Qt.rgba(boneC.r, boneC.g, boneC.b, 0.85)
        c.stroke()
        // iris
        c.beginPath(); c.arc(cx, cy, h * 0.3, 0, Math.PI * 2)
        c.strokeStyle = bloodC; c.lineWidth = 1.6; c.stroke()
        // veins from the corners
        c.strokeStyle = Qt.rgba(bloodC.r, bloodC.g, bloodC.b, 0.55); c.lineWidth = 0.8
        for (var v = -1; v <= 1; v += 2) {
          c.beginPath(); c.moveTo(v > 0 ? w - 3 : 3, cy)
          c.lineTo(cx + v * h * 0.62, cy - 2); c.moveTo(v > 0 ? w - 3 : 3, cy)
          c.lineTo(cx + v * h * 0.62, cy + 2); c.stroke()
        }
        // pupil: a spiral
        c.strokeStyle = Qt.rgba(boneC.r, boneC.g, boneC.b, 0.9); c.lineWidth = 1
        c.beginPath()
        for (var a = 0; a < 3.2 * Math.PI * 2; a += 0.2) {
          var r = 0.6 + a * 0.36
          var x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r
          if (a === 0) c.moveTo(x, y); else c.lineTo(x, y)
        }
        c.stroke()
      }
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

