import QtQuick
import Quickshell
import Quickshell.Io

// What moves behind the media controls while something plays. One kind is chosen on the Effects page:
//
//   blood    a slosh of blood that rises and falls with a beat
//   spiral   the Uzumaki spiral, turning
//   eyes     a row of eyes that open and shut, watching
//   fog      Silent Hill's fog, drifting slowly across
//   static   the pocket radio's static, hissing and tearing
//   custom   the user's own picture or GIF (Effects page -> Choose your own), drawn behind the buttons
//
// The effect eases in when playback starts and drains away when it stops. It is drawn on one Canvas that repaints
// only while there is something to see, so an idle bar costs nothing. `pulse()` throws it up for a moment (a new track).
Item {
  id: root

  property string kind: "blood"
  property bool active: false
  property color blood: "#c4162a"
  property color bone: "#c7ccd1"
  property real radius: height / 2
  property real speed: 1
  property url customSource: ""        // the user's own picture or GIF, for kind "custom"

  // Your own eye: put eyes.png and eyes-red.png (the same 640 x 246 shape as the ones in ito-art/eyefx) in
  // ~/.config/ito/eyefx/ and the Eye effect draws those instead of the built-in ones.
  readonly property string userEyeDir: Quickshell.env("HOME") + "/.config/ito/eyefx/"
  property bool hasUserEyes: false
  FileView {
    path: root.userEyeDir + "eyes.png"
    printErrors: false
    onLoaded: root.hasUserEyes = true
    onLoadFailed: root.hasUserEyes = false
  }

  property real surge: 0
  function pulse() { surgeAnim.restart() }

  property real shown: active ? 1 : 0
  Behavior on shown {
    NumberAnimation {
      duration: root.active ? 900 : 1500
      easing.type: Easing.BezierSpline
      easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    }
  }

  property real t: 0
  readonly property bool running: shown > 0.004

  NumberAnimation { id: surgeAnim; target: root; property: "surge"; from: 1; to: 0; duration: 1800; easing.type: Easing.OutCubic }

  FrameAnimation {
    running: root.running && root.kind !== "custom"
    onTriggered: {
      root.t += frameTime * root.speed
      canvas.requestPaint()
    }
  }

  // The user's own picture or GIF. It only plays while it is showing. It is cut to a rectangle set in from the pill's
  // round ends (no shader mask, so it costs nothing extra and works on any renderer), and shown a little transparent.
  Item {
    id: customFx
    anchors.fill: parent
    anchors.leftMargin: root.radius * 0.45
    anchors.rightMargin: root.radius * 0.45
    clip: true
    visible: root.kind === "custom" && root.running && root.customSource.toString() !== ""

    AnimatedImage {
      anchors.fill: parent
      source: customFx.visible ? root.customSource : ""
      fillMode: Image.PreserveAspectCrop
      playing: customFx.visible
      smooth: true
      opacity: 0.62 * root.shown
    }
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    visible: root.running && root.kind !== "custom"
    antialiasing: true

    function clipPill(ctx, w, h, r) {
      r = Math.min(r, h / 2, w / 2)
      ctx.beginPath()
      ctx.moveTo(r, 0); ctx.lineTo(w - r, 0); ctx.arc(w - r, r, r, -Math.PI / 2, 0)
      ctx.lineTo(w, h - r); ctx.arc(w - r, h - r, r, 0, Math.PI / 2)
      ctx.lineTo(r, h); ctx.arc(r, h - r, r, Math.PI / 2, Math.PI)
      ctx.lineTo(0, r); ctx.arc(r, r, r, Math.PI, Math.PI * 1.5)
      ctx.closePath()
    }
    function rgba(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // ------------------------------------------------------------------ blood
    function wave(ctx, w, h, base, amp, phase, aTop, aBottom) {
      var t = root.t
      ctx.beginPath(); ctx.moveTo(0, h)
      for (var x = 0; x <= w; x += 3)
        ctx.lineTo(x, base + Math.sin(x * 0.11 + t * 2.1 + phase) * amp + Math.sin(x * 0.23 - t * 1.4 + phase * 1.7) * amp * 0.55)
      ctx.lineTo(w, h); ctx.closePath()
      var b = root.blood
      var g = ctx.createLinearGradient(0, base - amp, 0, h)
      g.addColorStop(0, rgba(b, aTop)); g.addColorStop(1, Qt.rgba(b.r * 0.5, b.g * 0.45, b.b * 0.45, aBottom))
      ctx.fillStyle = g; ctx.fill()
    }
    function paintBlood(ctx, w, h) {
      var beat = 0.72 + 0.28 * Math.sin(root.t * 2.6) * Math.sin(root.t * 0.85 + 1.0)
      var amp = h * (0.05 + 0.05 * beat) + h * 0.16 * root.surge
      var fill = Math.min(0.95, 0.42 * root.shown + root.surge * 0.22)
      var base = h * (1 - fill)
      wave(ctx, w, h, base + h * 0.05, amp * 0.8, 2.0, 0.42, 0.62)
      wave(ctx, w, h, base, amp, 0.0, 0.66, 0.92)
    }

    // ------------------------------------------------------------------ spiral
    // Uzumaki's swirl: one heavy ink line winding in tight, even rings, thin at the centre and swelling as it
    // goes out, the way a pen leans into the stroke. Blood is a second arm that creeps out from the centre and
    // stops part-way, as the curse does. Each arm is one filled ribbon (a single path), not hundreds of strokes,
    // so it stays cheap while it turns.
    function ribbon(ctx, cx, cy, R, sx, sy, spin, turns, uMax, widthOf, colour) {
      var steps = 260, inner = []
      ctx.beginPath()
      for (var i = 0; i <= steps; i++) {
        var u = i / steps * uMax
        var a = spin + u * turns * 2 * Math.PI
        var r = u * R
        var hw = widthOf(u) * 0.5
        var cs = Math.cos(a), sn = Math.sin(a)
        var xo = cx + cs * (r + hw) * sx, yo = cy + sn * (r + hw) * sy
        if (i === 0) ctx.moveTo(xo, yo); else ctx.lineTo(xo, yo)
        inner.push(cx + cs * Math.max(0, r - hw) * sx, cy + sn * Math.max(0, r - hw) * sy)
      }
      for (var j = inner.length - 2; j >= 0; j -= 2) ctx.lineTo(inner[j], inner[j + 1])
      ctx.closePath()
      ctx.fillStyle = colour
      ctx.fill()
    }

    function paintSpiral(ctx, w, h) {
      var cx = w / 2, cy = h / 2, R = Math.max(w, h) * 0.66
      var spin = root.t * 0.7 + root.surge * 3
      var sx = w / Math.max(w, h) * 1.7, sy = 0.9
      var swell = 1 + root.surge * 0.5
      // the ink: thin at the middle, heavy outside, drawn to a point at its end
      ribbon(ctx, cx, cy, R, sx, sy, spin, 6.5, 1.0,
             function(u) { return (0.9 + 2.3 * Math.pow(u, 0.75)) * swell * (u > 0.94 ? (1 - u) / 0.06 : 1) },
             rgba(root.bone, 0.8 * root.shown))
      // the blood: the same turn, half a ring behind, only part of the way
      ribbon(ctx, cx, cy, R, sx, sy, spin + Math.PI, 6.5, 0.7,
             function(u) { return (1.1 + 1.4 * u) * swell * (u > 0.62 ? (0.7 - u) / 0.08 : 1) },
             rgba(root.blood, 0.85 * root.shown))
    }

    // ------------------------------------------------------------------ eyes
    function frac(v) { return v - Math.floor(v) }
    function hash(v) { return frac(Math.sin(v * 12.9898 + 78.233) * 43758.5453) }

    // Mostly open, and blinks the way an eye actually does: shut fast, held a breath, open fast — not a slow
    // continuous oscillation, which is what read as mechanical. Every eye keeps its own rhythm.
    function eyeOpen(seed, t) {
      var period = 2.6 + 2.4 * hash(seed)
      var phase = frac((t + seed * 7) / period)
      var toEdge = Math.min(phase, 1 - phase) * period
      var blink = Math.exp(-(toEdge * toEdge) / 0.012)
      return Math.max(0.05, 1 - 0.95 * blink)
    }

    // The eye holds a look, then darts to a new one — a saccade, not a smooth sweep — and holds again.
    function saccade(seed, t) {
      var period = 1.3 + 1.3 * hash(seed + 4.1)
      var cycle = (t + seed * 5) / period
      var step = Math.floor(cycle)
      var target = hash(step * 3.7 + seed * 9.2) * 2 - 1
      var eased = Math.min(1, frac(cycle) / 0.14)
      return target * eased
    }

    // "Eyes" is an original watching eye with a spiral pupil (scripts/eyeart.py); "Angel" is the fine-line eye of the emblem (a ring and a dot in an
    // almond). Both are sprites (scripts/gen-eyefx.py), only made to move: a blink is the lid coming down (the picture
    // squashed from top and bottom), a look is a small sideways start and stop, and when the music surges some
    // of them turn bloodshot.
    readonly property url eyeArt: Qt.resolvedUrl("ito-art/eyefx/")
    readonly property url fogArt: Qt.resolvedUrl("ito-art/misc/fog.png")
    readonly property url userEyeArt: "file://" + root.userEyeDir
    Connections {
      target: root
      function onHasUserEyesChanged() {
        if (!root.hasUserEyes) return
        canvas.loadImage(canvas.userEyeArt + "eyes.png"); canvas.loadImage(canvas.userEyeArt + "eyes-red.png")
        canvas.requestPaint()
      }
    }
    Component.onCompleted: {
      loadImage(eyeArt + "eyes.png"); loadImage(eyeArt + "eyes-red.png")
      loadImage(fogArt)
    }
    onImageLoaded: requestPaint()

    function paintEyes(ctx, w, h, style) {
      var eh = h * 0.98, ew = eh * 2.6                      // the picture is 2.6 : 1
      var n = 1                                             // a single eye, in the middle
      var gap = w / n
      for (var k = 0; k < n; k++) {
        var seed = k * 2.37 + 1
        var open = eyeOpen(seed, root.t)
        var look = saccade(seed, root.t) * gap * 0.03
        var red = root.surge > 0.25 && k % 2 === 0
        var name = style + (red ? "-red.png" : ".png")
        var src = (root.hasUserEyes && isImageLoaded(userEyeArt + name)) ? userEyeArt + name : eyeArt + name
        if (!isImageLoaded(src)) continue
        ctx.save()
        ctx.globalAlpha = Math.min(1, 0.95 * root.shown)
        ctx.translate(gap * (k + 0.5) + look, h / 2)
        ctx.scale(1, 0.12 + 0.88 * open)
        ctx.drawImage(src, -ew / 2, -eh / 2, ew, eh)
        ctx.restore()
      }
    }

    // ------------------------------------------------------------------ fog
    // A texture of layered noise (scripts/gen-fog.py), not radial blobs: two copies drift at different speeds and
    // heights so the streaks slide across each other the way a bank of fog does, with the red sun the game hides
    // in it. Nothing else: no grain on top.
    function paintFog(ctx, w, h) {
      if (isImageLoaded(fogArt)) {
        var th = Math.round(h * 1.7), tw = Math.round(Math.round(h * 1.7) * 4.8)
        for (var layer = 0; layer < 2; layer++) {
          var speed = layer === 0 ? 6 : 11, x0 = -((root.t * speed + layer * tw * 0.5) % tw)
          var y = (layer === 0 ? -h * 0.35 : -h * 0.55) + Math.sin(root.t * 0.25 + layer * 2) * h * 0.06
          ctx.globalAlpha = (layer === 0 ? 0.34 : 0.24) * (1 + 0.5 * root.surge) * root.shown
          // whole-pixel tiles: butted at fractional positions they leave a hairline where they meet
          for (var x = Math.round(x0); x < w; x += Math.round(tw)) ctx.drawImage(fogArt, x, Math.round(y), Math.round(tw), Math.round(th))
        }
        ctx.globalAlpha = 1
      }
      var sx = w * (0.72 + 0.04 * Math.sin(root.t * 0.3))
      var sg = ctx.createRadialGradient(sx, h * 0.55, 0, sx, h * 0.55, h * 0.95)
      sg.addColorStop(0, rgba(root.blood, 0.26 * root.shown)); sg.addColorStop(1, rgba(root.blood, 0))
      ctx.fillStyle = sg; ctx.fillRect(0, 0, w, h)
    }

    // ------------------------------------------------------------------ static
    // Kept light: a few short thin lines that change in bursts, one hairline of blood now and then.
    function paintStatic(ctx, w, h) {
      var step = Math.floor(root.t * 10)
      function rnd(i) { var v = Math.sin((step + 1) * 12.9898 + i * 78.233) * 43758.5453; return v - Math.floor(v) }
      for (var i = 0; i < 4; i++) {
        var y = rnd(i) * h, len = w * (0.1 + rnd(i + 30) * 0.3), x = rnd(i + 60) * (w - len)
        ctx.fillStyle = rgba(root.bone, (0.12 + 0.2 * rnd(i + 90)) * root.shown)
        ctx.fillRect(x, y, len, 1)
      }
      for (var j = 0; j < 8; j++) {
        ctx.fillStyle = rgba(root.bone, 0.12 * rnd(j + 200) * root.shown)
        ctx.fillRect(rnd(j + 300) * w, rnd(j + 400) * h, 1.5, 1.5)
      }
      var tear = (root.t * 0.4) % 1
      if (tear < 0.04 + root.surge * 0.2) {
        ctx.fillStyle = rgba(root.blood, 0.4 * root.shown)
        ctx.fillRect(0, h * (0.2 + rnd(500) * 0.6), w, 1)
      }
    }

    onPaint: {
      var ctx = getContext("2d")
      var w = width, h = height
      ctx.clearRect(0, 0, w, h)
      if (root.shown <= 0.004 || w < 4 || h < 4) return
      ctx.save()
      clipPill(ctx, w, h, root.radius)
      ctx.clip()
      if (root.kind === "spiral") paintSpiral(ctx, w, h)
      else if (root.kind === "eyes") paintEyes(ctx, w, h, "eyes")
      else if (root.kind === "fog") paintFog(ctx, w, h)
      else if (root.kind === "static") paintStatic(ctx, w, h)
      else paintBlood(ctx, w, h)
      ctx.restore()
    }
  }
}
