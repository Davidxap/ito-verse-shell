import QtQuick
import QtQuick.Shapes

// The emblem at the head of a popup: a small drawn sign for what the popup watches, between two rules that end in
// diamonds, like the ornament over a chapter in a manga. One is chosen with `kind`:
//
//   eye        watching            spiral     the player (a record that never ends)
//   waves      sound               web        the network
//   rune       Bluetooth           flame      power
//   hourglass  time                bell       notifications
//   sun moon cloud rain storm snow fog   the sky
//
// Everything is vector (Shapes, curve renderer), so it stays sharp at any size and screen scale, and it takes the
// theme's colours: `bone` for the line, `blood` for the one living detail. Static: nothing repaints.
Item {
  id: root

  property string kind: "eye"
  property color bone: "#c7ccd1"
  property color blood: "#c4162a"
  property color ink: "#0b0d0e"

  implicitWidth: 96
  implicitHeight: 32

  readonly property real cx: width / 2
  readonly property real cy: height / 2
  readonly property real u: Math.min(height, 32) / 32       // one drawing unit: the emblem is designed on 32 px
  readonly property color line: Qt.rgba(bone.r, bone.g, bone.b, 0.92)
  readonly property color soft: Qt.rgba(bone.r, bone.g, bone.b, 0.55)

  function pt(x, y) { return Qt.point(cx + x * u, cy + y * u) }

  // ---------------------------------------------------------------- the rules either side
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind !== "eye"

    ShapePath {
      strokeColor: root.soft; strokeWidth: 1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      startX: 2; startY: root.cy
      PathLine { x: root.cx - 24 * root.u; y: root.cy }
    }
    ShapePath {
      strokeColor: root.soft; strokeWidth: 1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      startX: root.width - 2; startY: root.cy
      PathLine { x: root.cx + 24 * root.u; y: root.cy }
    }
    // a diamond where each rule meets the emblem
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: Qt.rgba(root.blood.r, root.blood.g, root.blood.b, 0.5)
      startX: root.cx - 24 * root.u; startY: root.cy - 2.6
      PathLine { x: root.cx - 24 * root.u + 2.6; y: root.cy }
      PathLine { x: root.cx - 24 * root.u; y: root.cy + 2.6 }
      PathLine { x: root.cx - 24 * root.u - 2.6; y: root.cy }
      PathLine { x: root.cx - 24 * root.u; y: root.cy - 2.6 }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: Qt.rgba(root.blood.r, root.blood.g, root.blood.b, 0.5)
      startX: root.cx + 24 * root.u; startY: root.cy - 2.6
      PathLine { x: root.cx + 24 * root.u + 2.6; y: root.cy }
      PathLine { x: root.cx + 24 * root.u; y: root.cy + 2.6 }
      PathLine { x: root.cx + 24 * root.u - 2.6; y: root.cy }
      PathLine { x: root.cx + 24 * root.u; y: root.cy - 2.6 }
    }
  }

  // ---------------------------------------------------------------- eye
  ItoEye {
    visible: root.kind === "eye"
    anchors.centerIn: parent
    width: 84; height: 32
    bone: root.bone; blood: root.blood; ink: root.ink
  }

  // ---------------------------------------------------------------- spiral: the player
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "spiral"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.3; fillColor: "transparent"
      capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
      PathPolyline {
        path: {
          var out = [], turns = 3.2, r = 14
          for (var a = 0.2; a <= turns * 2 * Math.PI; a += 0.1) {
            var rr = 1 + a * (r - 1) / (turns * 2 * Math.PI)
            out.push(root.pt(Math.cos(a) * rr, Math.sin(a) * rr))
          }
          return out
        }
      }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.2; fillColor: root.blood
      startX: root.cx + 2.2 * root.u; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 2.2 * root.u; radiusY: 2.2 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  // ---------------------------------------------------------------- waves: sound
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "waves"
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.2; fillColor: root.blood
      startX: root.cx + 2.4 * root.u; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 2.4 * root.u; radiusY: 2.4 * root.u; startAngle: 0; sweepAngle: 360 }
    }
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      startX: root.cx + 8 * root.u * Math.cos(-0.9); startY: root.cy + 8 * root.u * Math.sin(-0.9)
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 8 * root.u; radiusY: 8 * root.u; startAngle: -52; sweepAngle: 104 }
    }
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      startX: root.cx - 8 * root.u * Math.cos(-0.9); startY: root.cy + 8 * root.u * Math.sin(-0.9)
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 8 * root.u; radiusY: 8 * root.u; startAngle: 232; sweepAngle: -104 }
    }
    ShapePath {
      strokeColor: root.soft; strokeWidth: 1.2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      startX: root.cx + 13 * root.u * Math.cos(-0.9); startY: root.cy + 13 * root.u * Math.sin(-0.9)
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 13 * root.u; radiusY: 13 * root.u; startAngle: -52; sweepAngle: 104 }
    }
    ShapePath {
      strokeColor: root.soft; strokeWidth: 1.2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      startX: root.cx - 13 * root.u * Math.cos(-0.9); startY: root.cy + 13 * root.u * Math.sin(-0.9)
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 13 * root.u; radiusY: 13 * root.u; startAngle: 232; sweepAngle: -104 }
    }
  }

  // ---------------------------------------------------------------- web: the network
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "web"
    // spokes
    ShapePath {
      strokeColor: root.soft; strokeWidth: 1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathMultiline {
        paths: {
          var out = []
          for (var i = 0; i < 6; i++) {
            var a = i * Math.PI / 3 - Math.PI / 2
            out.push([root.pt(0, 0), root.pt(Math.cos(a) * 14, Math.sin(a) * 14)])
          }
          return out
        }
      }
    }
    // two rings of thread, slightly sagging between the spokes
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.1; fillColor: "transparent"; joinStyle: ShapePath.RoundJoin
      PathPolyline {
        path: { var o = []; for (var i = 0; i <= 6; i++) { var a = i * Math.PI / 3 - Math.PI / 2; o.push(root.pt(Math.cos(a) * 6, Math.sin(a) * 6)) } return o }
      }
    }
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.1; fillColor: "transparent"; joinStyle: ShapePath.RoundJoin
      PathPolyline {
        path: { var o = []; for (var i = 0; i <= 6; i++) { var a = i * Math.PI / 3 - Math.PI / 2; o.push(root.pt(Math.cos(a) * 11, Math.sin(a) * 11)) } return o }
      }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: root.blood
      startX: root.cx + 1.8 * root.u; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 1.8 * root.u; radiusY: 1.8 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  // ---------------------------------------------------------------- rune: Bluetooth
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "rune"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.5; fillColor: "transparent"
      capStyle: ShapePath.RoundCap; joinStyle: ShapePath.MiterJoin
      PathPolyline {
        path: [root.pt(-6, -6), root.pt(6, 6), root.pt(0, 12), root.pt(0, -12), root.pt(6, -6), root.pt(-6, 6)]
      }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.2; fillColor: root.blood
      startX: root.cx + 1.6 * root.u; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 1.6 * root.u; radiusY: 1.6 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  // ---------------------------------------------------------------- flame: power
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "flame"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"; joinStyle: ShapePath.RoundJoin
      startX: root.cx; startY: root.cy - 13 * root.u
      PathCubic {
        x: root.cx; y: root.cy + 12 * root.u
        control1X: root.cx + 12 * root.u; control1Y: root.cy - 4 * root.u
        control2X: root.cx + 10 * root.u; control2Y: root.cy + 12 * root.u
      }
      PathCubic {
        x: root.cx; y: root.cy - 13 * root.u
        control1X: root.cx - 10 * root.u; control1Y: root.cy + 12 * root.u
        control2X: root.cx - 12 * root.u; control2Y: root.cy - 4 * root.u
      }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.2
      fillColor: Qt.rgba(root.blood.r, root.blood.g, root.blood.b, 0.45)
      startX: root.cx; startY: root.cy - 2 * root.u
      PathCubic {
        x: root.cx; y: root.cy + 9 * root.u
        control1X: root.cx + 5 * root.u; control1Y: root.cy + 2 * root.u
        control2X: root.cx + 4 * root.u; control2Y: root.cy + 9 * root.u
      }
      PathCubic {
        x: root.cx; y: root.cy - 2 * root.u
        control1X: root.cx - 4 * root.u; control1Y: root.cy + 9 * root.u
        control2X: root.cx - 5 * root.u; control2Y: root.cy + 2 * root.u
      }
    }
  }

  // ---------------------------------------------------------------- hourglass: time
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "hourglass"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"
      capStyle: ShapePath.RoundCap; joinStyle: ShapePath.MiterJoin
      PathPolyline {
        path: [root.pt(-9, -13), root.pt(9, -13), root.pt(1.4, 0), root.pt(9, 13), root.pt(-9, 13), root.pt(-1.4, 0), root.pt(-9, -13)]
      }
    }
    // the sand: a little left above, a heap below, one grain falling
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: Qt.rgba(root.blood.r, root.blood.g, root.blood.b, 0.5)
      PathPolyline { path: [root.pt(-3.8, -8), root.pt(3.8, -8), root.pt(0, -2.4), root.pt(-3.8, -8)] }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: Qt.rgba(root.blood.r, root.blood.g, root.blood.b, 0.5)
      PathPolyline { path: [root.pt(-6, 11.4), root.pt(6, 11.4), root.pt(0, 5.4), root.pt(-6, 11.4)] }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathPolyline { path: [root.pt(0, -1.6), root.pt(0, 4.4)] }
    }
  }

  // ---------------------------------------------------------------- bell: notifications
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "bell"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"
      capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
      startX: root.cx - 11 * root.u; startY: root.cy + 8 * root.u
      PathLine { x: root.cx - 8 * root.u; y: root.cy + 5.5 * root.u }
      PathCubic {
        x: root.cx; y: root.cy - 11 * root.u
        control1X: root.cx - 8 * root.u; control1Y: root.cy - 2 * root.u
        control2X: root.cx - 6 * root.u; control2Y: root.cy - 11 * root.u
      }
      PathCubic {
        x: root.cx + 8 * root.u; y: root.cy + 5.5 * root.u
        control1X: root.cx + 6 * root.u; control1Y: root.cy - 11 * root.u
        control2X: root.cx + 8 * root.u; control2Y: root.cy - 2 * root.u
      }
      PathLine { x: root.cx + 11 * root.u; y: root.cy + 8 * root.u }
      PathLine { x: root.cx - 11 * root.u; y: root.cy + 8 * root.u }
    }
    // the clapper, the one living thing
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.2; fillColor: root.blood
      startX: root.cx + 2.4 * root.u; startY: root.cy + 11.6 * root.u
      PathAngleArc { centerX: root.cx; centerY: root.cy + 11.6 * root.u; radiusX: 2.4 * root.u; radiusY: 2.4 * root.u; startAngle: 0; sweepAngle: 360 }
    }
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathPolyline { path: [root.pt(0, -11), root.pt(0, -13.5)] }
    }
  }

  // ---------------------------------------------------------------- the sky
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: ["sun", "suncloud"].indexOf(root.kind) >= 0
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"
      startX: root.cx + 6 * root.u; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 6 * root.u; radiusY: 6 * root.u; startAngle: 0; sweepAngle: 360 }
    }
    ShapePath {
      strokeColor: root.soft; strokeWidth: 1.2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathMultiline {
        paths: {
          var out = []
          for (var i = 0; i < 12; i++) {
            var a = i * Math.PI / 6
            out.push([root.pt(Math.cos(a) * 9, Math.sin(a) * 9), root.pt(Math.cos(a) * (i % 2 ? 12 : 14), Math.sin(a) * (i % 2 ? 12 : 14))])
          }
          return out
        }
      }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: root.blood
      startX: root.cx + 1.8 * root.u; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 1.8 * root.u; radiusY: 1.8 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "moon"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"; joinStyle: ShapePath.RoundJoin
      startX: root.cx + 4 * root.u; startY: root.cy - 12 * root.u
      PathArc { x: root.cx + 4 * root.u; y: root.cy + 12 * root.u; radiusX: 12 * root.u; radiusY: 12 * root.u; direction: PathArc.Counterclockwise }
      PathArc { x: root.cx + 4 * root.u; y: root.cy - 12 * root.u; radiusX: 9 * root.u; radiusY: 9 * root.u; direction: PathArc.Clockwise }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: root.blood
      startX: root.cx + 9 * root.u + 1.6 * root.u; startY: root.cy - 6 * root.u
      PathAngleArc { centerX: root.cx + 9 * root.u; centerY: root.cy - 6 * root.u; radiusX: 1.6 * root.u; radiusY: 1.6 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  // a cloud, with what falls from it
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: ["cloud", "rain", "storm", "snow"].indexOf(root.kind) >= 0
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"
      capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
      startX: root.cx - 12 * root.u; startY: root.cy + (root.kind === "cloud" ? 5 : 1) * root.u
      PathArc { x: root.cx - 9 * root.u; y: root.cy + (root.kind === "cloud" ? -3 : -7) * root.u; radiusX: 5 * root.u; radiusY: 5 * root.u; direction: PathArc.Clockwise }
      PathArc { x: root.cx + 4 * root.u; y: root.cy + (root.kind === "cloud" ? -6 : -10) * root.u; radiusX: 7 * root.u; radiusY: 7 * root.u; direction: PathArc.Clockwise }
      PathArc { x: root.cx + 11 * root.u; y: root.cy + (root.kind === "cloud" ? 1 : -3) * root.u; radiusX: 6 * root.u; radiusY: 6 * root.u; direction: PathArc.Clockwise }
      PathArc { x: root.cx + 9 * root.u; y: root.cy + (root.kind === "cloud" ? 5 : 1) * root.u; radiusX: 3 * root.u; radiusY: 3 * root.u; direction: PathArc.Clockwise }
      PathLine { x: root.cx - 12 * root.u; y: root.cy + (root.kind === "cloud" ? 5 : 1) * root.u }
    }
    // rain
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathMultiline {
        paths: root.kind === "rain" ? [
          [root.pt(-7, 5), root.pt(-9, 11)], [root.pt(-1, 5), root.pt(-3, 11)],
          [root.pt(5, 5), root.pt(3, 11)], [root.pt(10, 5), root.pt(8, 11)]] : []
      }
    }
    // lightning
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.3; fillColor: "transparent"
      capStyle: ShapePath.RoundCap; joinStyle: ShapePath.MiterJoin
      PathPolyline {
        path: root.kind === "storm" ? [root.pt(2, 3), root.pt(-3, 8), root.pt(1, 8), root.pt(-3, 13)] : []
      }
    }
    // snow
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathMultiline {
        paths: {
          if (root.kind !== "snow") return []
          var out = []
          var cs = [[-6, 9], [0, 12], [6, 9]]
          for (var c = 0; c < cs.length; c++)
            for (var k = 0; k < 3; k++) {
              var a = k * Math.PI / 3
              out.push([root.pt(cs[c][0] - Math.cos(a) * 2.2, cs[c][1] - Math.sin(a) * 2.2),
                        root.pt(cs[c][0] + Math.cos(a) * 2.2, cs[c][1] + Math.sin(a) * 2.2)])
            }
          return out
        }
      }
    }
  }

  // fog: layers that do not quite line up
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "fog"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      startX: root.cx - 12 * root.u; startY: root.cy - 7 * root.u
      PathCubic { x: root.cx + 8 * root.u; y: root.cy - 7 * root.u; control1X: root.cx - 6 * root.u; control1Y: root.cy - 10 * root.u; control2X: root.cx + 2 * root.u; control2Y: root.cy - 4 * root.u }
    }
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      startX: root.cx - 8 * root.u; startY: root.cy
      PathCubic { x: root.cx + 12 * root.u; y: root.cy; control1X: root.cx - 2 * root.u; control1Y: root.cy - 3 * root.u; control2X: root.cx + 6 * root.u; control2Y: root.cy + 3 * root.u }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      startX: root.cx - 12 * root.u; startY: root.cy + 7 * root.u
      PathCubic { x: root.cx + 6 * root.u; y: root.cy + 7 * root.u; control1X: root.cx - 6 * root.u; control1Y: root.cy + 4 * root.u; control2X: root.cx; control2Y: root.cy + 10 * root.u }
    }
  }
}
