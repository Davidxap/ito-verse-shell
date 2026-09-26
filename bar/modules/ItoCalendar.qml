import QtQuick
import QtQuick.Layouts
import Quickshell
import "ItoMotion.js" as Motion

// The clock and calendar panel, opened from the time or the date in the bar.
//
// A big time with the colon in blood, the date under it, and a month you can page through. Today is
// ringed the way the active workspace is. It slides down out of the bar and fades in, and the month
// crossfades when you turn the page; nothing moves while it is closed.
PanelWindow {
  id: root

  property bool open: false
  // Seconds it stays once the pointer is off it; 0 keeps it until the next click. Handed in by the widget.
  property real closeAfter: 3
  signal expired()
  property var bar: null
  // The shell's colours (an ItoConfig), handed in by whichever widget opened the calendar.
  property var palette: null
  readonly property color blood: palette ? palette.blood : "#c4162a"
  readonly property color bone: palette ? palette.bone : "#c7ccd1"
  property url artBase: Qt.resolvedUrl("ito-art/")

  // The Motion setting: 0 is instant, 1 the default, more is slower and wider.
  readonly property real amp: palette && palette.motionAmp !== undefined ? palette.motionAmp : 1

  readonly property int headroom: palette ? palette.panelHeadroom : 0

  // 0 closed .. 1 open. The window stays alive until the close animation has finished.
  property real reveal: open ? 1 : 0
  Behavior on reveal {
    NumberAnimation {
      duration: Math.round((root.open ? Motion.slow : Motion.normal) * Math.min(root.amp, 1.4))
      easing.type: Easing.BezierSpline
      easing.bezierCurve: root.open ? Motion.spring : Motion.accel
    }
  }

  // Beside the bar, whichever edge it is on: under it, above it, or next to it in the corner.
  readonly property string pos: root.bar && root.bar.position ? String(root.bar.position) : "top"
  readonly property int edge: (root.bar ? root.bar.barSize : 46) + 8

  visible: open || reveal > 0.01
  anchors.top: pos !== "bottom"
  anchors.bottom: pos === "bottom"
  anchors.left: pos === "left"
  anchors.right: pos === "right"
  margins.top: pos === "top" ? edge : 12
  margins.bottom: pos === "bottom" ? edge : 0
  margins.left: pos === "left" ? edge : 0
  margins.right: pos === "right" ? edge : 0
  exclusiveZone: 0
  implicitWidth: card.width + 24
  implicitHeight: card.height + 24
  color: "transparent"

  // ---------------------------------------------------------------- the month
  // The month being looked at, as the first of it. Turning the page moves this, not the clock.
  property date shown: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
  property date picked: new Date()
  property bool turning: false

  readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July",
                                     "August", "September", "October", "November", "December"]
  readonly property var dayNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  readonly property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

  SystemClock {
    id: clock
    precision: root.open ? SystemClock.Seconds : SystemClock.Minutes
  }

  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
  }

  // ISO week number of a date, so the left-hand column can carry it.
  function isoWeek(date) {
    var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    var day = d.getUTCDay() || 7
    d.setUTCDate(d.getUTCDate() + 4 - day)
    var start = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
    return Math.ceil(((d - start) / 86400000 + 1) / 7)
  }

  // Six rows of seven, Monday first, starting from the Monday on or before the 1st.
  function cells(month) {
    var first = new Date(month.getFullYear(), month.getMonth(), 1)
    var offset = (first.getDay() + 6) % 7
    var out = []
    for (var i = 0; i < 42; i++) {
      var d = new Date(first.getFullYear(), first.getMonth(), 1 - offset + i)
      out.push({ "date": d, "inMonth": d.getMonth() === month.getMonth() })
    }
    return out
  }

  readonly property var grid: cells(shown)

  function turn(step) {
    turning = true
    fade.step = step
    fade.restart()
  }

  function today() {
    var now = new Date()
    picked = now
    if (shown.getMonth() !== now.getMonth() || shown.getFullYear() !== now.getFullYear()) {
      shown = new Date(now.getFullYear(), now.getMonth(), 1)
    }
  }

  onOpenChanged: if (open) today()

  // page turn: the month slides out the way you turned, the next slides in from the other side
  SequentialAnimation {
    id: fade
    property int step: 1
    ParallelAnimation {
      NumberAnimation { target: gridBox; property: "opacity"; to: 0; duration: Motion.fast
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.accel }
      NumberAnimation { target: gridBox; property: "x"; to: -fade.step * 26; duration: Motion.fast
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.accel }
    }
    ScriptAction {
      script: {
        root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() + fade.step, 1)
        gridBox.x = fade.step * 26
      }
    }
    ParallelAnimation {
      NumberAnimation { target: gridBox; property: "opacity"; to: 1; duration: Motion.normal
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.decel }
      NumberAnimation { target: gridBox; property: "x"; to: 0; duration: Motion.normal
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.decel }
    }
    ScriptAction { script: root.turning = false }
  }

  // ------------------------------------------------------------------ the card
  HoverHandler { id: cardHover }
  ItoAutoClose { opened: root.open; hovered: cardHover.hovered; seconds: root.closeAfter; onExpired: root.expired() }

  Item {
    id: card
    width: 372
    height: content.implicitHeight + headroom + 62
    anchors.horizontalCenter: parent.horizontalCenter
    // it slides in from the bar, whichever side the bar is on
    y: root.pos === "bottom" ? parent.height - height - 12 + (1 - root.reveal) * 22 : 12 - (1 - root.reveal) * 22
    opacity: Math.min(1, root.reveal * 1.6)
    transformOrigin: root.pos === "bottom" ? Item.Bottom : Item.Top
    scale: 0.95 + 0.05 * root.reveal

    ItoPanelFrame { cfg: root.palette; target: card; emblem: "clock"; opened: root.open; memos: ["Time keeps its own count.", "Today has happened before.", "Another lap of the same hour.", "The days turn, and you with them."] }

    ColumnLayout {
      id: content
      x: 22
      y: 20 + headroom
      width: parent.width - 44
      spacing: 12

      // ------------------------------------------------------------- time and date
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
          textFormat: Text.StyledText
          text: Qt.formatTime(clock.date, "HH") + "<font color='" + root.blood + "'>:</font>"
            + Qt.formatTime(clock.date, "mm")
          color: root.bone
          font.family: "Noto Serif"
          font.pixelSize: 46
          font.weight: Font.Light
        }

        Text {
          visible: root.open
          text: Qt.formatTime(clock.date, "ss")
          color: root.blood
          opacity: 0.8
          font.family: "Noto Serif"
          font.pixelSize: 16
          Layout.alignment: Qt.AlignBottom
          Layout.bottomMargin: 8
        }

        Item { Layout.fillWidth: true }

        ColumnLayout {
          spacing: 1
          Layout.alignment: Qt.AlignVCenter

          Text {
            Layout.alignment: Qt.AlignRight
            text: root.dayNames[clock.date.getDay()]
            color: root.bone
            font.family: "Noto Serif"
            font.pixelSize: 14
          }

          Text {
            Layout.alignment: Qt.AlignRight
            text: clock.date.getDate() + " " + root.monthNames[clock.date.getMonth()]
            color: root.bone
            opacity: 0.6
            font.family: "Noto Serif"
            font.pixelSize: 12
          }
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: root.blood; opacity: 0.4 }

      // ------------------------------------------------------------- month header
      RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: [{ "label": "‹", "step": -1 }]

          Rectangle {
            required property var modelData
            Layout.preferredWidth: 30
            Layout.preferredHeight: 26
            radius: 13
            color: prev.containsMouse ? Qt.rgba(root.blood.r, root.blood.g, root.blood.b, 0.22) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
              anchors.centerIn: parent
              text: parent.modelData.label
              color: root.bone
              font.pixelSize: 18
            }

            MouseArea {
              id: prev
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.turn(parent.modelData.step)
            }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: 26

          Text {
            anchors.centerIn: parent
            text: root.monthNames[root.shown.getMonth()] + "  " + root.shown.getFullYear()
            color: root.bone
            font.family: "Noto Serif"
            font.pixelSize: 14
            font.letterSpacing: 1
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.today()
          }
        }

        Repeater {
          model: [{ "label": "›", "step": 1 }]

          Rectangle {
            required property var modelData
            Layout.preferredWidth: 30
            Layout.preferredHeight: 26
            radius: 13
            color: next.containsMouse ? Qt.rgba(root.blood.r, root.blood.g, root.blood.b, 0.22) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
              anchors.centerIn: parent
              text: parent.modelData.label
              color: root.bone
              font.pixelSize: 18
            }

            MouseArea {
              id: next
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.turn(parent.modelData.step)
            }
          }
        }
      }

      // ------------------------------------------------------------- the grid
      Item {
        id: gridBox
        Layout.fillWidth: true
        Layout.preferredHeight: 22 + 6 * 34

        GridLayout {
          anchors.fill: parent
          columns: 8
          rowSpacing: 0
          columnSpacing: 0

          // heading row: a blank over the week numbers, then Mo..Su
          Text {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 22
            text: "wk"
            color: root.bone
            opacity: 0.35
            font.family: "Noto Serif"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          Repeater {
            model: root.weekdays

            Text {
              required property string modelData
              required property int index
              Layout.fillWidth: true
              Layout.preferredHeight: 22
              text: modelData
              color: index >= 5 ? root.blood : root.bone
              opacity: index >= 5 ? 0.85 : 0.55
              font.family: "Noto Serif"
              font.pixelSize: 11
              font.letterSpacing: 1
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
          }

          // each row is a week number, then its seven days
          Repeater {
            model: 48

            Item {
              id: cell
              required property int index
              readonly property int week: Math.floor(index / 8)
              readonly property int col: index % 8
              readonly property var day: col === 0 ? null : root.grid[week * 7 + col - 1]
              readonly property bool isToday: !!day && root.sameDay(day.date, clock.date)
              readonly property bool isPicked: !!day && root.sameDay(day.date, root.picked)

              Layout.fillWidth: col !== 0
              Layout.preferredWidth: col === 0 ? 26 : -1
              Layout.preferredHeight: 34

              Text {
                visible: cell.col === 0
                anchors.centerIn: parent
                text: cell.col === 0 ? root.isoWeek(root.grid[cell.week * 7].date) : ""
                color: root.bone
                opacity: 0.3
                font.family: "Noto Serif"
                font.pixelSize: 10
              }

              // the picked day is a soft blood wash; today is a ring, as on the workspaces
              Rectangle {
                visible: !!cell.day
                anchors.centerIn: parent
                width: 28
                height: 28
                radius: 14
                color: cell.isPicked && !cell.isToday
                  ? Qt.rgba(root.blood.r, root.blood.g, root.blood.b, 0.28)
                  : (dayMouse.containsMouse ? Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.10) : "transparent")
                border.width: cell.isToday ? 1.5 : 0
                border.color: root.blood
                Behavior on color { ColorAnimation { duration: 120 } }
              }

              Text {
                visible: !!cell.day
                anchors.centerIn: parent
                text: cell.day ? cell.day.date.getDate() : ""
                color: cell.isToday ? root.bone : root.bone
                opacity: !cell.day ? 0 : (cell.day.inMonth ? (cell.isToday ? 1 : 0.85) : 0.25)
                font.family: "Noto Serif"
                font.pixelSize: 13
                font.weight: cell.isToday ? Font.DemiBold : Font.Normal
              }

              MouseArea {
                id: dayMouse
                anchors.fill: parent
                enabled: !!cell.day
                hoverEnabled: true
                onClicked: root.picked = cell.day.date
              }
            }
          }
        }
      }

      // ------------------------------------------------------------- footer
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: Qt.formatDate(root.picked, "dddd d MMMM yyyy")
          color: root.bone
          opacity: 0.6
          font.family: "Noto Serif"
          font.pixelSize: 11
        }

        Item { Layout.fillWidth: true }

        Text {
          text: "today"
          color: todayMouse.containsMouse ? root.blood : root.bone
          opacity: todayMouse.containsMouse ? 1 : 0.6
          font.family: "Noto Serif"
          font.pixelSize: 11
          font.letterSpacing: 1
          Behavior on color { ColorAnimation { duration: 120 } }

          MouseArea {
            id: todayMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            onClicked: root.today()
          }
        }
      }
    }
  }
}
