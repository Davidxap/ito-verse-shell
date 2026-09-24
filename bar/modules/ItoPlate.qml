import QtQuick

// The bar's plate: near-black with blood veins in patches, cut from the design mock-up.
//
// Painted in one Canvas with a rounded clip, so it needs no shader and looks the same in the
// shell and in the offscreen lab. Every layer is a property, so the surface is customizable:
//
//   veins   the mock-up strip, mirrored and tiled          (opacity 0..1)
//   wood    the Uzumaki plank: grain winding into knots    (opacity 0..1)
//   grain   press dirt over the whole plate, drawn wide      (opacity 0..1)
//   tone    a halftone screen, barely there                (opacity 0..1)
//   border  the pale line round the edge
//   lift    how far the base is lifted off pure black, for a printed-paper plate
//
// The centre is kept calmer than the ends by `calm`, a dark veil that fades in from both sides,
// so icons and numerals stay legible where the veins would otherwise run behind them.
Canvas {
  id: root

  property url artBase: ""                // folder holding surface/veins.png, misc/grain.png ...
  property int radius: 20
  property bool flatTop: false            // a bar flush with the screen's top edge keeps its top corners square
  property real veins: 0.6
  property real wood: 0
  property real grain: 0.10
  property real tone: 0.06
  property real calm: 0.4
  property bool border: true
  property bool torn: false               // the border reads as hand-torn paper instead of a ruled line
  property real lift: 0
  property real plate: 1                  // whole-plate opacity, for the glass look
  property real fog: 0                    // Silent Hill's fog, always drifting across the plate, very faint
  // The shell's colours (an ItoConfig). The plate is always painted in the shell's own bone and crimson;
  // under a theme the whole plate then goes through the theme shader, which moves both onto the theme.
  property var palette: null
  readonly property color bone: "#c7ccd1"
  property color ink: "#050607"

  antialiasing: true
  opacity: plate

  // Under a theme the plate is recoloured by the theme shader: its bone to the foreground, its blood to the
  // accent.
  layer.enabled: !!palette && palette.tinted
  layer.effect: ItoThemeEffect { palette: root.palette }
  visible: plate > 0.01

  Image { id: veinsProbe; source: root.artBase + "surface/veins.png"; visible: false }
  Image { id: woodProbe; source: root.artBase + "surface/wood.png"; visible: false }
  Image { id: dirtProbe; source: root.artBase + "surface/dirt.png"; visible: false }

  readonly property url veinsSrc: artBase + "surface/veins.png"
  readonly property url woodSrc: artBase + "surface/wood.png"
  readonly property url grainSrc: artBase + "surface/dirt.png"
  readonly property url toneSrc: artBase + "surface/tone.png"

  Component.onCompleted: {
    loadImage(veinsSrc); loadImage(woodSrc); loadImage(grainSrc); loadImage(toneSrc)
  }
  onImageLoaded: requestPaint()
  Connections { target: veinsProbe; function onStatusChanged() { root.requestPaint() } }
  Connections { target: woodProbe; function onStatusChanged() { root.requestPaint() } }
  Connections { target: dirtProbe; function onStatusChanged() { root.requestPaint() } }
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onVeinsChanged: requestPaint()
  onWoodChanged: requestPaint()
  onGrainChanged: requestPaint()
  onToneChanged: requestPaint()
  onCalmChanged: requestPaint()
  onBorderChanged: requestPaint()
  onTornChanged: requestPaint()
  onFlatTopChanged: requestPaint()
  onRadiusChanged: requestPaint()
  onLiftChanged: requestPaint()
  onFogChanged: requestPaint()

  // Fog lives on its own Canvas so its low-frequency repaint never has to redo the veins/grain/border tiling
  // underneath -- repainting the whole plate for a wisp of fog was most of what fog actually cost.
  Canvas {
    id: fogCanvas
    anchors.fill: parent
    visible: root.fog > 0.001
    antialiasing: true

    Timer {
      interval: 260
      running: fogCanvas.visible
      repeat: true
      onTriggered: fogCanvas.requestPaint()
    }

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      if (root.fog <= 0.001 || width < 4 || height < 4) return
      ctx.save()
      root.roundedPath(ctx, 0, 0, width, height, root.flatTop ? 0 : root.radius, root.radius)
      ctx.clip()
      var t = Date.now() / 1000
      for (var wi = 0; wi < 2; wi++) {
        var speed = 11 + wi * 4
        var span = width + height * 2
        var fx = ((t * speed + wi * width * 0.6) % span) - height
        var fy = height * (0.3 + 0.4 * wi)
        var fr = height * (1.6 + wi * 0.5)
        var fgrad = ctx.createRadialGradient(fx, fy, 0, fx, fy, fr)
        fgrad.addColorStop(0, Qt.rgba(root.bone.r, root.bone.g, root.bone.b, root.fog))
        fgrad.addColorStop(1, Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0))
        ctx.fillStyle = fgrad
        // Only the wisp's own bounding box, not the whole plate: the gradient is already 0 past its
        // radius, so filling further is wasted work on every one of these low-frequency repaints.
        ctx.fillRect(fx - fr, Math.max(0, fy - fr), fr * 2, Math.min(height, fr * 2))
      }
      ctx.restore()
    }
  }

  // Built from true arcs: arcTo() draws a stray vertical stroke when the radius is half the height.
  // The top and bottom corners can differ, so a bar flush with the screen edge can keep its top square.
  function roundedPath(ctx, x, y, w, h, rTop, rBottom) {
    var t = Math.max(0, Math.min(rTop, w / 2, h / 2))
    var b = Math.max(0, Math.min(rBottom === undefined ? rTop : rBottom, w / 2, h / 2))
    ctx.beginPath()
    ctx.moveTo(x + t, y)
    ctx.lineTo(x + w - t, y)
    if (t > 0) ctx.arc(x + w - t, y + t, t, -Math.PI / 2, 0)
    ctx.lineTo(x + w, y + h - b)
    if (b > 0) ctx.arc(x + w - b, y + h - b, b, 0, Math.PI / 2)
    ctx.lineTo(x + b, y + h)
    if (b > 0) ctx.arc(x + b, y + h - b, b, Math.PI / 2, Math.PI)
    ctx.lineTo(x, y + t)
    if (t > 0) ctx.arc(x + t, y + t, t, Math.PI, Math.PI * 1.5)
    ctx.closePath()
  }

  // Tile an image across the plate at its own height, at a given opacity.
  function tile(ctx, src, alpha, tileH) {
    if (alpha <= 0 || !isImageLoaded(src)) return
    ctx.globalAlpha = alpha
    var h = tileH > 0 ? tileH : height
    var probe = src === veinsSrc ? veinsProbe
      : src === woodSrc ? woodProbe : src === grainSrc ? dirtProbe : null
    // Whole pixels: a fractional tile width leaves a hairline seam between tiles, which on a fine pattern shows
    // as stripes across the plate. The screentone tile wraps exactly, so it is drawn at a whole fraction of itself.
    h = Math.round(h)
    var w = Math.max(1, Math.round(probe ? h * probe.implicitWidth / Math.max(1, probe.implicitHeight) : h))
    for (var x = 0; x < width; x += w) ctx.drawImage(src, x, 0, w, h)
    ctx.globalAlpha = 1
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    ctx.save()
    // Edge to edge, not inset: an inset fill leaves a half-transparent seam where the plate is meant to touch the
    // screen's edge exactly (a flush top bar, or the flush side of a vertical one), and the wallpaper bleeds through
    // that seam as a thin line. The half-pixel inset a crisp stroke wants is applied only to the border below.
    roundedPath(ctx, 0, 0, width, height, flatTop ? 0 : radius, radius)
    ctx.clip()

    ctx.fillStyle = lift > 0 ? Qt.rgba(ink.r + lift, ink.g + lift, ink.b + lift, 1) : ink
    ctx.fillRect(0, 0, width, height)
    tile(ctx, woodSrc, wood, height)
    if (wood > 0) {
      // The grain is kept to the ends of the plate, as the layer promises: over the middle it would read as scan
      // lines behind the widgets, so the plate colour is laid back over it and only the two ends keep the wood.
      var fade = ctx.createLinearGradient(0, 0, width, 0)
      var base = lift > 0 ? Qt.rgba(ink.r + lift, ink.g + lift, ink.b + lift, 1) : ink
      var covered = Qt.rgba(base.r, base.g, base.b, 0.94)
      var open = Qt.rgba(base.r, base.g, base.b, 0)
      fade.addColorStop(0, open); fade.addColorStop(0.16, covered); fade.addColorStop(0.84, covered); fade.addColorStop(1, open)
      ctx.fillStyle = fade
      ctx.fillRect(0, 0, width, height)
    }
    tile(ctx, veinsSrc, veins, height)
    // Scaled well past the bar height: at tile size the dirt repeats every 40px and reads as a
    // pattern instead of as dirt.
    tile(ctx, toneSrc, tone, 64)
    tile(ctx, grainSrc, grain, height * 4.5)

    // the calm veil: darkest in the middle, gone at the ends
    if (calm > 0) {
      var g = ctx.createLinearGradient(0, 0, width, 0)
      var c = Qt.rgba(ink.r, ink.g, ink.b, calm)
      var clear = Qt.rgba(ink.r, ink.g, ink.b, 0)
      g.addColorStop(0, clear); g.addColorStop(0.22, c); g.addColorStop(0.78, c); g.addColorStop(1, clear)
      ctx.fillStyle = g
      ctx.fillRect(0, 0, width, height)
    }
    ctx.restore()

    if (border && torn) {
      // A torn-paper edge: the same clean path (nothing about the plate's shape changes), but broken into an
      // irregular dash instead of one ruled line, inked in three offset passes of different weight -- at a
      // 1px line a pixel of jitter alone is invisible; a broken line reads as torn at any size.
      var passes = [[-1.6, 1.1, 1.6, 0.42], [1.3, -0.9, 1.1, 0.3], [-0.4, -1.4, 0.8, 0.22]]
      for (var s = 0; s < passes.length; s++) {
        var p = passes[s]
        ctx.save()
        ctx.translate(p[0], p[1])
        ctx.setLineDash([5, 2, 2, 2, 7, 1, 3, 3])
        ctx.lineDashOffset = s * 3
        roundedPath(ctx, 0.75, 0.75, width - 1.5, height - 1.5, flatTop ? 0 : radius, radius)
        ctx.strokeStyle = Qt.rgba(bone.r, bone.g, bone.b, p[3])
        ctx.lineWidth = p[2]
        ctx.stroke()
        ctx.restore()
      }
    } else if (border) {
      roundedPath(ctx, 0.75, 0.75, width - 1.5, height - 1.5, flatTop ? 0 : radius, radius)
      ctx.strokeStyle = Qt.rgba(bone.r, bone.g, bone.b, 0.55)
      ctx.lineWidth = 1
      ctx.stroke()
    }

  }
}
