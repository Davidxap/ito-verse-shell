import QtQuick
import "../../bar/modules"
import "../../bar/modules/ItoSurfaces.js" as Surfaces

// The bar's own row, offscreen: every icon at the real size, on the real plate, so alignment and weight
// can be judged without taking the desktop's shell away from whoever is using it.
Rectangle {
  id: root
  width: 1500; height: 260
  gradient: Gradient { orientation: Gradient.Horizontal
    GradientStop { position: 0; color: "#2b2340" }
    GradientStop { position: 1; color: "#17414d" } }

  readonly property url art: "../../bar/modules/ito-art/"
  readonly property url inst: art + "instruments/"
  readonly property int bar: 46
  readonly property int glyph: Math.round(bar * 0.62)

  QtObject {
    id: pal
    readonly property color blood: "#c4162a"
    readonly property color lit: "#d92038"
    readonly property color bone: "#c7ccd1"
    readonly property bool tinted: false
    function get(k, f) { return f }
  }

  component Reading: Row {
    property alias source: art.source
    property string value: ""
    spacing: 4
    ItoImage { id: art; width: root.glyph; height: root.glyph; palette: pal
      anchors.verticalCenter: parent.verticalCenter }
    Text { visible: value !== ""; text: value; color: pal.bone; font.family: "Noto Serif"
      font.pixelSize: Math.round(root.bar * 0.30); font.weight: Font.DemiBold
      anchors.verticalCenter: parent.verticalCenter }
  }

  // the plate, at the real height
  Item {
    x: 20; y: 40
    width: root.width - 40
    height: root.bar

    ItoPlate {
      anchors.fill: parent
      anchors.topMargin: 3
      anchors.bottomMargin: 3
      radius: 20
      artBase: root.art
      palette: pal
      veins: 0; wood: 0; calm: 0.4; grain: 0.14; tone: 0; lift: 0; border: true
    }

    Row {
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12

      ItoImage { width: root.glyph; height: root.glyph; palette: pal
        source: root.art + "system/menu-uzumaki.png"; anchors.verticalCenter: parent.verticalCenter }
      Row {
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
          model: ["ws-1", "ws-2-red", "ws-3", "ws-4", "ws-5"]
          ItoImage { required property string modelData; width: root.glyph; height: root.glyph
            palette: pal; source: root.art + "workspace-labels/" + modelData + ".png" }
        }
      }
    }

    Row {
      anchors.centerIn: parent
      spacing: 10
      Text { text: "13:42"; color: pal.bone; font.family: "Noto Serif"; font.pixelSize: 19
        anchors.verticalCenter: parent.verticalCenter }
      Row {
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter
        ItoImage { width: 18; height: 40; palette: pal; source: root.art + "tomie/tomie-vein.png" }
        Text { text: "富\n江"; color: pal.bone; font.family: "Noto Serif CJK JP"; font.weight: Font.Bold
          font.pixelSize: 15; lineHeight: 0.78; lineHeightMode: Text.ProportionalHeight
          horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
        ItoImage { width: 18; height: 40; palette: pal; mirror: true; source: root.art + "tomie/tomie-vein.png" }
      }
      Text { text: "sun 20"; color: pal.bone; opacity: 0.85; font.family: "Noto Serif"
        font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12

      Reading { source: root.inst + "sky-rain.png"; value: "20°" }
      Reading { source: root.art + "system/jar.png"; value: "3" }
      Reading { source: root.inst + "net-3.png" }
      Reading { source: root.inst + "bt-linked.png" }
      Reading { source: root.inst + "vol-2.png"; value: "45%" }
      Reading { source: root.inst + "sun-3.png"; value: "80%" }
      Reading { source: root.inst + "bat-3.png"; value: "76%" }
      Reading { source: root.art + "system/brain.png"; value: "35%" }
      Reading { source: root.art + "workspace-indicators/indicator-active.png"; value: "7%" }
      Reading { source: root.art + "status-eyes/eye-normal.png"; value: "22%" }
      Reading { source: root.art + "system/brain.png"; value: "44%" }
    }
  }

  Timer { interval: 1800; running: true; onTriggered: root.grabToImage(function(r) {
    r.saveToFile("/tmp/ito-lab/out.png"); Qt.quit() }) }
}
