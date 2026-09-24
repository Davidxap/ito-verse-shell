import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Ui as Ui
import "../../bar/modules" as Ito

// Ito media: previous, play or pause, next, for whatever is playing (any MPRIS player: Spotify, a browser,
// mpv…). The play ring is blood while something plays. Nothing is drawn when there is no player, so it
// costs the bar no room.
Ui.BarWidget {
  id: root
  moduleName: "ito.media"

  Ito.ItoConfig {
    id: cfg
    path: Qt.resolvedUrl("../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  readonly property url art: Qt.resolvedUrl("../../bar/modules/ito-art/media/")
  readonly property int glyph: Math.round(root.barSize * cfg.get("iconScale", 0.62))

  // The player that is playing, else the first one there is.
  readonly property var player: {
    var list = Mpris.players.values
    for (var i = 0; i < list.length; i++)
      if (list[i].isPlaying) return list[i]
    return list.length > 0 ? list[0] : null
  }
  readonly property bool playing: player ? player.isPlaying : false
  readonly property string track: player ? String(player.trackTitle || "") : ""

  visible: player !== null

  // Something moves in a pill behind the controls while a track plays, and stops when it stops. Which effect it is
  // (blood, the spiral, eyes, fog or radio static) is chosen on the Effects page; it leaps when the track changes.
  onTrackChanged: if (root.playing) blood.pulse()
  onPlayingChanged: blood.pulse()

  Ito.ItoMediaFx {
    id: blood
    anchors.centerIn: parent
    width: parent.width - 6
    height: Math.min(parent.height - 10, 30)
    radius: 15
    kind: String(cfg.get("mediaFx", "blood"))
    customSource: String(cfg.get("mediaFx", "blood")) !== "custom" ? "" : "file://" + Quickshell.env("HOME") + "/.config/ito/effects/custom?v=" + cfg.get("fxCustomVer", 0)
    active: root.playing
    blood: cfg.blood
    bone: cfg.bone
    speed: cfg.fxSpeed
    z: 0
  }
  implicitWidth: player ? controls.implicitWidth : 0
  implicitHeight: player ? controls.implicitHeight : 0

  // Side by side on a horizontal bar, stacked on a vertical one.
  Grid {
    id: controls
    columns: root.vertical ? 1 : 3
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    Repeater {
      model: [
        { "face": "media-prev", "tip": "Previous", "act": "prev" },
        { "face": "playpause", "tip": "Play or pause", "act": "toggle" },
        { "face": "media-next", "tip": "Next", "act": "next" }
      ]

      Ui.WidgetButton {
        id: control
        required property var modelData

        bar: root.bar
        tooltipText: (modelData.act === "toggle" && root.track !== "") ? root.track : modelData.tip
        labelVisible: false
        hasVisualContent: true
        horizontalMargin: 2
        enabled: root.player !== null
        fixedWidth: root.vertical ? root.barSize : root.glyph + scaledHorizontalMargin * 2
        fixedHeight: root.vertical ? root.glyph + 8 : root.barSize
        onPressed: function(mouseButton) {
          if (mouseButton !== Qt.LeftButton || !root.player) return
          if (modelData.act === "prev" && root.player.canGoPrevious) root.player.previous()
          else if (modelData.act === "next" && root.player.canGoNext) root.player.next()
          else if (modelData.act === "toggle" && root.player.canTogglePlaying) root.player.togglePlaying()
        }

        Ito.ItoImage {
          palette: cfg
          anchors.centerIn: parent
          width: root.glyph
          height: width
          // playing shows the pause ring; paused shows the red play ring
          source: root.art + (modelData.face === "playpause"
            ? (root.playing ? "media-pause" : "media-play") : modelData.face) + ".png"
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          opacity: control.tooltipHovered ? 1 : 0.9
          scale: control.tooltipHovered ? 1.1 : 1
          Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
      }
    }
  }
}
