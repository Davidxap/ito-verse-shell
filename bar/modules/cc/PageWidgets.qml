import QtQuick
import QtQuick.Layouts
import ".." as Ito
import "../ItoWidgets.js" as Widgets
import "../ItoIcons.js" as Icons

// Icons: the bar's widgets laid out the way the bar is (left, centre, right), each with a switch to turn it on or
// off and arrows to move it, plus what each one shows.
ColumnLayout {
  id: page

  property var cc: null
  readonly property var pal: cc.pal
  readonly property var act: cc.actions
  readonly property color bone: pal.bone

  spacing: 10

  // ---------------------------------------------------------------- dragging a widget between the columns
  // The three columns, so a drag can tell which one the pointer is over; and where a drop would land, for the guide line.
  property var columns: ({})
  property string dragId: ""
  property string dragRegion: ""             // the column the dragged row belongs to (raised above its neighbours)
  property string dropRegion: ""
  property string dropBeforeId: ""           // the widget it would go in front of, "" for the end of the column
  property int dropIndex: 0

  function locate(sceneX, sceneY, movingId) {
    var names = ["left", "center", "right"], best = "", bestGap = 1e9
    for (var n = 0; n < names.length; n++) {
      var col = columns[names[n]]
      if (!col) continue
      var p = col.mapFromItem(null, sceneX, sceneY)
      var gap = p.x < 0 ? -p.x : (p.x > col.width ? p.x - col.width : 0)
      if (gap < bestGap) { bestGap = gap; best = names[n] }
    }
    if (best === "") return null
    var c = columns[best], q = c.mapFromItem(null, sceneX, sceneY), idx = 0, before = ""
    for (var i = 0; i < c.children.length; i++) {
      var r = c.children[i]
      if (r.wid === undefined || r.wid === movingId || !r.visible) continue
      if (r.y + r.height / 2 < q.y) idx++
      else if (before === "") before = r.wid
    }
    return { "region": best, "index": idx, "before": before }
  }

  function dragMoved(id, sx, sy) {
    var at = locate(sx, sy, id)
    if (!at) return
    dropRegion = at.region; dropBeforeId = at.before; dropIndex = at.index
  }

  function dragDone(id, sx, sy) {
    var at = locate(sx, sy, id)
    dragId = ""; dragRegion = ""; dropRegion = ""; dropBeforeId = ""
    if (at) page.act.moveWidgetTo(id, at.region, at.index)
  }

  readonly property var modeNames: ({ "both": "Icon + text", "icon": "Icon only", "text": "Text only" })

  // ---------------------------------------------------------------- readings
  CcSection {
    host: page.cc
    startOpen: true
    pal: page.pal
    label: "READINGS"
    note: "How a number beside an icon reads, everywhere at once."


    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: [
          { "key": "percent", "label": "42%",     "name": "Percent", "note": "How full or how loud, as a percentage: RAM 42%." },
          { "key": "amount",  "label": "17/32G",  "name": "Amount",  "note": "What is really in use out of the total: memory 17/32G, disk 210/930G. Loudness, load and the rest stay a percentage." },
          { "key": "number",  "label": "42",      "name": "Number",  "note": "The bare number, no unit." },
          { "key": "off",     "label": "—",       "name": "Off",     "note": "Icons only. No numbers on the bar." }
        ]

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 62
          Layout.preferredWidth: 1
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: String(page.pal.get("valueStyle", "percent")) === modelData.key
          visible: page.cc.match(modelData.name + " " + modelData.note + " readings")
          onActivated: page.act.set("valueStyle", modelData.key)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            text: modelData.label
            color: parent.current ? page.pal.lit : page.bone
            opacity: parent.current ? 1 : 0.75
            font.family: "Noto Serif"
            font.weight: Font.DemiBold
            font.pixelSize: 17
          }
        }
      }
    }


    CcToggle {
      Layout.fillWidth: true
      host: page.cc
      pal: page.pal
      label: "Name each reading (CPU 42%, RAM 17/32G)"
      hint: "Puts a small label before the number so you always know what it measures, the way Shibumi does. Horizontal bars only."
      on: page.pal.get("valueLabels", true) !== false
      onActivated: page.act.set("valueLabels", on ? "false" : "true")
    }


    CcMeter { host: page.cc; pal: page.pal; actions: page.act
      label: "Icon size"; key: "iconScale"; fallback: 0.62; lo: 0.5; hi: 0.8
      hint: "The one size every icon on the bar shares, as a share of the bar's height." }


    // ---------------------------------------------------------------- popups
    CcMeter { host: page.cc; pal: page.pal; actions: page.act; percent: false; unit: " s"; zeroLabel: "Never"
      label: "Close popups after"; key: "popupSeconds"; fallback: 3; lo: 0; hi: 15
      hint: "A widget's popup (calendar, volume, network...) closes by itself this many seconds after the pointer leaves it. Never keeps it open until you click again." }
  }


  CcSection {
    startOpen: true
    host: page.cc
    Layout.topMargin: 6
    pal: page.pal
    label: "YOUR BAR"
    note: "Three columns, the way the bar is laid out: left, centre, right; top to bottom is the order along the bar. Drag a widget by its grip to any place in any column, or use the arrows. The switch turns a widget on or off (it keeps its place)."


    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      Repeater {
        model: [
          { "region": "left",   "title": "LEFT" },
          { "region": "center", "title": "CENTRE" },
          { "region": "right",  "title": "RIGHT" }
        ]

        ColumnLayout {
          id: col
          required property var modelData
          readonly property var ids: page.act.widgetsIn(modelData.region)
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.alignment: Qt.AlignTop
          spacing: 6
          z: page.dragRegion === modelData.region ? 50 : 0
          Component.onCompleted: page.columns[modelData.region] = col

          Text {
            text: col.modelData.title
            color: page.bone
            opacity: 0.7
            font.family: "Noto Serif"
            font.pixelSize: 10
            font.letterSpacing: 3
          }

          Repeater {
            model: col.ids
            BarRow {
              required property string modelData
              required property int index
              wid: modelData
              region: col.modelData.region
              position: index
              count: col.ids.length
            }
          }

          Text {
            visible: col.ids.length === 0
            text: page.dragId !== "" && page.dropRegion === col.modelData.region ? "Drop it here." : "Nothing here. Drag a widget in, or use ◀ ▶ on one."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            color: page.bone
            opacity: 0.4
            font.family: "Noto Serif"
            font.pixelSize: 11
          }
        }
      }
    }


    // widgets that are in no column at all (removed from the layout): one click puts them on the right
    ColumnLayout {
      id: unplaced
      Layout.fillWidth: true
      spacing: 6
      readonly property var ids: {
        var out = []
        for (var i = 0; i < Widgets.widgets.length; i++)
          if (page.act.regionOf(Widgets.widgets[i].id) === "") out.push(Widgets.widgets[i].id)
        return out
      }
      visible: ids.length > 0

      CcSection {
        host: page.cc
        startOpen: true
        pal: page.pal
        label: "NOT ON THE BAR"
        note: "Click one to add it to the right side; move it from there."

          Flow {
          Layout.fillWidth: true
          spacing: 8
          Repeater {
            model: unplaced.ids
            CcCard {
              required property string modelData
              width: 150
              height: 34
              radius: 17
              host: page.cc
              pal: page.pal
              showCaption: false
              hint: "Add this widget to the right side of the bar."
              onActivated: page.act.addPlugin(modelData, "right")
              Text {
                anchors.centerIn: parent
                text: "+ " + (page.widgetInfo(modelData) ? page.widgetInfo(modelData).name : modelData)
                color: page.bone
                font.family: "Noto Serif"
                font.pixelSize: 12
              }
            }
          }
        }
      }
    }
  }


  // ---------------------------------------------------------------- the network drawing
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "NETWORK ICON"
    note: "What the bar draws for the connection. Auto shows what is real: the port on a cable, the signal arcs on Wi-Fi."


    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: [
          { "key": "auto",  "name": "Auto",        "note": "The port when you are on a cable, the signal arcs when you are on Wi-Fi." },
          { "key": "wifi",  "name": "Wi-Fi arcs",  "note": "Always the signal arcs, even on a cable (drawn at full strength)." },
          { "key": "cable", "name": "Cable port",  "note": "Always the port, even on Wi-Fi." }
        ]

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.preferredHeight: 84
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: String(page.pal.get("netIcon", "auto")) === modelData.key
          onActivated: page.act.set("netIcon", modelData.key)

          Ito.ItoImage {
            palette: page.pal
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            width: 40
            height: 40
            source: Qt.resolvedUrl("../ito-art/instruments/" + (modelData.key === "cable" ? "net-wired.png" : "net-3.png"))
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: parent.current ? 1 : 0.8
          }
        }
      }
    }
  }


  // ---------------------------------------------------------------- versions of the indicators
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "INDICATOR ICONS"
    note: "Each indicator comes in several versions, some of them from Silent Hill. Pick the one you like; it is shown lit."


    Repeater {
      model: Icons.indicators

      ColumnLayout {
        id: group
        required property var modelData
        Layout.fillWidth: true
        spacing: 6

        Text {
          text: group.modelData.name
          color: page.bone
          opacity: 0.8
          font.family: "Noto Serif"
          font.pixelSize: 12
          visible: page.cc.match(group.modelData.name + " indicator icon")
        }

        GridLayout {
          Layout.fillWidth: true
          columns: 5
          rowSpacing: 8
          columnSpacing: 8
          visible: page.cc.match(group.modelData.name + " indicator icon")

          Repeater {
            model: group.modelData.versions

            CcCard {
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              Layout.preferredHeight: 96
              host: page.cc
              pal: page.pal
              caption: modelData.name
              hint: modelData.note
              current: Icons.version(page.pal, group.modelData.id) === modelData.key
              onActivated: page.act.set("icon:" + group.modelData.id, modelData.key)

              Ito.ItoImage {
                palette: page.pal
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                width: 52
                height: 52
                source: Qt.resolvedUrl("../ito-art/indicators/" + group.modelData.id + "-" + modelData.key + "-on.png")
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
              }
            }
          }
        }
      }
    }
  }


  // ---------------------------------------------------------------- the AI usage drawing
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "AI USAGE ICON"
    note: "What the quota fills as it is spent. Shown here half full."


    GridLayout {
      Layout.fillWidth: true
      columns: 5
      rowSpacing: 8
      columnSpacing: 8

      Repeater {
        model: [
          { "key": "brain",       "name": "Brain",       "note": "The engraved brain seen from the side." },
          { "key": "hemispheres", "name": "Hemispheres", "note": "The brain from above, both halves with their folds." },
          { "key": "neurons",     "name": "Neurons",     "note": "A small net of cells joined by fibres." },
          { "key": "eye",         "name": "Eye",         "note": "Her eye; the white of it floods with blood." },
          { "key": "spiral",      "name": "Spiral",      "note": "The spiral, filling like a glass." }
        ]

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.preferredHeight: 108
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: String(page.pal.get("aiStyle", "brain")) === modelData.key
          visible: page.cc.match(modelData.name + " " + modelData.note + " ai usage icon")
          onActivated: page.act.set("aiStyle", modelData.key)

          Ito.ItoFillArt {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            size: 62
            value: 0.55
            palette: page.pal
            art: Qt.resolvedUrl("../ito-art/system/" + (modelData.key === "brain" ? "brain.png" : "ai-" + modelData.key + ".png"))
            inside: Qt.resolvedUrl("../ito-art/system/" + (modelData.key === "brain" ? "brain-fill.png" : "ai-" + modelData.key + "-fill.png"))
          }
        }
      }
    }
  }


  // ---------------------------------------------------------------- your bar
  function widgetInfo(id) {
    for (var i = 0; i < Widgets.widgets.length; i++) if (Widgets.widgets[i].id === id) return Widgets.widgets[i]
    return null
  }

  // A small square button: an arrow that moves a widget, or says why it cannot.
  component Nudge: Rectangle {
    id: nudge
    property string glyph: ""
    property string tip: ""
    property bool usable: true
    signal tapped()
    width: 22
    height: 24
    radius: 7
    color: nh.hovered && usable ? Qt.rgba(page.pal.blood.r, page.pal.blood.g, page.pal.blood.b, 0.3) : "transparent"
    opacity: usable ? 1 : 0.22
    Text { anchors.centerIn: parent; text: nudge.glyph; color: page.bone; font.pixelSize: 13 }
    HoverHandler {
      id: nh
      cursorShape: nudge.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
      onHoveredChanged: page.cc.hint = hovered ? nudge.tip : ""
    }
    TapHandler { enabled: nudge.usable; onTapped: nudge.tapped() }
  }

  // One widget on the bar: its switch, its name and what it shows, and the arrows that move it.
  component BarRow: Rectangle {
    id: row
    required property string wid
    required property string region
    required property int position
    required property int count
    readonly property var info: page.widgetInfo(wid)
    readonly property bool on: page.act.widgetOn(wid)
    readonly property string mode: page.act.contentOf(wid)
    readonly property bool canMode: info && info.reading === true
    readonly property bool locked: info && info.locked === true

    // being dragged: it follows the pointer (it keeps its place in the list until it is dropped)
    property real dragX: 0
    property real dragY: 0
    readonly property bool dragging: page.dragId === wid
    z: dragging ? 100 : 0
    transform: Translate { x: row.dragX; y: row.dragY }
    // where a drop would land: a line above this row, or below it if it is the last of the column
    readonly property bool guideAbove: page.dragId !== "" && !dragging && page.dropRegion === region && page.dropBeforeId === wid
    readonly property bool guideBelow: page.dragId !== "" && !dragging && page.dropRegion === region && page.dropBeforeId === ""
                                       && position === count - 1

    Layout.fillWidth: true
    Layout.preferredHeight: 66
    radius: 12
    visible: !!info && page.cc.match(info.name + " " + info.note + " widget")
    color: dragging ? Qt.rgba(page.pal.ink.r * 0.85 + page.bone.r * 0.15, page.pal.ink.g * 0.85 + page.bone.g * 0.15, page.pal.ink.b * 0.85 + page.bone.b * 0.15, 0.98)
         : (rowHover.hovered ? Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.07) : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.03))
    opacity: 1
    border.width: 1
    border.color: dragging ? page.pal.lit : on ? Qt.rgba(page.pal.blood.r, page.pal.blood.g, page.pal.blood.b, 0.4) : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.1)

    HoverHandler {
      id: rowHover
      onHoveredChanged: page.cc.hint = hovered && row.info ? row.info.note : ""
    }

    // the guide line for a drop
    Rectangle {
      visible: row.guideAbove || row.guideBelow
      x: 6; width: parent.width - 12; height: 3; radius: 1.5
      y: row.guideAbove ? -5 : parent.height + 2
      color: page.pal.blood
    }

    // the grip: hold it and drag the widget to any place in any column
    Item {
      id: grip
      x: 2; width: 18; height: parent.height
      visible: !row.locked
      Text {
        anchors.centerIn: parent
        text: "⋮⋮"
        rotation: 0
        color: page.bone
        opacity: gripHover.hovered || row.dragging ? 0.9 : 0.35
        font.pixelSize: 15
      }
      HoverHandler {
        id: gripHover
        cursorShape: row.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onHoveredChanged: page.cc.hint = hovered ? "Hold and drag to move this widget anywhere on the bar." : ""
      }
      // follow the pointer while the drag lasts: how far it is from where it was pressed, and where a drop would land
      // (read on a short timer: the handler's own change signals arrived too rarely to move the row smoothly)
      Timer {
        running: dragger.active
        interval: 16
        repeat: true
        onTriggered: {
          var c = dragger.centroid
          row.dragX = c.scenePosition.x - c.scenePressPosition.x
          row.dragY = c.scenePosition.y - c.scenePressPosition.y
          page.dragMoved(row.wid, c.scenePosition.x, c.scenePosition.y)
        }
      }
      DragHandler {
        id: dragger
        target: null
        cursorShape: Qt.ClosedHandCursor
        onActiveChanged: {
          if (active) { page.dragId = row.wid; page.dragRegion = row.region }
          else { row.dragX = 0; row.dragY = 0; page.dragDone(row.wid, centroid.scenePosition.x, centroid.scenePosition.y) }
        }
      }
    }

    // the switch: a track with a knob, blood when the widget is on
    Rectangle {
      id: track
      x: 24
      y: 11
      width: 34
      height: 18
      radius: 9
      visible: !row.locked
      color: row.on ? page.pal.blood : "transparent"
      border.width: 1
      border.color: row.on ? page.pal.blood : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.45)
      Behavior on color { ColorAnimation { duration: 120 } }
      Rectangle {
        y: 3
        x: row.on ? parent.width - width - 3 : 3
        width: 12
        height: 12
        radius: 6
        color: row.on ? page.bone : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.6)
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
      }
      HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: page.cc.hint = hovered ? (row.on ? "Switch this widget off. It keeps its place." : "Switch this widget on.") : ""
      }
      TapHandler { onTapped: page.act.setWidget(row.wid, !row.on) }
    }
    Text {
      x: 24
      y: 9
      width: 34
      visible: row.locked
      horizontalAlignment: Text.AlignHCenter
      text: "•"
      color: page.pal.blood
      font.pixelSize: 16
    }

    // line one: the whole name, with all the room there is
    Text {
      x: 68
      y: 9
      width: parent.width - 76
      elide: Text.ElideRight
      text: row.info ? row.info.name : row.wid
      color: page.bone
      opacity: row.on ? 1 : 0.55
      font.family: "Noto Serif"
      font.pixelSize: 13
      font.weight: Font.DemiBold
    }
    // line two, on the left: what it shows (a plain link-like chip for the widgets that have a reading)
    Text {
      x: 24
      y: 40
      width: parent.width - arrows.width - 34
      elide: Text.ElideRight
      text: row.locked ? "Always on" : (row.canMode && row.on ? page.modeNames[row.mode] + "  ↻" : (row.on ? "On" : "Off"))
      color: row.canMode && row.on && !row.locked ? page.pal.lit : page.bone
      opacity: row.canMode && row.on && !row.locked ? 0.95 : 0.45
      font.family: "Noto Serif"
      font.pixelSize: 10
      MouseArea {
        anchors.fill: parent
        enabled: row.canMode && row.on && !row.locked
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
        onEntered: page.cc.hint = "Click to change what it shows: icon and number, icon only, or number only."
        onExited: page.cc.hint = ""
        onClicked: page.act.cycleContent(row.wid)
      }
    }

    Row {
      id: arrows
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 6
      anchors.right: parent.right
      anchors.rightMargin: 6
      spacing: 0
      Nudge { glyph: "◀"; usable: row.region !== "left" && !row.locked
              tip: row.region === "right" ? "Move to the centre of the bar." : "Move to the left side of the bar."
              onTapped: page.act.sendWidget(row.wid, row.region === "right" ? "center" : "left") }
      Nudge { glyph: "▲"; usable: row.position > 0 && !row.locked; tip: "Move it one place earlier."
              onTapped: page.act.nudgeWidget(row.wid, -1) }
      Nudge { glyph: "▼"; usable: row.position < row.count - 1 && !row.locked; tip: "Move it one place later."
              onTapped: page.act.nudgeWidget(row.wid, 1) }
      Nudge { glyph: "▶"; usable: row.region !== "right" && !row.locked
              tip: row.region === "left" ? "Move to the centre of the bar." : "Move to the right side of the bar."
              onTapped: page.act.sendWidget(row.wid, row.region === "left" ? "center" : "right") }
    }
  }
}
