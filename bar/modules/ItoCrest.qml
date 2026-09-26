import QtQuick
import QtQuick.Shapes

// The emblem at the head of a popup: a small drawn sign for what the popup watches, between two rules that end in
// diamonds, like the ornament over a chapter in a manga. One is chosen with `kind`:
//
//   eye        watching            spiral     the player (a record that never ends)
//   waves      sound               signal     the network (a signal that will not settle)
//   rune       Bluetooth           flame      power
//   clock      time                phone      notifications (a receiver that rings)
//   mind       AI usage
//   sun moon cloud rain storm snow fog   the sky
//
// Everything is vector (Shapes, curve renderer), so it stays sharp at any size and screen scale, and it takes the
// theme's colours: `bone` for the line, `blood` for the one living detail. Lines are inked by hand: circles and arcs
// wander a little off true, the way a pen does, so nothing looks like a stock icon.
//
// It moves only while `live` (the popup is open) and Motion is not off: one clock, and only transforms and opacity
// change, never the geometry, so nothing is re-tessellated and an open popup costs almost nothing.
Item {
  id: root

  property string kind: "eye"
  property color bone: "#c7ccd1"
  property color blood: "#c4162a"
  property color ink: "#0b0d0e"
  property bool live: false
  property real amp: 1

  implicitWidth: 96
  implicitHeight: 32

  readonly property real cx: width / 2
  readonly property real cy: height / 2
  readonly property real u: Math.min(height, 32) / 32       // one drawing unit: the emblem is designed on 32 px
  readonly property color line: Qt.rgba(bone.r, bone.g, bone.b, 0.92)
  readonly property color soft: Qt.rgba(bone.r, bone.g, bone.b, 0.55)
  readonly property color dim: Qt.rgba(bone.r, bone.g, bone.b, 0.3)
  readonly property color redSoft: Qt.rgba(blood.r, blood.g, blood.b, 0.5)

  // seconds since it started moving
  property real t: 0
  FrameAnimation {
    running: root.live && root.amp > 0
    onTriggered: root.t += frameTime
  }
  readonly property bool moving: live && amp > 0
  // a wall clock in milliseconds, refreshed only while the emblem is the clock and it is moving
  property real nowMs: Date.now()
  Timer { running: root.moving && root.kind === "clock"; interval: 250; repeat: true; onTriggered: root.nowMs = Date.now() }

  function pt(x, y) { return Qt.point(cx + x * u, cy + y * u) }
  function wob(i, k) { return 0.3 * Math.sin(i * 2.31 + k) + 0.2 * Math.sin(i * 5.17 + k * 1.7) }
  // a circle or an arc, wandering off true by a few tenths of a unit: ink, not geometry
  function inked(x, y, r, a0, a1, n, k) {
    var out = []
    for (var i = 0; i <= n; i++) {
      var a = a0 + (a1 - a0) * i / n
      var rr = r + wob(i, k)
      out.push(pt(x + Math.cos(a) * rr, y + Math.sin(a) * rr))
    }
    return out
  }
  function spiralPts(x, y, r0, r1, turns, k) {
    var out = [], n = Math.round(turns * 34)
    for (var i = 0; i <= n; i++) {
      var f = i / n, a = f * turns * 2 * Math.PI
      var rr = r0 + (r1 - r0) * f + 0.25 * wob(i, k)
      out.push(pt(x + Math.cos(a) * rr, y + Math.sin(a) * rr))
    }
    return out
  }

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
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: root.redSoft
      startX: root.cx - 24 * root.u; startY: root.cy - 2.6
      PathLine { x: root.cx - 24 * root.u + 2.6; y: root.cy }
      PathLine { x: root.cx - 24 * root.u; y: root.cy + 2.6 }
      PathLine { x: root.cx - 24 * root.u - 2.6; y: root.cy }
      PathLine { x: root.cx - 24 * root.u; y: root.cy - 2.6 }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: root.redSoft
      startX: root.cx + 24 * root.u; startY: root.cy - 2.6
      PathLine { x: root.cx + 24 * root.u + 2.6; y: root.cy }
      PathLine { x: root.cx + 24 * root.u; y: root.cy + 2.6 }
      PathLine { x: root.cx + 24 * root.u - 2.6; y: root.cy }
      PathLine { x: root.cx + 24 * root.u; y: root.cy - 2.6 }
    }
  }

  // ---------------------------------------------------------------- eye: the pupil turns
  ItoEye {
    visible: root.kind === "eye"
    anchors.centerIn: parent
    width: 84 * root.u; height: 32 * root.u
    bone: root.bone; blood: root.blood; ink: root.ink
    spin: root.moving ? root.t * 34 : 0
  }

  // ---------------------------------------------------------------- spiral: the player, turning
  Item {
    anchors.fill: parent
    visible: root.kind === "spiral"
    rotation: root.moving ? root.t * 42 : 0
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
      ShapePath {
        strokeColor: root.line; strokeWidth: 1.5; fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        PathPolyline { path: root.spiralPts(0, 0, 1.2, 14, 3.4, 1) }
      }
      ShapePath {
        strokeColor: root.redSoft; strokeWidth: 1.1; fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        PathPolyline { path: root.spiralPts(0, 0, 1.2, 12, 3.0, 4).map(function(p) { return Qt.point(2 * root.cx - p.x, 2 * root.cy - p.y) }) }
      }
    }
  }
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "spiral"
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.2; fillColor: root.blood
      startX: root.cx + 2 * root.u; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 2 * root.u; radiusY: 2 * root.u; startAngle: 0; sweepAngle: 360 }
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
  }
  // two rings of arcs, each side; the outer one breathes out and in, half a beat behind the inner
  Repeater {
    model: [{ "r": 8, "w": 1.4, "k": 1 }, { "r": 13.5, "w": 1.2, "k": 2 }]
    Item {
      required property var modelData
      required property int index
      anchors.fill: parent
      visible: root.kind === "waves"
      scale: root.moving ? 1 + 0.09 * Math.sin(root.t * 4 - index * 1.6) : 1
      opacity: root.moving ? 0.6 + 0.4 * (0.5 + 0.5 * Math.sin(root.t * 4 - index * 1.6)) : 1
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        ShapePath {
          strokeColor: index === 0 ? root.line : root.soft; strokeWidth: modelData.w; fillColor: "transparent"; capStyle: ShapePath.RoundCap
          PathPolyline { path: root.inked(0, 0, modelData.r, -0.9, 0.9, 16, modelData.k) }
        }
        ShapePath {
          strokeColor: index === 0 ? root.line : root.soft; strokeWidth: modelData.w; fillColor: "transparent"; capStyle: ShapePath.RoundCap
          PathPolyline { path: root.inked(0, 0, modelData.r, Math.PI - 0.9, Math.PI + 0.9, 16, modelData.k + 3) }
        }
      }
    }
  }

  // ---------------------------------------------------------------- signal: the network
  // A dot and three arcs that never quite close: they light one after another, outwards, and start again, like a
  // signal looking for something to answer it.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "signal"
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.2; fillColor: root.blood
      startX: root.cx + 2.3 * root.u; startY: root.cy + 9 * root.u
      PathAngleArc { centerX: root.cx; centerY: root.cy + 9 * root.u; radiusX: 2.3 * root.u; radiusY: 2.3 * root.u; startAngle: 0; sweepAngle: 360 }
    }
    // a crack in the mast: it is not a clean line
    ShapePath {
      strokeColor: root.soft; strokeWidth: 1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathPolyline { path: [root.pt(0, 6.5), root.pt(-1.2, 3), root.pt(1, 0.5), root.pt(-0.6, -2)] }
    }
  }
  Repeater {
    model: [{ "r": 7, "k": 1 }, { "r": 12, "k": 5 }, { "r": 17, "k": 9 }]
    Shape {
      required property var modelData
      required property int index
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
      visible: root.kind === "signal"
      opacity: root.moving ? Math.max(0.22, 1 - ((root.t * 1.5 - index * 0.5) % 1.8 + 1.8) % 1.8 / 1.1) : 1
      ShapePath {
        strokeColor: index === 0 ? root.line : (index === 1 ? root.soft : root.dim)
        strokeWidth: 1.5 - index * 0.15; fillColor: "transparent"; capStyle: ShapePath.RoundCap
        PathPolyline { path: root.inked(0, 9, modelData.r, -Math.PI * 0.86, -Math.PI * 0.14, 22, modelData.k) }
      }
    }
  }

  // ---------------------------------------------------------------- rune: Bluetooth
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "rune"
    opacity: root.moving ? 0.8 + 0.2 * Math.sin(root.t * 3.1) * Math.sin(root.t * 1.3 + 1) : 1
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.5; fillColor: "transparent"
      capStyle: ShapePath.RoundCap; joinStyle: ShapePath.MiterJoin
      PathPolyline {
        path: [root.pt(-6, -6), root.pt(6, 6), root.pt(0, 12), root.pt(0, -12), root.pt(6, -6), root.pt(-6, 6)]
      }
    }
  }
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "rune"
    scale: root.moving ? 1 + 0.35 * Math.max(0, Math.sin(root.t * 3.4)) : 1
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.2; fillColor: root.blood
      startX: root.cx + 1.6 * root.u; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 1.6 * root.u; radiusY: 1.6 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  // ---------------------------------------------------------------- flame: power, guttering
  Item {
    anchors.fill: parent
    visible: root.kind === "flame"
    transformOrigin: Item.Bottom
    scale: root.moving ? 1 + 0.03 * Math.sin(root.t * 5.3) : 1
    transform: Scale {
      origin.x: root.cx; origin.y: root.cy + 12 * root.u
      yScale: root.moving ? 1 + 0.07 * Math.sin(root.t * 7.1) + 0.04 * Math.sin(root.t * 13.3 + 2) : 1
    }
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
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
  }

  // ---------------------------------------------------------------- clock: time, with a hand that will not stop
  // A hand-inked face with twelve uneven ticks, an hour and a minute hand that tell the real time, and a second
  // hand in blood that sweeps. Twelve is marked in blood: it is where the loop begins again.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "clock"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.5; fillColor: "transparent"; joinStyle: ShapePath.RoundJoin
      PathPolyline { path: root.inked(0, 0, 12.5, 0, Math.PI * 2, 48, 2) }
    }
    ShapePath {
      strokeColor: root.soft; strokeWidth: 1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathMultiline {
        paths: {
          var out = []
          for (var i = 0; i < 12; i++) {
            var a = i * Math.PI / 6 - Math.PI / 2
            var r1 = (i % 3 === 0 ? 8.2 : 9.6) + 0.3 * root.wob(i, 6)
            out.push([root.pt(Math.cos(a) * r1, Math.sin(a) * r1), root.pt(Math.cos(a) * 11, Math.sin(a) * 11)])
          }
          return out
        }
      }
    }
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.6; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathPolyline { path: [root.pt(0, -8.4), root.pt(0, -11.2)] }
    }
  }
  // hour and minute hands: real time
  Repeater {
    model: [{ "len": 6, "w": 1.9 }, { "len": 9.5, "w": 1.4 }]
    Item {
      required property var modelData
      required property int index
      anchors.fill: parent
      visible: root.kind === "clock"
      readonly property real mins: new Date(root.nowMs).getMinutes() + new Date(root.nowMs).getSeconds() / 60
      rotation: index === 0 ? ((new Date(root.nowMs).getHours() % 12) + mins / 60) * 30 : mins * 6
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        ShapePath {
          strokeColor: root.line; strokeWidth: modelData.w; fillColor: "transparent"; capStyle: ShapePath.RoundCap
          PathPolyline { path: [root.pt(0, 1.5), root.pt(0, -modelData.len)] }
        }
      }
    }
  }
  // the second hand sweeps; it ends in a small loop, a curl of hair
  Item {
    anchors.fill: parent
    visible: root.kind === "clock"
    rotation: (root.nowMs % 60000) / 1000 * 6 + (root.moving ? (root.nowMs % 250) * 0 : 0)
    Behavior on rotation { enabled: false }
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
      ShapePath {
        strokeColor: root.blood; strokeWidth: 1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
        PathPolyline { path: [root.pt(0, 3.4), root.pt(0, -9.4)] }
      }
      ShapePath {
        strokeColor: root.blood; strokeWidth: 1; fillColor: "transparent"
        PathPolyline { path: root.inked(0, -10.6, 1.3, 0, Math.PI * 2, 14, 8) }
      }
    }
  }
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "clock"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1; fillColor: root.ink
      startX: root.cx + 1.5 * root.u; startY: root.cy
      PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 1.5 * root.u; radiusY: 1.5 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  // ---------------------------------------------------------------- phone: notifications, a receiver that rings
  // An old handset with a coiled cord (a spiral, of course). It shakes in short bursts, the way a ringing phone
  // does, then goes still; a small blood light beats beside it.
  Item {
    anchors.fill: parent
    visible: root.kind === "phone"
    transformOrigin: Item.Center
    readonly property real ring: root.moving ? Math.max(0, Math.sin(root.t * 2.4 - 0.4) - 0.35) / 0.65 : 0
    rotation: ring * 7 * Math.sin(root.t * 46)
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
      // the handset: a long curved grip with a cup at each end
      ShapePath {
        strokeColor: root.line; strokeWidth: 2.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
        startX: root.cx - 10 * root.u; startY: root.cy - 4 * root.u
        PathCubic {
          x: root.cx + 10 * root.u; y: root.cy - 4 * root.u
          control1X: root.cx - 6 * root.u; control1Y: root.cy - 11 * root.u
          control2X: root.cx + 6 * root.u; control2Y: root.cy - 11 * root.u
        }
      }
      ShapePath {
        strokeColor: root.line; strokeWidth: 1.2; fillColor: root.ink; joinStyle: ShapePath.RoundJoin
        PathPolyline { path: [root.pt(-13, -4), root.pt(-7, -4), root.pt(-6.4, 1.6), root.pt(-12.4, 1.6), root.pt(-13, -4)] }
      }
      ShapePath {
        strokeColor: root.line; strokeWidth: 1.2; fillColor: root.ink; joinStyle: ShapePath.RoundJoin
        PathPolyline { path: [root.pt(13, -4), root.pt(7, -4), root.pt(6.4, 1.6), root.pt(12.4, 1.6), root.pt(13, -4)] }
      }
      // the coiled cord hangs from the middle
      ShapePath {
        strokeColor: root.soft; strokeWidth: 1.1; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        PathPolyline {
          path: {
            var out = []
            for (var i = 0; i <= 60; i++) {
              var f = i / 60, a = f * 5 * 2 * Math.PI
              out.push(root.pt(Math.cos(a) * 3 + Math.sin(f * 6) * 0.6, -5 + f * 15 + Math.sin(a) * 1.6))
            }
            return out
          }
        }
      }
    }
  }
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "phone"
    opacity: root.moving ? 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(root.t * 9)) : 1
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: root.blood
      startX: root.cx + 1.9 * root.u; startY: root.cy - 9.6 * root.u
      PathAngleArc { centerX: root.cx; centerY: root.cy - 9.6 * root.u; radiusX: 1.9 * root.u; radiusY: 1.9 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  // ---------------------------------------------------------------- mind: AI usage
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "mind"
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"; joinStyle: ShapePath.RoundJoin
      startX: root.cx; startY: root.cy - 10 * root.u
      PathCubic { x: root.cx - 12 * root.u; y: root.cy - 1 * root.u; control1X: root.cx - 8 * root.u; control1Y: root.cy - 12 * root.u; control2X: root.cx - 14 * root.u; control2Y: root.cy - 8 * root.u }
      PathCubic { x: root.cx; y: root.cy + 10 * root.u; control1X: root.cx - 11 * root.u; control1Y: root.cy + 8 * root.u; control2X: root.cx - 5 * root.u; control2Y: root.cy + 11 * root.u }
    }
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"; joinStyle: ShapePath.RoundJoin
      startX: root.cx; startY: root.cy - 10 * root.u
      PathCubic { x: root.cx + 12 * root.u; y: root.cy - 1 * root.u; control1X: root.cx + 8 * root.u; control1Y: root.cy - 12 * root.u; control2X: root.cx + 14 * root.u; control2Y: root.cy - 8 * root.u }
      PathCubic { x: root.cx; y: root.cy + 10 * root.u; control1X: root.cx + 11 * root.u; control1Y: root.cy + 8 * root.u; control2X: root.cx + 5 * root.u; control2Y: root.cy + 11 * root.u }
    }
  }
  // the folds light up in turn, as if something were thinking
  Repeater {
    model: [-1, 1]
    Shape {
      required property int modelData
      required property int index
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
      visible: root.kind === "mind"
      opacity: root.moving ? 0.25 + 0.75 * (0.5 + 0.5 * Math.sin(root.t * 3 + index * 3.14)) : 0.6
      ShapePath {
        strokeColor: root.soft; strokeWidth: 1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
        PathPolyline { path: [root.pt(modelData * 3, -6), root.pt(modelData * 7, -3), root.pt(modelData * 4, 0), root.pt(modelData * 8, 3)] }
      }
    }
  }
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "mind"
    scale: root.moving ? 1 + 0.5 * Math.max(0, Math.sin(root.t * 3)) : 1
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: root.blood
      startX: root.cx + 1.8 * root.u; startY: root.cy + 2 * root.u
      PathAngleArc { centerX: root.cx; centerY: root.cy + 2 * root.u; radiusX: 1.8 * root.u; radiusY: 1.8 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  // ---------------------------------------------------------------- the sky
  Item {
    anchors.fill: parent
    visible: ["sun", "suncloud"].indexOf(root.kind) >= 0
    rotation: root.moving ? root.t * 8 : 0
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
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
    }
  }
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: ["sun", "suncloud"].indexOf(root.kind) >= 0
    ShapePath {
      strokeColor: root.line; strokeWidth: 1.4; fillColor: "transparent"
      PathPolyline { path: root.inked(0, 0, 6, 0, Math.PI * 2, 30, 3) }
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
  }
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "moon"
    opacity: root.moving ? 0.4 + 0.6 * (0.5 + 0.5 * Math.sin(root.t * 2.6)) : 1
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1; fillColor: root.blood
      startX: root.cx + 9 * root.u + 1.6 * root.u; startY: root.cy - 6 * root.u
      PathAngleArc { centerX: root.cx + 9 * root.u; centerY: root.cy - 6 * root.u; radiusX: 1.6 * root.u; radiusY: 1.6 * root.u; startAngle: 0; sweepAngle: 360 }
    }
  }

  // a cloud, drifting a little, with what falls from it
  Item {
    anchors.fill: parent
    visible: ["cloud", "rain", "storm", "snow"].indexOf(root.kind) >= 0
    x: root.moving ? 1.6 * Math.sin(root.t * 0.9) : 0
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
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
    }
  }
  // rain and snow fall; the storm flashes
  Item {
    anchors.fill: parent
    visible: root.kind === "rain" || root.kind === "snow"
    y: root.moving ? ((root.t * 9) % 6) - 3 : 0
    opacity: root.moving ? 1 - (((root.t * 9) % 6) / 6) * 0.8 : 1
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      antialiasing: true
      ShapePath {
        strokeColor: root.blood; strokeWidth: 1.3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
        PathMultiline {
          paths: root.kind === "rain" ? [
            [root.pt(-7, 5), root.pt(-9, 11)], [root.pt(-1, 5), root.pt(-3, 11)],
            [root.pt(5, 5), root.pt(3, 11)], [root.pt(10, 5), root.pt(8, 11)]] : []
        }
      }
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
  }
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true
    visible: root.kind === "storm"
    opacity: root.moving ? (Math.sin(root.t * 3.7) > 0.55 || Math.sin(root.t * 9.1) > 0.92 ? 1 : 0.2) : 1
    ShapePath {
      strokeColor: root.blood; strokeWidth: 1.3; fillColor: "transparent"
      capStyle: ShapePath.RoundCap; joinStyle: ShapePath.MiterJoin
      PathPolyline { path: [root.pt(2, 3), root.pt(-3, 8), root.pt(1, 8), root.pt(-3, 13)] }
    }
  }

  // fog: layers that do not quite line up, sliding past each other
  Repeater {
    model: [{ "y": -7, "x0": -12, "c1": -6, "c2": 2, "dx": 20, "col": 0, "ph": 0 },
            { "y": 0, "x0": -8, "c1": -2, "c2": 6, "dx": 20, "col": 0, "ph": 2 },
            { "y": 7, "x0": -12, "c1": -6, "c2": 0, "dx": 18, "col": 1, "ph": 4 }]
    Item {
      required property var modelData
      anchors.fill: parent
      visible: root.kind === "fog"
      x: root.moving ? 2.2 * Math.sin(root.t * 0.8 + modelData.ph) : 0
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        ShapePath {
          strokeColor: modelData.col ? root.blood : root.line; strokeWidth: 1.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
          startX: root.cx + modelData.x0 * root.u; startY: root.cy + modelData.y * root.u
          PathCubic {
            x: root.cx + (modelData.x0 + modelData.dx) * root.u; y: root.cy + modelData.y * root.u
            control1X: root.cx + modelData.c1 * root.u; control1Y: root.cy + (modelData.y - 3) * root.u
            control2X: root.cx + modelData.c2 * root.u; control2Y: root.cy + (modelData.y + 3) * root.u
          }
        }
      }
    }
  }
}
