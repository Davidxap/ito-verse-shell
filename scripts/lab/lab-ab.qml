import QtQuick
import "../../bar/modules"

// A/B of the art pipeline at the bar's real sizes: plain tint above, sharpened tint below.
Rectangle {
  id: root
  width: 760; height: 190; color: "#0a0c0d"
  readonly property color ink: "#14181b"
  component Row46: Rectangle {
    property string base: ""
    width: 720; height: 46; radius: 14; color: root.ink; border.color: "#262d32"
    Row { anchors.centerIn: parent; spacing: 12
      ItoArt { size: 32; sources: [base + "status-eyes/eye-outline.png", base + "status-eyes/eye-normal.png", base + "status-eyes/eye-red.png"]; value: 0.5 }
      ItoArt { size: 32; sources: [base + "workspace-indicators/indicator-inactive.png", base + "workspace-indicators/indicator-active.png"]; value: 0.6 }
      ItoLevelArt { size: 32; value: 0.5; blood: "#c4162a"; source: base + "devices/drive.png" }
      ItoArt { size: 27; sources: [base + "network/wifi.png"] }
      ItoArt { size: 27; sources: [base + "audio/volume.png"] }
      ItoArt { size: 27; sources: [base + "brightness/brightness-high.png"] }
      ItoArt { size: 27; sources: [base + "bluetooth/bluetooth.png"] }
      ItoArt { size: 38; sources: [base + "system/system-normal.png"] }
      Image { width: 19; height: 34; source: base + "tomie/tomie-mark.png"; fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true } } }
  Column { x: 20; y: 12; spacing: 8
    Text { text: "A — tinte plano"; color: "#8b9199"; font.pixelSize: 11 }
    Row46 { base: "file:///tmp/ito-lab/art-plain/" }
    Text { text: "B — tinte + afilado 70 %"; color: "#8b9199"; font.pixelSize: 11 }
    Row46 { base: "file:///tmp/ito-lab/art-sharp/" } }
  Timer { interval: 1200; running: true; onTriggered: root.grabToImage(function(r) { r.saveToFile("/tmp/ito-lab/out.png"); Qt.quit() }) }
}
