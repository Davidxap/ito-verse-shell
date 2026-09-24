import QtQuick
import QtQuick.Layouts
import "../../bar/modules" as Ito

// The Icons page with a stand-in for the control centre, so the layout can be seen without opening the panel.
// Saves /tmp/ito-lab/out.png.
Rectangle {
  id: root
  width: 880; height: 1000; color: "#0b0d0e"

  QtObject {
    id: cfg
    property color bone: "#c7ccd1"
    property color blood: "#c4162a"
    property color lit: "#8a86d8"
    function get(k, f) { return f }
  }

  QtObject {
    id: acts
    property var off: ["ito.weather", "ito.disk"]
    function widgetOn(id) { return off.indexOf(id) < 0 }
    function contentOf(id) { return "both" }
    function widgetsIn(r) {
      return ({ left: ["ito.spiral", "ito.workspaces", "ito.clock", "ito.weather"],
                center: ["ito.tomie"],
                right: ["ito.notifications", "ito.indicators", "ito.media", "ito.network", "ito.audio", "ito.ai", "ito.cpu", "ito.disk"] })[r]
    }
    function regionOf(id) { return widgetsIn("left").indexOf(id) >= 0 ? "left" : widgetsIn("center").indexOf(id) >= 0 ? "center" : widgetsIn("right").indexOf(id) >= 0 ? "right" : "" }
    function set(k, v) {}
    function setWidget() {}
    function cycleContent() {}
    function nudgeWidget() {}
    function sendWidget() {}
    function addPlugin() {}
  }
  QtObject {
    id: fakeCc
    property var pal: cfg
    property var actions: acts
    property string hint: ""
    property string query: ""
    function match(t) { return true }
  }

  Flickable {
    anchors.fill: parent; anchors.margins: 20
    contentHeight: pageLoader.item ? pageLoader.item.implicitHeight : 0
    Loader { id: pageLoader; width: parent.width; Component.onCompleted: setSource("../../bar/modules/cc/PageWidgets.qml", { "cc": fakeCc }) }
  }
  Timer { interval: 1800; running: true; onTriggered: root.grabToImage(function(r) { r.saveToFile("/tmp/ito-lab/out.png"); Qt.quit() }) }
}
