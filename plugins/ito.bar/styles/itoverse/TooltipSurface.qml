import QtQuick

// Ito-verse tooltip: an ink bubble, bone text and a thin blood edge.
//
// Written to tolerate a host that has not injected `bar` yet. The fork's own tooltip
// dereferences bar.visualTokens without a guard and throws a TypeError at startup; the same
// mistake, repeated across Shibumi's widgets, accounts for nearly all of its journal errors.
Item {
  id: root

  property var bar: null
  readonly property var tokens: bar && bar.visualTokens ? bar.visualTokens : null
  readonly property string resolvedText: {
    const target = bar ? bar.tooltipTarget : null
    return target && target.tooltipText !== undefined
      ? String(target.tooltipText) : String(bar ? bar.tooltipText || "" : "")
  }

  implicitWidth: bubble.implicitWidth
  implicitHeight: bubble.implicitHeight

  Rectangle {
    id: bubble

    anchors.fill: parent
    implicitWidth: label.implicitWidth + 2 * (root.tokens ? root.tokens.tooltipPaddingX : 10)
    implicitHeight: label.implicitHeight + 2 * (root.tokens ? root.tokens.tooltipPaddingY : 4)
    color: "#14181b"
    border.color: "#5d1926"
    border.width: 1
    radius: root.tokens ? root.tokens.tooltipRadius : 6

    Text {
      id: label

      anchors.centerIn: parent
      text: root.resolvedText
      color: "#c7ccd1"
      font.family: "Noto Serif CJK JP"
      font.pixelSize: 12
      font.letterSpacing: 0.5
      renderType: Text.NativeRendering
    }
  }
}
