import QtQuick
import "../ItoMotion.js" as Motion

// A selectable card of the control centre: whatever you put inside on top, its name underneath, a blood
// underline when it is the chosen one, and its explanation handed to the footer while the pointer is on it.
Rectangle {
  id: root

  property var host: null           // the ControlCenter, for the footer hint
  property var pal: null            // the shell's colours (an ItoConfig)
  property string caption: ""
  property string hint: ""
  property bool current: false
  property real captionSize: 12
  property bool showCaption: true
  readonly property bool hovered: hover.hovered
  default property alias content: inner.data

  signal activated()

  radius: 12
  color: hover.hovered ? Qt.rgba(pal.bone.r, pal.bone.g, pal.bone.b, 0.09)
    : (current ? Qt.rgba(pal.blood.r, pal.blood.g, pal.blood.b, 0.12) : Qt.rgba(pal.bone.r, pal.bone.g, pal.bone.b, 0.035))
  border.width: 1
  border.color: current ? Qt.rgba(pal.blood.r, pal.blood.g, pal.blood.b, 0.7)
    : Qt.rgba(pal.bone.r, pal.bone.g, pal.bone.b, 0.12)
  // The card leans towards the pointer and gives under a press. Springs settle; nothing snaps.
  scale: press.pressed ? 0.975 : (hover.hovered ? 1.018 : 1)
  Behavior on scale {
    NumberAnimation { duration: Motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.standard }
  }
  Behavior on color { ColorAnimation { duration: Motion.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.soft } }
  Behavior on border.color { ColorAnimation { duration: Motion.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.soft } }

  Item {
    id: inner
    anchors.fill: parent
  }

  Text {
    visible: root.showCaption
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 8
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.caption
    color: root.current ? root.pal.lit : root.pal.bone
    opacity: root.current ? 1 : 0.72
    font.family: "Noto Serif"
    font.pixelSize: root.captionSize
    Behavior on color { ColorAnimation { duration: Motion.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.soft } }
  }

  Rectangle {
    visible: root.showCaption
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 3
    anchors.horizontalCenter: parent.horizontalCenter
    width: 22
    height: 2
    radius: 1
    color: root.pal.blood
    opacity: root.current ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Motion.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.decel } }
  }

  HoverHandler {
    id: hover
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: if (root.host) root.host.hint = hovered ? root.hint : ""
  }

  TapHandler {
    id: press
    onTapped: root.activated()
  }
}
