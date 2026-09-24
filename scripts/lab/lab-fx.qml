import QtQuick
import "../../bar/modules"

// Every effect on one sheet, frozen at a moment of its cycle. Saves /tmp/ito-lab/out.png.
Rectangle {
  id: root
  width: 900; height: 130; color: "#0b0d0e"

  Row {
    x: 20; y: 20
    spacing: 8
    Repeater {
      model: ["none", "spin", "pulse", "breathe", "heartbeat", "flicker", "sway", "glitch", "ripple"]
      ItoFx {
        id: fx
        required property string modelData
        required property int index
        width: 84; height: 84
        kind: modelData
        active: true
        amount: 1
        Component.onCompleted: { fx.t = 0.16 + 0.31 * index; fx.angle = 40 }
        Image {
          anchors.fill: parent
          source: "file:///mnt/DATA/Themes/ito-verse/Ito-verse/bar/modules/ito-art/system/menu-tomie.png"
          fillMode: Image.PreserveAspectFit
        }
      }
    }
  }
  Timer { interval: 700; running: true; onTriggered: root.grabToImage(function(r) { r.saveToFile("/tmp/ito-lab/out.png"); Qt.quit() }) }
}
