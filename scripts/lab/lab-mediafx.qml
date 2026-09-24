import QtQuick
import "../../bar/modules" as Ito

// The media effects, frozen mid-motion, at the size the media widget actually gives them. Saves
// /tmp/ito-lab/out.png.
Rectangle {
  id: root
  width: 760; height: 260; color: "#0b0d0e"

  Column {
    x: 20; y: 20
    spacing: 14
    Repeater {
      model: ["eyes", "fog", "static"]
      Row {
        id: fxRow
        required property string modelData
        spacing: 12
        Text { text: fxRow.modelData; color: "#c7ccd1"; font.pixelSize: 14; width: 60; anchors.verticalCenter: parent.verticalCenter }
        Repeater {
          model: 3
          Ito.ItoMediaFx {
            id: mfx
            required property int index
            width: 220; height: 40
            kind: fxRow.modelData
            active: true
            surge: index === 1 ? 0.8 : 0
            Component.onCompleted: mfx.t = 1.1 + index * 1.7
          }
        }
      }
    }
  }
  Timer { interval: 1200; running: true; onTriggered: root.grabToImage(function(r) { r.saveToFile("/tmp/ito-lab/out.png"); Qt.quit() }) }
}
