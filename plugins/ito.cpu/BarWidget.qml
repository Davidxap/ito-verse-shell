import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import qs.Ui as Ui
import "../../bar/modules" as Ito

// Ito cpu — theme gear artwork with live total CPU load from /proc/stat (polled).
// Click opens btop; tooltip shows the current load.
// Plugin form of bar/modules/ito-cpu.qml. The ito.bar host loads registered
// plugins by id and has no support for `type: qml` entries.
Ui.BarWidget {
  id: root
  moduleName: "ito.cpu"

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
  // One standard glyph size for every bar icon; only the centre seal breaks it.
  readonly property int glyph: Math.round(root.barSize * cfg.get("iconScale", 0.62))
  readonly property bool showValues: cfg.get("showValues", true)
    && cfg.get("valueStyle", "percent") !== "off"
    && cfg.get("content:ito.cpu", "both") !== "icon"
  // "text" mode drops the icon and leaves the reading
  readonly property bool showIcon: cfg.get("content:ito.cpu", "both") !== "text"

  property real pct: 0
  property double prevIdle: -1
  property double prevTotal: -1

  function refresh() {
    if (!poll.running) poll.running = true
  }

  function parse(text) {
    var parts = String(text || "").trim().split(/\s+/)
    if (parts.length < 5 || parts[0] !== "cpu") return
    var nums = []
    // First 8 fields only: guest times are already counted inside user/nice.
    for (var i = 1; i < parts.length && i <= 8; i++) nums.push(parseFloat(parts[i]) || 0)
    var idle = nums[3] + (nums.length > 4 ? nums[4] : 0)
    var total = 0
    for (var j = 0; j < nums.length; j++) total += nums[j]
    if (root.prevTotal >= 0 && total > root.prevTotal) {
      var dTotal = total - root.prevTotal
      if (dTotal > 0)
        root.pct = Math.max(0, Math.min(1, 1 - (idle - root.prevIdle) / dTotal))
    }
    root.prevIdle = idle
    root.prevTotal = total
  }

  Process {
    id: poll
    running: true
    command: ["sh", "-c", "head -1 /proc/stat"]
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
    tooltipText: "CPU " + Math.round(root.pct * 100) + "%"
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

      // A chip with the spiral in it, filling with blood as the processor's load rises.
      Ito.ItoHover { parent: button; target: icon; hovered: button.tooltipHovered; kind: "pulse"; amp: cfg.motionAmp; glow: cfg.blood; light: cfg.light }
      Ito.ItoFillArt {
        id: icon
        visible: root.showIcon
        palette: cfg
        size: root.glyph
        value: root.pct
        art: root.art + "system/cpu.png"
        inside: root.art + "system/cpu-fill.png"
        paper: false
      }

      Ito.ItoValue {
        visible: root.showValues
        barSize: root.barSize
        label: "CPU"
        vertical: root.vertical
        hot: root.pct > 0.8
        value: Math.round(root.pct * 100)
      }
    }
  }
}
