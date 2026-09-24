import QtQuick
import Quickshell
import qs.Ui as Ui
import "../../bar/modules" as Ito

// Ito clock: the time as a serif numeral, no letters and no icon. The full date, with its
// words, lives in the tooltip. Written for Ito-verse, not ported from the stock clock.
Ui.BarWidget {
  id: root
  moduleName: "ito.clock"

  Ito.ItoConfig {
    id: cfg
    path: Qt.resolvedUrl("../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  readonly property color blood: cfg.blood
  property bool calendarOpen: false
  readonly property real k: root.barSize / 52

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
    labelVisible: false
    hasVisualContent: true
    horizontalMargin: 5
    fixedWidth: vertical ? barSize : face.implicitWidth + scaledHorizontalMargin * 2
    fixedHeight: vertical ? stacked.height + scaledVerticalPadding * 2 : barSize
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.calendarOpen = !root.calendarOpen
    }

    // The colon is the one red thing in the clock, so the hour reads as two halves rather than as a
    // number. Rich text keeps it one laid-out line, so nothing jumps when a digit changes width.
    // On a vertical bar the hour sits over the minutes, with the one red mark between them.
    Column {
      id: stacked
      visible: root.vertical
      anchors.centerIn: parent
      spacing: 1

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(clock.date, "HH")
        color: cfg.bone
        font.family: "Noto Serif CJK JP"
        font.weight: Font.Medium
        font.pixelSize: Math.round(17 * root.k)
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 10
        height: 2
        radius: 1
        color: root.blood
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(clock.date, "mm")
        color: cfg.bone
        font.family: "Noto Serif CJK JP"
        font.weight: Font.Medium
        font.pixelSize: Math.round(17 * root.k)
      }
    }

    Text {
      id: face
      visible: !root.vertical
      anchors.centerIn: parent
      textFormat: Text.StyledText
      text: Qt.formatTime(clock.date, "HH") + "<font color=\'" + root.blood + "\'>:</font>"
        + Qt.formatTime(clock.date, "mm")
      color: cfg.bone
      opacity: button.tooltipHovered ? 1 : 0.92
      font.family: "Noto Serif CJK JP"
      font.weight: Font.Medium
      font.pixelSize: Math.round(19 * root.k)
      font.letterSpacing: 1.5

      Behavior on opacity { NumberAnimation { duration: 140 } }
    }
  }

  // The clock and the date open the same calendar; this is the clock's copy of it.
  Ito.ItoCalendar {
    open: root.calendarOpen
    closeAfter: Number(cfg.get("popupSeconds", 3))
    onExpired: root.calendarOpen = false
    bar: root.bar
    palette: cfg
  }
}
