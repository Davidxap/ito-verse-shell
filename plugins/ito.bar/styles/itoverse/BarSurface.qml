pragma ComponentBehavior: Bound

import QtQuick
import "../shibumi" as Fork

// The Ito-verse surface.
//
// The fork's surface is not just a background: it hosts the whole widget layout, the drag handling
// and the shell forms, and the panel only ever hands it `layoutSession` and `screenName`. So it is
// kept intact and made see-through by the tokens, and the texture reaches it through the `runPlate`
// token (see RunPlate.qml), which is what lets a split island carry the same plate as a joined bar.
Item {
  id: root

  required property var bar
  property var layoutSession: null
  property string screenName: ""

  Fork.BarSurface {
    anchors.fill: parent
    bar: root.bar
    layoutSession: root.layoutSession
    screenName: root.screenName
  }
}
