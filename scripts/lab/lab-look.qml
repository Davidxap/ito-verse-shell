import QtQuick
import "../../bar/modules"
import "../../bar/modules/ItoSurfaces.js" as Surfaces

// Every look layer on its own, on the same plate, to see that each one does something.
Rectangle {
  id: root
  width: 1200; height: 760; color: "#1a2730"
  readonly property url art: "file:///mnt/DATA/Themes/ito-verse/Ito-verse/bar/modules/ito-art/"
  readonly property var cases: [
    ["base", { fxPlate: true, fxGrain: false, fxCalm: false, fxBorder: false }],
    ["glass", { fxPlate: true, fxGlass: true, fxGrain: false, fxCalm: false, fxBorder: false }],
    ["paper", { fxPlate: true, fxPaper: true, fxGrain: false, fxCalm: false, fxBorder: false }],
    ["blood", { fxPlate: true, fxBlood: true, fxGrain: false, fxCalm: false, fxBorder: false }],
    ["wood", { fxPlate: true, fxWood: true, fxGrain: false, fxCalm: false, fxBorder: false }],
    ["tone", { fxPlate: true, fxTone: true, fxGrain: false, fxCalm: false, fxBorder: false }],
    ["grain", { fxPlate: true, fxGrain: true, fxCalm: false, fxBorder: false }],
    ["calm+blood", { fxPlate: true, fxBlood: true, fxCalm: true, fxGrain: false, fxBorder: false }],
    ["border", { fxPlate: true, fxGrain: false, fxCalm: false, fxBorder: true }],
    ["opacity .4", { fxPlate: true, fxGrain: false, fxCalm: false, fxBorder: false, surfaceOpacity: 0.4 }],
    ["no plate", { fxPlate: false, fxGrain: false, fxCalm: false, fxBorder: false }]
  ]
  Column {
    x: 20; y: 10; spacing: 6
    Repeater {
      model: root.cases
      Row {
        id: line
        required property var modelData
        spacing: 12
        readonly property var flags: modelData[1]
        readonly property var fake: ({ get: function(k, f) { return line.flags[k] !== undefined ? line.flags[k] : f } })
        readonly property var look: Surfaces.resolve(fake)
        Text { width: 90; height: 46; verticalAlignment: Text.AlignVCenter; color: "#c7ccd1"; text: line.modelData[0]; font.pixelSize: 12 }
        ItoPlate {
          width: 1000; height: 46; radius: 23; artBase: root.art
          plate: line.look.plate; veins: line.look.veins; wood: line.look.wood; calm: line.look.calm
          grain: line.look.grain; tone: line.look.tone; lift: line.look.lift; border: line.look.border
        }
      }
    }
  }
  Timer { interval: 1500; running: true; onTriggered: root.grabToImage(function(r) { r.saveToFile("/tmp/ito-lab/out.png"); Qt.quit() }) }
}
