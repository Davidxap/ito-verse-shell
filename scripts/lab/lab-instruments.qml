import QtQuick
import "../../bar/modules"

Rectangle {
  id: root
  width: 1000; height: 640; color: "#050607"
  readonly property var rows: [
    { kind: "net",  values: [-1, 0.2, 0.5, 0.8, 1] },
    { kind: "vol",  values: [-1, 0.1, 0.4, 0.7, 1] },
    { kind: "sun",  values: [0.1, 0.3, 0.5, 0.8, 1] },
    { kind: "bluetooth", values: [-1, 0, 0, 1, 1] },
    { kind: "battery", values: [0.1, 0.35, 0.6, 0.85, 1] }
  ]
  Column { x: 20; y: 16; spacing: 14
    Repeater { model: root.rows
      Row { required property var modelData; spacing: 26
        Text { width: 40; text: parent.modelData.kind; color: "#8b9199"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        Repeater { model: parent.modelData.values
          ItoGlyph { required property real modelData; kind: parent.modelData.kind; value: modelData; active: parent.modelData.kind === "bluetooth" ? modelData >= 1 : parent.modelData.kind === "battery" && modelData > 0.8; size: 96; bone: "#c7ccd1"; blood: "#d60a25"; ink: "#050607"; seed: 5 } } } } }
  Row { x: 60; y: 560; spacing: 12
    Repeater { model: root.rows
      Row { required property var modelData; spacing: 8
        Repeater { model: parent.modelData.values
          ItoGlyph { required property real modelData; kind: parent.modelData.kind; value: modelData; size: 31; bone: "#c7ccd1"; blood: "#d60a25"; ink: "#050607"; seed: 5 } } } } }
  Timer { interval: 1400; running: true; onTriggered: root.grabToImage(function(r) { r.saveToFile("/tmp/ito-lab/out.png"); Qt.quit() }) }
}
