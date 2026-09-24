import QtQuick
import "../../bar/modules"
import "../../bar/modules/ItoSurfaces.js" as Surfaces

Rectangle {
  id: root
  width: 1400; height: 420
  gradient: Gradient { orientation: Gradient.Horizontal
    GradientStop { position: 0; color: "#3a2a57" }
    GradientStop { position: 1; color: "#1d5a6b" } }
  readonly property url art: "../../bar/modules/ito-art/"
  Column { x: 24; y: 18; spacing: 12
    Repeater { model: Surfaces.bases
      Column { required property string modelData; spacing: 4
        Text { text: Surfaces.getBase(parent.modelData).name; color: "#e7e9ec"; font.pixelSize: 12 }
        ItoPlate { width: 1340; height: 40; radius: 20; artBase: root.art
          plate: Surfaces.getBase(parent.modelData).opacity
          grain: Surfaces.getBase(parent.modelData).grain
          tone: Surfaces.getBase(parent.modelData).tone
          wood: Surfaces.getBase(parent.modelData).wood === undefined ? 0 : Surfaces.getBase(parent.modelData).wood
          lift: Surfaces.getBase(parent.modelData).lift === undefined ? 0 : Surfaces.getBase(parent.modelData).lift
          veins: 0; calm: 0; border: true } } } }
  Timer { interval: 1600; running: true; onTriggered: root.grabToImage(function(r) { r.saveToFile("/tmp/ito-lab/out.png"); Qt.quit() }) }
}
