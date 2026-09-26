import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import qs.Ui as Ui
import "../../bar/modules" as Ito

// Ito memory — theme chip artwork with live RAM use from /proc/meminfo (polled).
// Click opens btop; tooltip shows used vs total.
// Plugin form of bar/modules/ito-mem.qml. The ito.bar host loads registered
// plugins by id and has no support for `type: qml` entries.
Ui.BarWidget {
  id: root
  moduleName: "ito.mem"

  // Same blood setting as workspaces/spiral. The default is the palette
  // paint stop; all stops are defined in themes/ito-verse/palette.toml.
    // Settings live in the sidecar, not in shell.json, because the engine
  // rewrites that file under us. See ItoConfig.qml.
  Ito.ItoConfig {
    id: cfg
    path: Qt.resolvedUrl("../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  readonly property string host: Qt.resolvedUrl("../../bar/modules/bin/ito-host").toString().replace("file://", "")
  readonly property color blood: cfg.get("blood", setting("blood", "#651817"))
  readonly property int artSize: cfg.get("size", setting("size", 30))

  readonly property url art: Qt.resolvedUrl("../../bar/modules/ito-art/")
  readonly property int glyph: Math.round(root.barSize * cfg.get("iconScale", 0.62))
  readonly property bool showValues: cfg.get("showValues", true)
    && cfg.get("valueStyle", "percent") !== "off"
    && cfg.get("content:ito.mem", "both") !== "icon"
  // "text" mode drops the icon and leaves the reading
  readonly property bool showIcon: cfg.get("content:ito.mem", "both") !== "text"

  property real pct: 0
  property double usedKiB: 0
  property double totalKiB: 1

  function gib(kib) {
    return (kib / 1024 / 1024).toFixed(1)
  }

  function refresh() {
    if (!poll.running) poll.running = true
  }

  function parse(text) {
    var total = 0, avail = 0
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^(\w+):\s+(\d+)/)
      if (!m) continue
      if (m[1] === "MemTotal") total = parseFloat(m[2])
      else if (m[1] === "MemAvailable") avail = parseFloat(m[2])
    }
    if (!(total > 0)) return
    root.totalKiB = total
    root.usedKiB = Math.max(0, total - avail)
    root.pct = Math.max(0, Math.min(1, root.usedKiB / total))
  }

  Process {
    id: poll
    running: true
    command: ["sh", "-c", "head -3 /proc/meminfo"]
    stdout: StdioCollector {
      onStreamFinished: root.parse(this.text)
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "Memory " + Math.round(root.pct * 100) + "% · "
      + root.gib(root.usedKiB) + " / " + root.gib(root.totalKiB) + " GiB"
    horizontalMargin: 4
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? barSize : content.width + scaledHorizontalMargin * 2
    fixedHeight: vertical ? content.height + scaledVerticalPadding * 2 : barSize
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton && root.bar)
        if (root.bar) root.bar.run(host + " tui btop")
    }

    // Side by side on a horizontal bar, stacked (icon over reading) on a vertical one.
    Grid {
      id: content
      anchors.centerIn: parent
      columns: root.vertical ? 1 : 9
      spacing: 3
      horizontalItemAlignment: Grid.AlignHCenter
      verticalItemAlignment: Grid.AlignVCenter

      // A memory module with an eye on each chip, filling with blood as memory is used.
      Ito.ItoHover { parent: button; target: icon; hovered: button.tooltipHovered; kind: "lift"; amp: cfg.motionAmp; glow: cfg.blood; light: cfg.light }
      Ito.ItoFillArt {
        id: icon
        visible: root.showIcon
        palette: cfg
        size: root.glyph
        value: root.pct
        art: root.art + "system/mem.png"
        inside: root.art + "system/mem-fill.png"
        paper: false
      }

      Ito.ItoValue {
        visible: root.showValues
        barSize: root.barSize
        label: "RAM"
        vertical: root.vertical
        detail: Math.round(root.usedKiB / 1024 / 1024) + "/" + Math.round(root.totalKiB / 1024 / 1024) + "G"
        hot: root.pct > 0.85
        value: Math.round(root.pct * 100)
      }
    }
  }
}
