import QtQuick
import QtQuick.Shapes

// The eye that watches from the top edge of a popup: an almond, a ringed iris, a spiral for a pupil and lashes at
// the outer corner. Drawn as vector curves (Shapes) with the curve renderer, so its lines stay sharp at any size and
// screen scale, and it takes the theme's colours from `bone`, `blood` and `ink`. It is static: nothing repaints.
Item {
  id: root

  property color bone: "#c7ccd1"
  property color blood: "#c4162a"
  property color ink: "#0b0d0e"

  // degrees the pupil has turned; the caller drives it (0 leaves it still)
  property real spin: 0

  implicitWidth: 84
  implicitHeight: 32

  readonly property real w: width
  readonly property real h: height
  readonly property real cx: w / 2
  readonly property real cy: h / 2
  readonly property real irisR: h * 0.31

  // the spiral, as a list of points from the centre outwards
  readonly property var spiral: {
    var pts = [], turns = 2.6, r = irisR * 0.86
    for (var a = 0.15; a <= turns * 2 * Math.PI; a += 0.12) {
      var rr = 0.6 + a * (r - 0.6) / (turns * 2 * Math.PI)
      pts.push(Qt.point(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr))
    }
    return pts
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true

    // the opening, filled with ink
    ShapePath {
      fillColor: root.ink
      strokeColor: "transparent"
      startX: 3; startY: root.cy
      PathCubic { x: root.w - 3; y: root.cy - 0.5; control1X: root.w * 0.28; control1Y: -root.h * 0.14; control2X: root.w * 0.72; control2Y: -root.h * 0.14 }
      PathCubic { x: 3; y: root.cy; control1X: root.w * 0.74; control1Y: root.h * 1.14; control2X: root.w * 0.26; control2Y: root.h * 1.14 }
    }

    // the iris: a faint fill and a ring in the accent
    ShapePath {
      fillColor: Qt.rgba(root.blood.r, root.blood.g, root.blood.b, 0.18)
      strokeColor: root.blood
      strokeWidth: 1.5
      startX: root.cx + root.irisR; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: root.irisR; radiusY: root.irisR; startAngle: 0; sweepAngle: 360 }
    }

    // the upper lid, firm
    ShapePath {
      fillColor: "transparent"
      strokeColor: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.95)
      strokeWidth: 1.7
      capStyle: ShapePath.RoundCap
      startX: 3; startY: root.cy
      PathCubic { x: root.w - 3; y: root.cy - 0.5; control1X: root.w * 0.28; control1Y: -root.h * 0.14; control2X: root.w * 0.72; control2Y: -root.h * 0.14 }
    }

    // the lower lid, thin
    ShapePath {
      fillColor: "transparent"
      strokeColor: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.7)
      strokeWidth: 1
      capStyle: ShapePath.RoundCap
      startX: root.w - 3; startY: root.cy - 0.5
      PathCubic { x: 3; y: root.cy; control1X: root.w * 0.74; control1Y: root.h * 1.14; control2X: root.w * 0.26; control2Y: root.h * 1.14 }
    }

    // lashes at the outer corner
    ShapePath {
      fillColor: "transparent"
      strokeColor: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.85)
      strokeWidth: 1
      capStyle: ShapePath.RoundCap
      PathMultiline {
        paths: {
          var out = []
          for (var n = 0; n < 4; n++) {
            var t = 0.72 + n * 0.07
            var bx = 3 + (root.w - 6) * t
            var by = root.cy - root.h * 0.37 * Math.sin(Math.PI * t) - 0.5
            out.push([Qt.point(bx, by), Qt.point(bx + 2.4 + n * 0.6, by - 3.4 - n * 0.4)])
          }
          return out
        }
      }
    }
  }

  // the pupil turns on its own layer, so turning it never redraws the eye
  Item {
    anchors.fill: parent
    rotation: root.spin
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
      ShapePath {
        fillColor: "transparent"
        strokeColor: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.95)
        strokeWidth: 1
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: root.spiral }
      }
    }
  }
}
