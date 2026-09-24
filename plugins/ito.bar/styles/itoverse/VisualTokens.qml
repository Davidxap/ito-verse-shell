pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons as Commons
import "." as Ito
import "../../../../bar/modules" as Modules
import "../../../../bar/modules/ItoSurfaces.js" as Surfaces

// Geometry for the Ito-verse 52px bar. Everything that is not geometry is the fork's own
// token set (MIT, see ../../NOTICE): colours, border and radius still follow ito.state.
Item {
  id: root

  required property var bar

  Modules.ItoConfig {
    id: look
    path: Qt.resolvedUrl("../../../../bar/modules/ito-style.json").toString().replace("file://", "")
  }
  readonly property var stateService: bar && bar.shell
    && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor("ito.state") : null
  readonly property var presentation: stateService && stateService.config
    ? stateService.config.presentation || ({}) : ({})
  readonly property string shellStyle:
    ["shibumi", "full", "fit", "dock", "notch"]
      .indexOf(String(presentation.shellStyle || "")) >= 0
      ? String(presentation.shellStyle) : "shibumi"
  readonly property bool v2Shell: shellStyle !== "shibumi"

  readonly property string fontFamily: Commons.Style.font.family
  // 46px bar: a 40px visible strip inside it, 3px above and below, and three more pixels
  // reserved so windows do not touch it. Widgets size their art as a fraction of barSize.
  // The details of the shape, each a choice on the Bars page (sidecar keys barSize, barRadius, barGap, barShadow).
  readonly property int sizePx: Math.max(38, Math.min(58, Math.round(Number(look.get("barSize", 46)))))
  readonly property string radiusMode: String(look.get("barRadius", "round"))      // square | soft | round
  readonly property string gapMode: String(look.get("barGap", "normal"))            // tight | normal | airy
  readonly property real gapScale: gapMode === "tight" ? 0.5 : (gapMode === "airy" ? 1.5 : 1)
  readonly property int barHeight: Commons.Style.space(sizePx)
  readonly property int exclusiveHeight: Commons.Style.space(sizePx + 3)
  // The bar sits flush against the screen edge it is on, with no gap: the plate fills the whole bar and touches the
  // edge. "Float off the edge" (sidecar barFloat, Bars page) gives back the old look, a pill clear of the edge.
  readonly property bool floatBar: look.get("barFloat", false) === true
  readonly property bool flushEdge: !floatBar
  readonly property int islandHeight: floatBar ? Commons.Style.space(sizePx - 6) : barHeight
  readonly property int islandInsetX: floatBar ? Commons.Style.space(6) : 0
  readonly property int islandContentInsetX: Commons.Style.space(10)
  readonly property int islandOffsetY: floatBar ? Commons.Style.space(3) : 0
  readonly property int slotHeight: Commons.Style.space(35)
  readonly property int pillHeight: Commons.Style.space(30)
  // How round the corners are, one rule for every form. Against the screen edge (the default) only the corners that
  // are free curve, and a full pill there would sweep the whole height into a crescent, so Round is a firm 16 px and
  // Soft 8; floating clear of the edge every corner is free and Round is the whole pill. Square is square everywhere.
  function corner(round, soft) {
    if (radiusMode === "square") return 0
    if (radiusMode === "soft" || presentation.radius === "small") return soft
    return round
  }
  readonly property int pillRadius: Commons.Style.space(corner(14, 7))
  readonly property int islandRadius: Commons.Style.space(flushEdge ? corner(16, 8) : corner(20, 9))
  readonly property int tileRadius: v2Shell
    ? Commons.Style.space(11)
    : Math.max(1, pillRadius - Commons.Style.space(2))
  readonly property int pillPaddingX: Commons.Style.space(11)
  readonly property int labelSize: Commons.Style.font.body
  readonly property int captionSize: Commons.Style.font.caption
  readonly property int iconSize: Commons.Style.space(18)
  readonly property int contentGap: Commons.Style.space(6)
  readonly property int compactGap: Commons.Style.space(4)
  readonly property int groupGap: Commons.Style.space(Math.round(12 * gapScale))
  readonly property int splitGap: Commons.Style.space(Math.round(22 * gapScale))
  readonly property int tooltipRadius: Commons.Style.space(6)
  readonly property int tooltipPaddingX: Commons.Style.space(10)
  readonly property int tooltipPaddingY: Commons.Style.space(4)
  readonly property int widgetFadeDuration: 140
  readonly property int geometryDuration: 160
  readonly property int colorDuration: 160
  readonly property int invalidDropDuration: 230
  readonly property int returnCleanupDuration: 240
  // V2 notch contract: 14px shoulder flowing directly from the screen edge.
  readonly property int shellWingWidth: Commons.Style.space(18)
  readonly property int shellFitRadius: Commons.Style.space(corner(16, 8))
  readonly property int shellDockRadius: Commons.Style.space(flushEdge ? corner(16, 8) : corner(20, 10))
  // The notch's inner corner, where its shoulder meets the plate.
  readonly property int notchBodyRadius: radiusMode === "square" ? 0 : (radiusMode === "soft" ? 6 : 12)

  // The plate draws its own edge; the fork's one-pixel line would double it.
  readonly property bool borderEnabled: false
  readonly property bool panelBorderEnabled: v2Shell
    ? presentation.panelBorder !== false : borderEnabled
  readonly property bool shadowEnabled: presentation.shadow === true || look.get("barShadow", false) === true
  readonly property bool frostEnabled: !v2Shell && presentation.frost === true
  readonly property color paper: Commons.Color.background
  readonly property color ink: Commons.Color.foreground
  readonly property color sumi: Commons.Color.muted
  readonly property color sumiHi: mix(sumi, ink, 0.55)
  readonly property color seal: stateService
    ? stateService.selectedColor : Commons.Color.bar.active
  readonly property color mutedInk: sumi
  Modules.ItoConfig {
    id: sidecar
    path: Qt.resolvedUrl("../../../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  // "Widget pills" layer: each of our widgets sits in its own dark pill, the way Shibumi's do. It is
  // what makes the Floating look (no plate) readable over a busy wallpaper.
  readonly property bool pillsOn: Surfaces.on(sidecar, "fxPills")

  readonly property color pill: pillsOn
    ? Qt.rgba(0.02, 0.024, 0.027, sidecar.get("surfacePill", 0.78))
    : Qt.rgba(paper.r, paper.g, paper.b, 0.18)
  // The plate (ItoPlate) is drawn underneath, so the fork surface must not paint over it.
  readonly property color barBackground: "transparent"
  readonly property color panelBackground: Qt.rgba(paper.r, paper.g, paper.b, 0.94)
  readonly property color pillBorder: pillsOn
    ? Qt.rgba(0.78, 0.8, 0.82, 0.22) : mix(paper, ink, 0.13)
  readonly property color islandBorder: mix(paper, ink, 0.16)
  readonly property color shellBorder: mix(paper, ink, 0.22)
  readonly property color pillShadow: Qt.rgba(0, 0, 0, 0.55)
  readonly property int pillBorderWidth: pillsOn || borderEnabled ? 1 : 0
  readonly property color panelBorder: pillBorder
  readonly property int panelBorderWidth: panelBorderEnabled ? 1 : 0
  readonly property int panelRadius: v2Shell
    ? Commons.Style.space(6) : pillRadius
  readonly property color shellShadow: Qt.rgba(0, 0, 0, 0.46)
  readonly property color separator: Qt.rgba(ink.r, ink.g, ink.b, 0.18)
  readonly property color fillActive: Qt.rgba(seal.r, seal.g, seal.b, 0.18)
  readonly property color fillHover: Qt.rgba(seal.r, seal.g, seal.b, 0.10)
  readonly property color fillIdle: Qt.rgba(0, 0, 0, 0.12)
  readonly property color fillPrimaryHover: Qt.lighter(seal, 1.15)

  function workspacePillPadding(style) {
    if (style !== "numbers") return Commons.Style.space(4)
    const outerRadius = v2Shell ? Commons.Style.space(12) : pillRadius
    const badgeRadius = v2Shell ? Commons.Style.space(10)
      : Commons.Style.space(presentation.radius === "small" ? 5 : 10)
    return Math.max(1, outerRadius - badgeRadius)
  }

  function widgetColorId(settings) {
    const value = settings && settings.color !== undefined
      ? String(settings.color) : "inherit"
    return value === "inherit" ? "inherit"
      : stateService && typeof stateService.paletteColor === "function"
        ? value : "inherit"
  }

  function widgetBorderColorId(settings) {
    const legacySurfaceColor = settings
      && settings.widgetBorderUsesSurfaceColor === true
    const value = settings && settings.widgetBorderColor !== undefined
      ? String(settings.widgetBorderColor)
      : legacySurfaceColor ? widgetColorId(settings) : "inherit"
    return value === "inherit" ? "inherit"
      : stateService && typeof stateService.paletteColor === "function"
        ? value : "inherit"
  }

  function widgetColorMode(settings) {
    const value = settings && settings.colorMode !== undefined
      ? String(settings.colorMode) : "fill"
    return ["none", "fill", "border", "both"].indexOf(value) >= 0
      ? value : "fill"
  }

  function widgetHasFill(settings) {
    if (!v2Shell) return widgetColorId(settings) !== "inherit"
    const mode = widgetColorMode(settings)
    return widgetColorId(settings) !== "inherit"
      && (mode === "fill" || mode === "both")
  }

  function widgetHasBorder(settings) {
    const mode = widgetColorMode(settings)
    return settings && settings.widgetBorder === true
      || mode === "border" || mode === "both"
  }

  function widgetSurfaceOpacity(settings) {
    const value = settings && settings.surfaceOpacity !== undefined
      ? Number(settings.surfaceOpacity) : 1
    return Math.max(0.35, Math.min(1, Number.isFinite(value) ? value : 1))
  }

  function widgetRadius(settings) {
    const value = settings && settings.widgetRadius !== undefined
      ? String(settings.widgetRadius) : "auto"
    if (value === "square") return 0
    if (value === "soft") return Commons.Style.space(6)
    if (value === "round") return pillHeight / 2
    return tileRadius
  }

  function widgetPadding(settings, decorated) {
    const value = settings && settings.widgetPadding !== undefined
      ? String(settings.widgetPadding) : "auto"
    if (value === "none") return 0
    if (value === "compact") return Commons.Style.space(3)
    if (value === "roomy") return Commons.Style.space(6)
    return decorated ? Commons.Style.space(3) : 0
  }

  function widgetBorderWidth(settings) {
    const value = settings && settings.widgetBorderWidth !== undefined
      ? Number(settings.widgetBorderWidth) : 1
    const bounded = Math.max(0.5, Math.min(2,
      Number.isFinite(value) ? value : 1))
    return Math.round(bounded * 2) / 2
  }

  function widgetFillColor(settings) {
    const id = widgetColorId(settings)
    return widgetHasFill(settings) && stateService
      ? stateService.paletteColor(id) : "transparent"
  }

  function widgetBorderColor(settings) {
    if (!widgetHasBorder(settings)) return "transparent"
    const id = widgetBorderColorId(settings)
    return id !== "inherit" && stateService
      ? stateService.paletteColor(id) : panelBorder
  }

  function widgetContentColor(settings, fallback) {
    const id = widgetColorId(settings)
    if (!widgetHasFill(settings)) return fallback
    const tone = settings && settings.tone !== undefined
      ? String(settings.tone) : "auto"
    if (tone === "background") return paper
    if (tone === "foreground") return ink
    return stateService
        && typeof stateService.paletteContrastColor === "function"
      ? stateService.paletteContrastColor(id) : fallback
  }

  function mix(base, toward, amount) {
    return Qt.rgba(
      base.r * (1 - amount) + toward.r * amount,
      base.g * (1 - amount) + toward.g * amount,
      base.b * (1 - amount) + toward.b * amount,
      1)
  }

  // Editing the bar is plain drag-and-drop here: no grid of empty slots, no + and × buttons, and a card
  // that says what to do. (Shibumi's slot editor is still what the shibumi style shows.)
  readonly property bool plainEditing: true
  // The dock is a floating pill, clear of the screen's edge, not a block attached to it.
  readonly property bool floatingDock: floatBar

  // How the bar is arranged when nothing has been moved: the one list Reset puts everything back to.
  Modules.ItoConfig {
    id: arrangement
    path: Qt.resolvedUrl("../../../../bar/modules/ito-layout.json").toString().replace("file://", "")
  }
  readonly property var defaultArrangement: arrangement.values
  readonly property Component editHint: hintComponent

  Component {
    id: hintComponent

    Ito.EditHint {}
  }

  // The plate that RunChrome paints in place of a flat rectangle, one per run of the bar.
  readonly property Component runPlate: plateComponent

  Component {
    id: plateComponent

    Ito.RunPlate {}
  }

  visible: false
  width: 0
  height: 0
}
