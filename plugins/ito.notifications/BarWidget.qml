import QtQuick
import Quickshell.Io
import qs.Ui as Ui
import "../../bar/modules" as Ito

// Ito notifications: the sheet's bell. Still when nothing is waiting, in blood when something is, and the eye
// that watches instead when they are silenced. Click toggles Do Not Disturb.
//
// Written against the notification service Omarchy provides when the shell hands it over (that also gives the
// count of what is waiting). When it does not, Do Not Disturb is still read and flipped through ito-host, so the
// bell and its click keep working; only the waiting count needs the service.
Ui.BarWidget {
  id: root
  moduleName: "ito.notifications"

  Ito.ItoConfig {
    id: cfg
    path: Qt.resolvedUrl("../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  readonly property url art: Qt.resolvedUrl("../../bar/modules/ito-art/notifications/")
  readonly property int glyph: Math.round(root.barSize * cfg.get("iconScale", 0.62))
  readonly property var service: root.bar && root.bar.shell && typeof root.bar.shell.firstPartyServiceFor === "function"
    ? root.bar.shell.firstPartyServiceFor("omarchy.notifications") : null
  readonly property string host: Qt.resolvedUrl("../../bar/modules/bin/ito-host").toString().replace("file://", "")
  property bool dndPolled: false
  readonly property bool silenced: service ? service.doNotDisturb === true : dndPolled
  readonly property int waiting: service && service.popupModel ? service.popupModel.count : 0
  readonly property string face: silenced ? "notification-dnd" : (waiting > 0 ? "notification-active" : "notification")

  // Something new arrives: a drop of blood falls from the bell.
  property int seen: 0
  onWaitingChanged: {
    if (waiting > seen) drop.restart()
    seen = waiting
  }

  Process {
    id: dndProbe
    command: [root.host, "dnd", "status"]
    stdout: StdioCollector { onStreamFinished: root.dndPolled = text.trim() === "on" }
  }
  Process {
    id: dndToggle
    onExited: dndSoon.restart()
  }
  Timer { id: dndSoon; interval: 600; onTriggered: if (!dndProbe.running) dndProbe.running = true }
  // only needed while there is no service to ask
  Timer { interval: 4000; running: !root.service; repeat: true; triggeredOnStart: true; onTriggered: if (!dndProbe.running) dndProbe.running = true }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: root.silenced ? "Notifications silenced" : (root.waiting > 0 ? root.waiting + " waiting" : "No notifications")
    labelVisible: false
    hasVisualContent: true
    horizontalMargin: 6
    fixedWidth: vertical ? barSize : root.glyph + scaledHorizontalMargin * 2
    fixedHeight: vertical ? root.glyph + scaledVerticalPadding * 2 : barSize
    onPressed: function(mouseButton) {
      if (mouseButton !== Qt.LeftButton) return
      if (root.service && typeof root.service.setDoNotDisturb === "function") {
        root.service.setDoNotDisturb(!root.silenced)
      } else if (!dndToggle.running) {
        root.dndPolled = !root.dndPolled                          // answers at once; the probe confirms it
        dndToggle.command = [root.host, "dnd", "toggle"]
        dndToggle.running = true
      }
    }

    Rectangle {
      id: dropMark
      z: 5
      width: 6
      height: 8
      radius: 3
      color: cfg.blood
      x: (parent.width - width) / 2
      y: parent.height * 0.55
      opacity: 0
    }

    ParallelAnimation {
      id: drop
      NumberAnimation { target: dropMark; property: "y"; from: button.height * 0.5; to: button.height * 1.0; duration: 900
                        easing.type: Easing.InQuad }
      SequentialAnimation {
        NumberAnimation { target: dropMark; property: "opacity"; from: 0; to: 0.95; duration: 120 }
        PauseAnimation { duration: 500 }
        NumberAnimation { target: dropMark; property: "opacity"; to: 0; duration: 280 }
      }
    }

    Ito.ItoImage {
      palette: cfg
      anchors.centerIn: parent
      width: root.glyph
      height: root.glyph
      source: root.art + root.face + ".png"
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true
      // the bell rings a little when something new arrives
      transformOrigin: Item.Top
      rotation: 0
      scale: button.tooltipHovered ? 1.1 : 1
      Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
  }
}
