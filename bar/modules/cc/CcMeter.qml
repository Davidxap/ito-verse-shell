import QtQuick
import "../ItoMotion.js" as Motion
import QtQuick.Layouts

// A labelled slider bound to one sidecar key. It writes while the pointer moves, a few times a second, so
// what it controls follows the hand instead of jumping on release.
RowLayout {
  id: root

  property var host: null
  property var pal: null
  property var actions: null
  property string label: ""
  property string key: ""
  property real fallback: 1
  property real lo: 0
  property real hi: 1
  property string hint: ""
  property bool percent: true       // show 62%, or a bare number for a count
  property string unit: ""          // appended to a bare number: "s"
  property string zeroLabel: ""     // shown instead of 0: "Never"
  property real pending: -1

  readonly property real stored: Number(pal.get(key, fallback))
  readonly property real shown: pending >= 0 ? pending : stored
  readonly property real fraction: Math.max(0, Math.min(1, (shown - lo) / (hi - lo)))

  Layout.fillWidth: true
  spacing: 12

  Text {
    Layout.preferredWidth: 130
    text: root.label
    color: root.pal.bone
    opacity: 0.75
    font.family: "Noto Serif"
    font.pixelSize: 12
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: 26

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 3
      radius: 1.5
      color: Qt.rgba(root.pal.bone.r, root.pal.bone.g, root.pal.bone.b, 0.18)
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width * root.fraction
      height: 3
      radius: 1.5
      color: root.pal.blood
      // the bar eases to a value set from outside (a preset), and follows the hand while it drags
      Behavior on width {
        enabled: !drag.pressed
        NumberAnimation { duration: Motion.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.decel }
      }
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      x: parent.width * root.fraction - width / 2
      width: drag.pressed ? 19 : 13
      height: width
      radius: width / 2
      color: drag.pressed ? root.pal.lit : root.pal.bone
      Behavior on width { NumberAnimation { duration: Motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.spring } }
      Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    Timer {
      interval: 140
      repeat: true
      running: drag.pressed
      onTriggered: if (root.pending >= 0) root.actions.set(root.key, root.percent ? root.pending.toFixed(2) : Math.round(root.pending))
    }

    MouseArea {
      id: drag
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      function pick(x) {
        root.pending = root.lo + Math.max(0, Math.min(1, x / width)) * (root.hi - root.lo)
      }
      onEntered: if (root.host) root.host.hint = root.hint
      onExited: if (root.host) root.host.hint = ""
      onPressed: function(mouse) { pick(mouse.x) }
      onPositionChanged: function(mouse) { if (pressed) pick(mouse.x) }
      onReleased: {
        if (root.pending >= 0) root.actions.set(root.key, root.percent ? root.pending.toFixed(2) : Math.round(root.pending))
        root.pending = -1
      }
    }
  }

  Text {
    Layout.preferredWidth: 42
    horizontalAlignment: Text.AlignRight
    text: root.percent ? Math.round(root.shown * 100) + "%"
      : (Math.round(root.shown) === 0 && root.zeroLabel !== "" ? root.zeroLabel : Math.round(root.shown) + root.unit)
    color: root.pal.bone
    font.family: "Noto Serif"
    font.pixelSize: 12
  }
}
