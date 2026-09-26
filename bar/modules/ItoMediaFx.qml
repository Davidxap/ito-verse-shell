import QtQuick

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
    // Not a clean mathematical curve: the wobble is what tells this from a logo. A third, faint arm keeps
    // it from ever quite settling into a simple two-arm pattern, and a few dark growths sit on the ink the
    // way the curse marks skin in Uzumaki -- small, uneven, not decoration.
    function paintSpiral(ctx, w, h) {
      var cx = w / 2, cy = h / 2, R = Math.max(w, h) * 0.62
      var spin = root.t * 0.9 + root.surge * 3
      var sx = w / Math.max(w, h) * 1.6
      var arms = [
        { off: 0, width: 3.0, col: rgba(root.blood, 0.8 * root.shown) },
        { off: Math.PI, width: 2.2, col: rgba(root.bone, 0.34 * root.shown) },
        { off: Math.PI * 0.55, width: 1.2, col: rgba(root.bone, 0.16 * root.shown) }
      ]
      for (var arm = 0; arm < arms.length; arm++) {
        ctx.beginPath()
        var growths = []
        for (var i = 0; i <= 170; i++) {
          var u = i / 170
          var wob = Math.sin(u * 19 + arm * 3 + root.t * 1.3) * (1 - u) * 0.05
          var a = spin + arms[arm].off + u * 4.4 * Math.PI + wob
          var r = u * R * (1 + 0.02 * Math.sin(u * 11 - root.t))
          var x = cx + Math.cos(a) * r * sx
          var y = cy + Math.sin(a) * r * 0.9
          if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
          if (arm === 0 && i > 20 && i % 27 === 0) growths.push([x, y, 1.2 + hash(i + arm) * 1.6])
        }
        ctx.lineWidth = arms[arm].width + root.surge * 1.2
        ctx.strokeStyle = arms[arm].col
        ctx.stroke()
        for (var gg = 0; gg < growths.length; gg++) {
          ctx.beginPath(); ctx.arc(growths[gg][0], growths[gg][1], growths[gg][2], 0, Math.PI * 2)
          ctx.fillStyle = rgba(root.blood, 0.55 * root.shown); ctx.fill()
        }
      }
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
        var src = eyeArt + style + (red ? "-red.png" : ".png")
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
