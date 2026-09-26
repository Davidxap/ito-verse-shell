import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui as Ui
import "../../bar/modules" as Ito
import "../../bar/modules/ItoMotion.js" as Motion

// Ito workspaces — theme artwork driven by live Hyprland state.
//
// Plugin form of the old bar/modules/ito-workspaces.qml. The ito.bar host loads
// registered plugins by id and has no support for `type: qml` entries.
//
// UNBREAKABLE ART RULES (see docs/ART_RULES.md):
//   1. A workspace's art is chosen by its STATE, never by its number. The only
//      exception is the numerals style, whose whole point is showing the digit.
//   2. Each style declares exactly four arts: empty, occupied, active, urgent.
//      A style never borrows art from another style, so a workspace id the
//      style does not cover can never fall through to a foreign look.
//   3. The art carries the blood. No ColorOverlay tints a workspace on focus:
//      tinting a red asset red again is what produced the "super red" bug.
//   4. No letters. The numerals style draws pre-rendered seals, not text.
Ui.BarWidget {
  id: root
  readonly property string host: Qt.resolvedUrl("../../bar/modules/bin/ito-host").toString().replace("file://", "")
  moduleName: "ito.workspaces"

  // Settings come from the sidecar first, because the engine rewrites
  // shell.json under us. Layout entries stay as a fallback for compatibility.
  Ito.ItoConfig {
    id: cfg
    path: Qt.resolvedUrl("../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  readonly property string wsStyle: cfg.get("style", setting("style", "orbs"))
  // Standard glyph size shared by every bar icon (the centre seal is the only exception).
  readonly property int artSize: cfg.get("size", setting("size", Math.round(root.barSize * cfg.get("iconScale", 0.62))))
  readonly property string art: "../../bar/modules/ito-art/"
  readonly property string home: Quickshell.env("HOME")

  // Rule 2: every style declares its four states up front.
  readonly property var styleArt: ({
    "orbs": {
      "empty":    "workspaces/workspace-1.png",
      "occupied": "workspaces/workspace-1.png",
      "active":   "workspaces/workspace-2.png",
      "urgent":   "workspaces/workspace-urgent.png"
    },
    // Tomie (the sheet's eyes and lips): even slots are eyes, odd slots are lips.
    "eyes": {
      "empty":    ["status-eyes/eye-normal.png", "status-eyes/eye-closed.png"],
      "occupied": ["status-eyes/eye-normal.png", "status-eyes/eye-closed.png"],
      "active":   "status-eyes/eye-red.png",
      "urgent":   "status-eyes/eye-bleeding.png"
    },
    // Uzumaki: a spiral with as many arms as the workspace number (1 to 5, and 6 to 10 wear an outer ring), so
    // every workspace has a face of its own without a digit. artFor() fills the number in.
    "uzumaki": { "empty": "empty", "occupied": "occupied", "active": "active", "urgent": "urgent" },
    // Remina: the planet with one eye; artFor() picks the file by number and state, like Uzumaki.
    "remina": { "empty": "empty", "occupied": "occupied", "active": "active", "urgent": "urgent" },
    // Dots: the sheet's target-dot is the ACTIVE marker, the plain red dot flags urgent.
    "dots": {
      "empty":    "workspace-indicators/indicator-empty.png",
      "occupied": "workspace-indicators/indicator-inactive.png",
      "active":   "workspace-indicators/indicator-urgent.png",
      "urgent":   "workspace-indicators/indicator-active.png"
    },
    // Halo: Silent Hill 3's own save-point seal. As many big spikes as the workspace number, the way
    // Uzumaki has one arm more per workspace -- artFor() fills the number in.
    "halo": { "empty": "empty", "occupied": "occupied", "active": "active", "urgent": "urgent" },
    // Flauros: the puzzle's own seal (a broken ring, a triangle, the thing coiled inside it), not
    // Metatron again -- that one already stands for the shell on the Logo page. The coil winds one turn
    // tighter per workspace number, like Remina's tendrils; artFor() picks the file by number and state.
    "flauros": { "empty": "empty", "occupied": "occupied", "active": "active", "urgent": "urgent" }
  })

  // Each bar shows the workspaces of its own screen. Listing every monitor's workspaces put a second screen's
  // workspace (a projector, a virtual output) on this bar as if it were here, and clicking it moved the view away.
  readonly property var screenObj: root.QsWindow.window ? root.QsWindow.window.screen : null
  readonly property var monitor: screenObj ? Hyprland.monitorFor(screenObj) : null
  readonly property string monitorName: monitor ? String(monitor.name || "") : ""

  function onThisScreen(ws) {
    if (!ws) return true
    // Which monitor this bar is on isn't known yet for a moment at startup or after a hot-plug. Showing
    // nothing for that moment is safe; showing every screen's workspaces as if they were this one (the old
    // behaviour here) is exactly the bug this function exists to prevent.
    if (root.monitorName === "") return false
    return !ws.monitor || String(ws.monitor.name || "") === root.monitorName
  }

  // The workspace this screen is showing, which is the one that is lit here even while another screen has focus.
  readonly property int shownId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id
    : (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1)

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      // a workspace that lives on another screen is not "occupied" here
      if (values[i].id === id && root.onThisScreen(values[i])) return values[i]
    }
    return null
  }

  // "used" shows only the workspaces that have something in them (and the one you are on); "count" always
  // draws the first N, so the row never changes width as you work.
  // Styles whose art for an empty workspace is the same drawing as an occupied one (rings, seals, eyes and lips)
  // dim the empty ones so they are told apart. Marks and Uzumaki draw an empty one differently already, so they
  // are not dimmed twice.
  readonly property bool emptyLooksOccupied: wsStyle === "numerals" || wsStyle === "orbs" || wsStyle === "eyes"
  readonly property string showMode: cfg.get("workspaceShow", "count")

  function inUse(id) {
    var ws = root.workspaceById(id)
    if (ws !== null && ws.toplevels.values.length > 0) return true
    if (ws !== null && ws.urgent === true) return true
    return root.shownId === id
  }

  function workspaceIds() {
    var ids = []
    if (root.showMode === "used") {
      var values = Hyprland.workspaces.values
      for (var v = 0; v < values.length; v++) {
        var wid = values[v].id
        if (wid > 0 && wid <= 10 && root.onThisScreen(values[v]) && root.inUse(wid) && ids.indexOf(wid) === -1) ids.push(wid)
      }
      if (root.shownId > 0 && root.shownId <= 10 && ids.indexOf(root.shownId) === -1) ids.push(root.shownId)
      ids.sort(function(left, right) { return left - right })
      return ids.length ? ids : [1]
    }
    for (var n = 1; n <= Math.max(1, Math.min(10, Math.round(Number(cfg.get("workspaceCount", 5))))); n++) ids.push(n)
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && root.onThisScreen(values[i]) && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run(host + " workspace " + id)
  }

  function stateOf(focused, occupied, urgent) {
    if (urgent) return "urgent"
    if (focused) return "active"
    return occupied ? "occupied" : "empty"
  }

  // Rule 1 + 2: state picks the art, and a style only ever uses its own set.
  function artFor(id, slot, focused, occupied, urgent) {
    var state = root.stateOf(focused, occupied, urgent)

    // The user's own pictures, one per state (Workspaces page -> Custom), adapted into the cache by ito-marks.
    // The stamp makes the bar reload a picture that was just replaced.
    if (root.wsStyle === "custom")
      return "@" + root.home + "/.cache/ito/marks/_ws-" + state + ".png?v=" + cfg.get("wsCustomVer", 0)

    if (root.wsStyle === "numerals") {
      // The digit IS the art here, pre-rendered so rule 4 still holds.
      if (id < 1 || id > 10) return ""
      var red = (state === "active" || state === "urgent")
      return "workspace-labels/ws-" + id + (red ? "-red" : "") + ".png"
    }

    if (root.wsStyle === "uzumaki" || root.wsStyle === "remina" || root.wsStyle === "halo" || root.wsStyle === "flauros") {
      var n = Math.max(1, Math.min(10, id))
      return "workspaces/ws-" + root.wsStyle + "-" + n + "-" + state + ".png"
    }

    var set = root.styleArt[root.wsStyle] || root.styleArt["orbs"]
    var pick = set[state]
    return Array.isArray(pick) ? pick[slot % pick.length] : pick
  }

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  // One row on a horizontal bar, one column on a vertical one.
  // Centred on the widget's own slot, not hung from its top: the slot is shorter than the bar (35 of 46), so a row
  // that fills the bar sticks out below the slot and every mark sits low against the other widgets.
  GridLayout {
    id: row
    anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
    anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
    columns: root.vertical ? 1 : 99
    rowSpacing: 3
    columnSpacing: 3

    Repeater {
      model: root.workspaceIds()

      Ui.WidgetButton {
        id: wsButton
        required property int modelData
        required property int index

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: root.shownId === modelData
        readonly property bool urgent: workspace !== null && workspace.urgent === true
        readonly property string art: root.artFor(modelData, index, focused, occupied, urgent)
        readonly property bool isDots: root.wsStyle === "dots"

        bar: root.bar
        tooltipText: "Workspace " + modelData
        text: ""
        labelVisible: false
        hasVisualContent: true
        horizontalMargin: 3
        verticalPadding: 4
        // A workspace with nothing in it recedes clearly, in every style, so an empty one made by pressing its number
        // never reads as one with something running in it. One with windows is at full strength. Rule 3.
        opacity: focused ? 1 : (occupied ? 0.96 : (root.emptyLooksOccupied ? 0.5 : 0.85))
        fixedWidth: root.vertical ? root.barSize : artItem.width + scaledHorizontalMargin * 2
        fixedHeight: root.vertical ? artItem.height + scaledVerticalPadding * 2 + 2 : root.barSize

        Behavior on opacity {
          NumberAnimation { duration: Math.round(Motion.normal * Math.min(cfg.motionAmp, 1.4)); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.soft }
        }

        onPressed: function() { root.focusWorkspace(modelData) }

        Item {
          id: artItem
          anchors.centerIn: parent
          width: isDots ? root.artSize : root.artSize
          height: width

          Ito.ItoImage {
            id: seal
            palette: cfg
            anchors.fill: parent
            source: wsButton.art === "" ? "" : (wsButton.art.charAt(0) === "@" ? "file://" + wsButton.art.substring(1) : Qt.resolvedUrl(root.art + wsButton.art))
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            // A state change eases in; nothing animates while idle.
            scale: wsButton.focused && !wsButton.isDots ? 1.08 : 1.0

            // arriving on a workspace, its mark pops out with a little overshoot and settles
            Behavior on scale {
              NumberAnimation { duration: Math.round(Motion.slow * Math.min(cfg.motionAmp, 1.4)); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.spring }
            }
          }
        }
      }
    }
  }
}
