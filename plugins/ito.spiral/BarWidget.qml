import QtQuick
import Quickshell
import qs.Ui as Ui
import "../../bar/modules" as Ito
import "../../bar/modules/ItoMarks.js" as Marks

// Ito spiral launcher — signature Tomie artwork.
// Left click summons the Omarchy menu (same IPC as the stock menu widget).
// What it does on hover (turn, pulse, flicker…) is the Effects page's choice; it lights up from behind.
// Plugin form of bar/modules/ito-spiral.qml. The ito.bar host loads registered
// plugins by id and has no support for `type: qml` entries.
Ui.BarWidget {
  id: root
  moduleName: "ito.spiral"

  // Same blood setting as the workspaces. The default is the palette
  // paint stop; all stops are defined in themes/ito-verse/palette.toml.
    // Settings live in the sidecar, not in shell.json, because the engine
  // rewrites that file under us. See ItoConfig.qml.
  Ito.ItoConfig {
    id: cfg
    path: Qt.resolvedUrl("../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  readonly property string host: Qt.resolvedUrl("../../bar/modules/bin/ito-host").toString().replace("file://", "")
  readonly property color blood: cfg.blood

  // The mark on the button: the Uzumaki spiral, a face, a sigil, or a picture of the user's own (Logo page).
  readonly property string mark: String(cfg.get("menuMark", "uzumaki"))
  readonly property url markSource: Marks.source(Qt.resolvedUrl("../../bar/modules/ito-art/").toString(), mark,
                                                 Quickshell.env("HOME"), cfg.markOverrides)
  // "auto" is the mark's own effect: a round seal turns, a face keeps a heartbeat.
  readonly property string effect: {
    var chosen = String(cfg.get("fxMark", "auto"))
    return chosen === "auto" ? Marks.autoEffect(mark) : chosen
  }
  readonly property int artSize: cfg.get("size", setting("size", 30))

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "Menu"
    horizontalMargin: 4
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? barSize : fx.width + scaledHorizontalMargin * 2
    fixedHeight: vertical ? fx.height + scaledVerticalPadding * 2 : barSize
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton && root.bar)
        if (root.bar) root.bar.run(host + " menu")
    }

    Ito.ItoGlow {
      anchors.centerIn: fx
      width: fx.width * 1.9
      height: fx.height * 1.9
      color: root.blood
      strength: (button.tooltipHovered ? 0.30 : 0) * cfg.light
      Behavior on strength { NumberAnimation { duration: 240 } }
    }

    Ito.ItoFx {
      id: fx
      anchors.centerIn: parent
      // The standard bar glyph, the same size as the workspaces and the instruments.
      width: Math.round(button.barSize * cfg.get("iconScale", 0.62))
      height: width
      kind: root.effect
      active: String(cfg.get("fxWhen", "hover")) === "always" || button.tooltipHovered
      speed: cfg.fxSpeed
      strength: cfg.fxStrength
      color: root.blood

      Ito.ItoImage {
        id: icon
        palette: cfg
        anchors.fill: parent
        source: root.markSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
      }
    }

  }
}
