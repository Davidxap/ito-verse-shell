import QtQuick
import "../../../../bar/modules" as Ito
import "../../../../bar/modules/ItoSurfaces.js" as Surfaces

// One plate for one run of the bar.
//
// The fork already knows how to cut the bar into runs (Shibumi's split islands) and paints each one
// through RunChrome. That paints a flat rectangle; a style can hand it a plate instead through the
// `runPlate` token, so every island — joined or split — carries the same surface.
//
// What the plate is made of is all sidecar: one `fx*` flag per layer, folded by Surfaces.resolve.
Ito.ItoPlate {
  palette: cfg
  id: root

  Ito.ItoConfig {
    id: cfg
    path: Qt.resolvedUrl("../../../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  readonly property var look: Surfaces.resolve(cfg)

  // The run's own corner: a floating island is a pill, a screen-edge form keeps the fork's radius.
  property int cornerRadius: Math.floor(height / 2)
  radius: cornerRadius
  artBase: Qt.resolvedUrl("../../../../bar/modules/ito-art/")
  plate: look.plate
  veins: look.veins
  wood: look.wood
  calm: look.calm
  grain: look.grain
  tone: look.tone
  lift: look.lift
  border: look.border
  torn: look.torn
  fog: look.fog
}
