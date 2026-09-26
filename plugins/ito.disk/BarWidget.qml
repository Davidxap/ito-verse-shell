import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import qs.Ui as Ui
import "../../bar/modules" as Ito

// Ito disk — theme drive artwork with live root filesystem use from df (polled).
// Click opens the home folder; tooltip shows use vs free space.
// Plugin form of bar/modules/ito-disk.qml. The ito.bar host loads registered
// plugins by id and has no support for `type: qml` entries.
Ui.BarWidget {
  id: root
  moduleName: "ito.disk"

  // Same blood setting as workspaces/spiral. The default is the palette
  // paint stop; all stops are defined in themes/ito-verse/palette.toml.
    // Settings live in the sidecar, not in shell.json, because the engine
  // rewrites that file under us. See ItoConfig.qml.
  Ito.ItoConfig {
    id: cfg
    path: Qt.resolvedUrl("../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  readonly property color blood: cfg.get("blood", setting("blood", "#651817"))
  readonly property int artSize: cfg.get("size", setting("size", 30))

  readonly property url art: Qt.resolvedUrl("../../bar/modules/ito-art/")
  readonly property color live: cfg.blood
  readonly property int glyph: Math.round(root.barSize * cfg.get("iconScale", 0.62))
  readonly property bool showValues: cfg.get("showValues", true)
    && cfg.get("valueStyle", "percent") !== "off"
    && cfg.get("content:ito.disk", "both") !== "icon"
  // "text" mode drops the icon and leaves the reading
  readonly property bool showIcon: cfg.get("content:ito.disk", "both") !== "text"

  property real pct: 0
  property double availBytes: 0
  property double usedBytes: 0

  function gib(b) {
    return (b / 1024 / 1024 / 1024).toFixed(1)
  }

  function refresh() {
    if (!poll.running) poll.running = true
  }

  function parse(text) {
    var m = String(text || "").match(/(\d+)%\s+(\d+)\s+(\d+)/)
    if (!m) return
    root.pct = Math.max(0, Math.min(1, parseInt(m[1], 10) / 100))
    root.usedBytes = parseFloat(m[2]) || 0
    root.availBytes = parseFloat(m[3]) || 0
  }

  Process {
    id: poll
    running: true
    command: ["sh", "-c", "df -B1 --output=pcent,used,avail / | tail -1"]
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
    tooltipText: "Disk / " + Math.round(root.pct * 100) + "% · "
      + root.gib(root.availBytes) + " GiB free"
    horizontalMargin: 4
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? barSize : content.width + scaledHorizontalMargin * 2
    fixedHeight: vertical ? content.height + scaledVerticalPadding * 2 : barSize
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton && root.bar)
        if (root.bar) root.bar.run("xdg-open ~")
    }

    // Side by side on a horizontal bar, stacked (icon over reading) on a vertical one.
    Grid {
      id: content
      anchors.centerIn: parent
      columns: root.vertical ? 1 : 9
      spacing: 3
      horizontalItemAlignment: Grid.AlignHCenter
      verticalItemAlignment: Grid.AlignVCenter

      // A platter that fills with blood as the disk fills.
      Ito.ItoHover { parent: button; target: icon; hovered: button.tooltipHovered; kind: "spin"; amp: cfg.motionAmp; glow: cfg.blood; light: cfg.light }
      Ito.ItoFillArt {
        id: icon
        visible: root.showIcon
        palette: cfg
        size: root.glyph
        value: root.pct
        art: root.art + "system/disk.png"
        inside: root.art + "system/disk-fill.png"
        paper: false
      }

      Ito.ItoValue {
        visible: root.showValues
        barSize: root.barSize
        label: "DISK"
        vertical: root.vertical
        detail: Math.round(root.usedBytes / 1073741824) + "/" + Math.round((root.usedBytes + root.availBytes) / 1073741824) + "G"
        hot: root.pct > 0.9
        value: Math.round(root.pct * 100)
      }
    }
  }
}
