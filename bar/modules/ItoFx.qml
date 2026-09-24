import QtQuick

// Every living effect of a mark, in one place: the menu mark, the seal and the veins all use it.
//
// One clock (`t`) drives everything, and one envelope (`amount`) says how much of the effect is on. Switching
// on or off only moves the envelope, so an effect always eases in and settles back to rest, whatever it is.
// The clock runs only while something is animating: a hover-only effect costs nothing while the pointer is
// elsewhere.
//
//   kind    none · spin · pulse · breathe · heartbeat · flicker · sway · glitch · ripple
//   active  whether the effect is on right now (a hover, or true for "always")
Item {
  id: root

  property string kind: "none"
  property bool active: false
  property real speed: 1
  property real strength: 1
  property color color: "#c4162a"
  // Set to keep a ring or bloom drawn under the content for ripple; harmless for the other kinds.
  property real ringSize: 1.9

  default property alias content: holder.data

  readonly property bool running: kind !== "none" && (active || amount > 0.002)

  property real amount: (active && kind !== "none") ? 1 : 0
  Behavior on amount {
    NumberAnimation {
      duration: root.amount < 0.5 ? 380 : 700
      easing.type: Easing.BezierSpline
      easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    }
  }

  property real t: 0
  property real angle: 0

  FrameAnimation {
    running: root.running
    onTriggered: {
      var dt = frameTime
      root.t += dt * root.speed
      if (root.kind === "spin") {
        // one turn in seven seconds at speed 1; the envelope makes it wind up and wind down
        root.angle += dt * root.speed * 51.4 * root.amount
      }
      if (!root.active) {
        // upright again: ease to the nearest whole turn once the winding-down is nearly done
        var rest = Math.round(root.angle / 360) * 360
        root.angle += (rest - root.angle) * (1 - Math.exp(-dt * 6 * (1 - root.amount)))
      }
    }
  }

  function bump(p, centre, width) {
    var d = (p - centre) / width
    return Math.exp(-d * d)
  }
  readonly property real k: strength
  readonly property real a: amount

  // -- the wave forms ------------------------------------------------------------------------------------
  readonly property real cycle: 0.5 - 0.5 * Math.cos(t * 2 * Math.PI / 1.1)
  readonly property real slow: 0.5 - 0.5 * Math.cos(t * 2 * Math.PI / 2.2)
  readonly property real beatPhase: (t % 1.25) / 1.25
  readonly property real beat: bump(beatPhase, 0.07, 0.045) + 0.7 * bump(beatPhase, 0.25, 0.055)
  readonly property real flickerGate: Math.max(0, Math.sin(t * 0.9 + 1) - 0.35) / 0.65
  readonly property real flickerNoise: Math.max(0, Math.sin(t * 43) * Math.sin(t * 17.3) + Math.sin(t * 7.7) * 0.6)
  readonly property bool glitchOn: (t % 2.4) < 0.14

  Item {
    id: holder
    anchors.fill: parent
    transformOrigin: Item.Center

    rotation: root.kind === "spin" ? root.angle
            : root.kind === "sway" ? 9 * root.k * root.a * Math.sin(root.t * 2 * Math.PI / 2.6)
            : 0
    scale: root.kind === "pulse" ? 1 + 0.10 * root.k * root.a * root.cycle
         : root.kind === "breathe" ? 1 + 0.045 * root.k * root.a * root.slow
         : root.kind === "heartbeat" ? 1 + 0.15 * root.k * root.a * root.beat
         : 1
    opacity: root.kind === "breathe" ? 1 - 0.38 * root.k * root.a * root.slow
           : root.kind === "flicker" ? 1 - Math.min(0.9, 0.9 * root.a * root.flickerGate * root.flickerNoise * root.k)
           : root.kind === "glitch" ? (root.glitchOn ? 1 - 0.3 * root.a : 1)
           : 1
    transform: Translate {
      x: root.kind === "glitch" && root.glitchOn ? Math.round(Math.sin(root.t * 97) * 2.2 * root.k * root.a) : 0
    }
  }

  // ripple: a ring leaves the mark and fades out, again and again
  Rectangle {
    visible: root.kind === "ripple" && root.amount > 0.002
    anchors.centerIn: parent
    width: parent.width
    height: parent.height
    radius: width / 2
    color: "transparent"
    border.width: 1.4
    border.color: root.color
    readonly property real p: (root.t / 1.8) % 1
    scale: 1 + (root.ringSize - 1) * p * root.k
    opacity: (1 - p) * (1 - p) * 0.6 * root.amount
    z: -1
  }
}
