import QtQuick
import "../../bar/modules" as Ito
Rectangle {
  id: root; width: 400; height: 80; color: "#0b0d0e"
  Ito.ItoMediaFx { x: 20; y: 20; width: 360; height: 36; radius: 18; kind: "custom"; active: true; customSource: "file:///tmp/ito-lab/t.gif" }
  Timer { interval: 1500; running: true; onTriggered: root.grabToImage(function(r) { r.saveToFile("/tmp/ito-lab/out.png"); Qt.quit() }) }
}
