import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons as Commons

// Settings that must survive the bar engine, and the colours the shell paints with.
//
// The engine owns shell.json and rewrites it whenever the user drags a module or a popup toggles, so any
// value stored in a layout entry can be reverted under our feet. That is the "the style changes by itself"
// bug: clicking a workspace makes the engine persist its own in-memory layout over ours.
//
// This sidecar lives next to the modules, so nothing but ito-config writes it. FileView watches it, which
// means a change applies live with no shell restart.
//
// COLOUR. The shell and the theme are two different things. By default the shell keeps its own palette
// (bone on ink, with blood as the one live colour), whatever theme is installed. With `colorMode` set to
// "theme" it follows the installed theme instead: blood becomes the theme's accent (or any colour of its
// palette the user picks), bone its foreground, and the pre-drawn art is recoloured by a shader onto both, so
// nothing stays crimson under a green theme.
QtObject {
  id: root

  // Absolute path, no file:// scheme.
  property string path: ""
  property var values: ({})

  function get(key, fallback) {
    var v = root.values[key]
    return (v === undefined || v === null || v === "") ? fallback : v
  }

  // The default is to follow the installed theme, as Shibumi does; the shell's own palette is one choice.
  readonly property bool followTheme: String(get("colorMode", "theme")) === "theme"

  // The installed theme's palette, read from its colors.toml (accent, foreground, color0..color15). This
  // is what the accent picker offers, so the choices are always the colours of the theme in use.
  property var themeColors: ({})

  // Which of them is the shell's "blood": the theme's accent by default, any of its palette colours, or
  // a colour typed in.
  readonly property string accentSource: String(get("accentSource", "accent"))

  function pickAccent() {
    var src = accentSource
    if (src === "custom") return get("accentCustom", "#c4162a")
    if (src === "ito") return "#c4162a"
    if (src !== "accent" && themeColors[src]) return themeColors[src]
    return themeColors["accent"] || Commons.Color.accent
  }

  // How much light the shell gives off, and how vivid its colours are. Both are 1 when never touched, so
  // nothing changes until the user moves them. `light` scales every glow and bloom (0 is none, 2 is
  // strong); `vibrance` pushes the accent towards a saturated, brighter colour or towards a quieter one.
  readonly property real light: Math.max(0, Math.min(2.5, Number(get("light", 1))))
  readonly property real vibrance: Math.max(0.3, Math.min(2, Number(get("vibrance", 1))))
  readonly property real fxSpeed: Math.max(0.2, Math.min(3, Number(get("fxSpeed", 1))))
  // How the shell moves when things appear: off (instant), calm (short and quiet, the default) or lively (longer
  // and with more travel). `motionAmp` is 0, 1 or 1.7 so a caller only multiplies its own distance and time.
  readonly property string motion: ["off", "calm", "lively"].indexOf(String(get("motion", "calm"))) >= 0
    ? String(get("motion", "calm")) : "calm"
  readonly property real motionAmp: motion === "off" ? 0 : motion === "lively" ? 1.7 : 1
  readonly property real fxStrength: Math.max(0.2, Math.min(2.5, Number(get("fxStrength", 1))))

  // Push a colour towards more or less vivid. `c` may be a colour or the "#rrggbb" text the settings file holds: it
  // is turned into a colour first, because a plain string has no hue or saturation and the arithmetic below gave NaN,
  // which paints black. That is what took every accent (and the slider fills) away as soon as Vibrance moved.
  function vivid(c) {
    var col = Qt.color(String(c))
    if (Math.abs(vibrance - 1) < 0.01) return col
    var h = col.hsvHue < 0 ? 0 : col.hsvHue
    var out = Qt.hsva(h, Math.min(1, col.hsvSaturation * vibrance),
                      Math.min(1, col.hsvValue * (0.7 + 0.3 * vibrance)), col.a)
    return isNaN(out.r) ? col : out
  }

  // The colours everything paints with.
  readonly property color blood: vivid(followTheme ? pickAccent() : get("bloodLive", "#c4162a"))
  readonly property color lit: Qt.lighter(blood, 1.18)
  readonly property color bone: followTheme ? (themeColors["foreground"] || Commons.Color.foreground) : "#c7ccd1"
  readonly property color ink: followTheme ? (themeColors["background"] || Commons.Color.background) : "#0b0d0e"

  // Whether the shell is following the theme. When it is, the pre-drawn art (bone and crimson) goes through
  // the theme shader (ItoThemeEffect), which moves it onto the colours above.
  readonly property bool tinted: followTheme

  // The theme's colors.toml. A theme swap changes what the `current` link points at, and a link is not
  // reliably watched, so the shell's own accent changing is the cue to read it again.
  property FileView themeFile: FileView {
    path: Commons.Color.currentThemePath + "/colors.toml"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var out = {}
      var lines = text().split("\n")
      for (var i = 0; i < lines.length; i++) {
        var m = lines[i].match(/^\s*([A-Za-z0-9_]+)\s*=\s*"(#[0-9A-Fa-f]{6,8})"/)
        if (m) out[m[1]] = m[2]
      }
      // colors.toml names the ANSI palette color0..color15; the picker shows them as color0..color15
      root.themeColors = out
    }
    onLoadFailed: root.themeColors = ({})
  }

  property Connections themeWatch: Connections {
    target: Commons.Color
    function onAccentChanged() { root.themeFile.reload() }
    function onForegroundChanged() { root.themeFile.reload() }
  }

  // Pictures of the user's own that replace a built-in mark of the same name (see bin/ito-marks). The index
  // is written by ito-marks whenever the folder is read.
  property var markOverrides: ({})
  property FileView marksIndex: FileView {
    path: Quickshell.env("HOME") + "/.cache/ito/marks/index.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.markOverrides = (JSON.parse(text()) || {}).overrides || ({}) } catch (e) { root.markOverrides = ({}) }
    }
    onLoadFailed: root.markOverrides = ({})
  }

  property FileView file: FileView {
    path: root.path
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        root.values = JSON.parse(text()) || ({})
      } catch (e) {
        root.values = ({})
      }
    }
    onLoadFailed: root.values = ({})
  }
}
