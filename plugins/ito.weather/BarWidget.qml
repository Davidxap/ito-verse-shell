import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui
import "../../bar/modules" as Ito
import "Sky.js" as Sky

// Ito weather — the sky in the same ink as the rest of the bar.
//
// wttr.in is asked once every refresh (curl, not a QML network stack, so a dead link can never wedge
// the shell) and the answer drives a drawn glyph: sun, moon, cloud, rain, storm, snow, fog. No icon
// font, no third-party art. Clicking opens the forecast: the rest of today by the hour, then the
// days ahead.
Ui.BarWidget {
  id: root
  moduleName: "ito.weather"

  Ito.ItoConfig {
    id: cfg
    path: Qt.resolvedUrl("../../bar/modules/ito-style.json").toString().replace("file://", "")
  }

  readonly property color blood: cfg.blood
  readonly property color bone: cfg.bone
  readonly property int glyph: Math.round(root.barSize * cfg.get("iconScale", 0.62))
  readonly property bool showValues: cfg.get("showValues", true)
    && cfg.get("valueStyle", "percent") !== "off"
    && cfg.get("content:ito.weather", "both") !== "icon"
  // "text" mode drops the icon and leaves the reading
  readonly property bool showIcon: cfg.get("content:ito.weather", "both") !== "text"
  readonly property int refreshMinutes: Math.max(5, cfg.get("weatherMinutes", 20))

  property bool popupOpen: false

  // ---------------------------------------------------------------- the report
  property var report: null                 // the whole wttr j1 answer, kept across failures
  property var place: ({ "name": "", "latitude": null, "longitude": null })

  readonly property var current: report && report.current_condition
    ? report.current_condition[0] : null
  readonly property var days: report && report.weather ? report.weather : []
  readonly property string area: {
    if (place.name !== "") return place.name
    var near = report && report.nearest_area ? report.nearest_area[0] : null
    return near && near.areaName && near.areaName[0] ? near.areaName[0].value : ""
  }
  readonly property int temp: current ? Math.round(Number(current.temp_C)) : 0
  readonly property string describe: current && current.weatherDesc && current.weatherDesc[0]
    ? String(current.weatherDesc[0].value).trim() : ""
  readonly property int hourNow: new Date().getHours()
  readonly property string kind: current
    ? Sky.kind(current.weatherCode, Sky.isNight(root.hourNow)) : "cloud"

  // The engraved sky, one drawing per kind (see scripts/gen-premium.py).
  readonly property url instruments: Qt.resolvedUrl("../../bar/modules/ito-art/instruments/")
  function skyArt(k) { return instruments + "sky-" + k + ".png" }

  // The rest of today and tomorrow morning, three hours at a time.
  readonly property var slots: {
    var out = []
    for (var d = 0; d < Math.min(2, days.length); d++) {
      var hours = days[d].hourly || []
      for (var i = 0; i < hours.length; i++) {
        var h = Sky.hourOf(hours[i].time)
        if (d === 0 && h <= root.hourNow) continue
        out.push({ "hour": h, "temp": Math.round(Number(hours[i].tempC)),
                   "kind": Sky.kind(hours[i].weatherCode, Sky.isNight(h)) })
        if (out.length >= 6) return out
      }
    }
    return out
  }

  // The location the user set in Omarchy's own settings, so both widgets agree on where you are.
  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var parsed = JSON.parse(text()) || ({})
        root.place = { "name": String(parsed.name || ""),
                       "latitude": parsed.latitude, "longitude": parsed.longitude }
      } catch (e) {
        root.place = { "name": "", "latitude": null, "longitude": null }
      }
      root.refresh()
    }
    onLoadFailed: root.refresh()
  }

  function query() {
    var lat = Number(root.place.latitude), lon = Number(root.place.longitude)
    if (isFinite(lat) && isFinite(lon) && (lat !== 0 || lon !== 0))
      return lat + "," + lon
    return root.place.name !== "" ? encodeURIComponent(root.place.name) : ""
  }

  function refresh() {
    if (fetch.running) return
    fetch.command = ["sh", "-c",
      "curl -fsS --max-time 20 'https://wttr.in/" + root.query() + "?format=j1'"]
    fetch.running = true
  }

  Process {
    id: fetch
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(this.text)
          if (parsed && parsed.current_condition) root.report = parsed
        } catch (e) {
          // keep whatever we had: a stale sky beats an empty one
        }
      }
    }
  }

  Timer {
    interval: root.refreshMinutes * 60000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: root.current
      ? (root.describe + " · " + root.temp + "°"
         + (root.area !== "" ? " · " + root.area : ""))
      : "Weather — reading the sky"
    horizontalMargin: 4
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? barSize : content.width + scaledHorizontalMargin * 2
    fixedHeight: vertical ? content.height + scaledVerticalPadding * 2 : barSize
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) {
        root.popupOpen = !root.popupOpen
        if (root.popupOpen) root.refresh()
      }
    }

    // Side by side on a horizontal bar, stacked (icon over reading) on a vertical one.
    Grid {
      id: content
      anchors.centerIn: parent
      columns: root.vertical ? 1 : 9
      spacing: 3
      horizontalItemAlignment: Grid.AlignHCenter
      verticalItemAlignment: Grid.AlignVCenter

      Ito.ItoHover { parent: button; target: skyGlyph; hovered: button.tooltipHovered; kind: root.kind === "moon" || root.kind === "fog" ? "breathe" : "lift"; amp: cfg.motionAmp; glow: cfg.blood; light: cfg.light }
      Ito.ItoSkyFx { parent: skyGlyph.parent; x: skyGlyph.x; y: skyGlyph.y; width: skyGlyph.width; height: skyGlyph.height; z: 2; kind: root.kind; live: button.tooltipHovered; amp: cfg.motionAmp; bone: cfg.bone; blood: cfg.blood }
      Ito.ItoImage {
        id: skyGlyph
        visible: root.showIcon
        source: root.skyArt(root.kind)
        width: root.glyph
        height: root.glyph
        palette: cfg
        opacity: root.current ? 1 : 0.45
        Behavior on opacity { NumberAnimation { duration: 200 } }
      }

      Ito.ItoValue {
        visible: root.showValues && root.current !== null
        barSize: root.barSize
        percent: false
        value: root.temp + "°"
      }
    }
  }

  // `omarchy-shell ito.weather toggle` (also open, close) for a keybinding.
  IpcHandler {
    target: "ito.weather"
    function open(): void { root.popupOpen = true }
    function close(): void { root.popupOpen = false }
    function toggle(): void { root.popupOpen = !root.popupOpen }
  }

  // ------------------------------------------------------------------ forecast
  // The forecast sits at the corner of the screen that is nearest the bar, whichever edge the bar is on.
  PanelWindow {
    id: panel

    readonly property string pos: root.bar && root.bar.position ? String(root.bar.position) : "top"
    readonly property int edge: (root.bar ? root.bar.barSize : 46) + 8

    visible: root.popupOpen
    anchors.top: pos !== "bottom"
    anchors.bottom: pos === "bottom"
    anchors.right: pos !== "left"
    anchors.left: pos === "left"
    margins.top: pos === "top" ? edge : 12
    margins.bottom: pos === "bottom" ? edge : 0
    margins.right: pos === "right" ? edge : 12
    margins.left: pos === "left" ? edge : 0
    exclusiveZone: 0
    implicitWidth: card.width + 24
    implicitHeight: card.height + 24
    color: "transparent"

    HoverHandler { id: panelHover }
    Ito.ItoAutoClose {
      opened: root.popupOpen
      hovered: panelHover.hovered
      seconds: Number(cfg.get("popupSeconds", 3))
      onExpired: root.popupOpen = false
    }

    // the range the days share, so their bars can be compared with each other
    readonly property real lo: {
      var m = 99
      for (var i = 0; i < root.days.length; i++) m = Math.min(m, Number(root.days[i].mintempC))
      return m
    }
    readonly property real hi: {
      var m = -99
      for (var i = 0; i < root.days.length; i++) m = Math.max(m, Number(root.days[i].maxtempC))
      return m
    }
    readonly property real span: Math.max(1, hi - lo)

    // a few lines for the foot, in the voice of the sky they describe; one is drawn each time it opens
    readonly property var notes: ({
      "fog": ["The fog does not lift.", "You have walked this street before.", "Something stands in the white, waiting."],
      "rain": ["It has rained here for days.", "The rain draws circles. Then more circles.", "Every drop lands where the last one did."],
      "storm": ["Something is walking in the storm.", "The thunder comes from below.", "The sky splits and shows the same sky."],
      "snow": ["The snow keeps what it covers.", "Nothing has walked here. Then footprints."],
      "sun": ["Even the sun looks wrong.", "The light is the wrong colour today."],
      "suncloud": ["The light comes and goes.", "A cloud turns slowly over the town."],
      "moon": ["The moon is watching.", "The same night, once more."],
      "cloud": ["The sky is closed.", "The clouds curl in on themselves."]
    })
    readonly property var memos: notes[root.kind] || notes["cloud"]

    Item {
      id: card
      x: 12
      y: 12
      width: 396
      height: body.implicitHeight + cfg.panelHeadroom + 84

      Ito.ItoPanelFrame { cfg: cfg; target: card; emblem: root.kind; opened: root.popupOpen; memos: panel.memos }
      Ito.ItoEnter {
        opened: root.popupOpen
        amp: cfg.motionAmp
        origin: panel.pos === "bottom" ? Item.Bottom : Item.Top
      }

      ColumnLayout {
        id: body
        x: 24
        y: 22 + cfg.panelHeadroom
        width: card.width - 48
        spacing: 14

        // now: the sky, the temperature, where
        RowLayout {
          Layout.fillWidth: true
          spacing: 16

          Ito.ItoImage {
            Layout.preferredWidth: 74
            Layout.preferredHeight: 74
            Layout.alignment: Qt.AlignVCenter
            source: root.skyArt(root.kind)
            fillMode: Image.PreserveAspectFit
            palette: cfg
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
              text: root.current ? root.temp + "°" : "—"
              color: root.bone
              font.family: "Noto Serif"
              font.pixelSize: 50
              font.weight: Font.Light
            }
            Text {
              Layout.fillWidth: true
              text: root.describe
              color: root.bone
              opacity: 0.85
              font.family: "Noto Serif"
              font.pixelSize: 14
              elide: Text.ElideRight
            }
            Text {
              Layout.fillWidth: true
              text: root.area.toUpperCase()
              color: root.blood
              font.family: "Noto Serif"
              font.pixelSize: 10
              font.letterSpacing: 1.6
              elide: Text.ElideRight
            }
          }
        }

        // three small readings, each a third of the width
        Row {
          Layout.fillWidth: true
          visible: !!root.current

          Repeater {
            model: root.current ? [
              { "k": "FEELS", "v": Math.round(Number(root.current.FeelsLikeC)) + "°" },
              { "k": "HUMIDITY", "v": root.current.humidity + "%" },
              { "k": "WIND", "v": root.current.windspeedKmph + " km/h" }
            ] : []

            Column {
              required property var modelData
              width: body.width / 3
              spacing: 2
              Text {
                text: modelData.k
                color: root.bone
                opacity: 0.5
                font.family: "Noto Serif"
                font.pixelSize: 9
                font.letterSpacing: 1.6
              }
              Text {
                text: modelData.v
                color: root.bone
                font.family: "Noto Serif"
                font.pixelSize: 14
              }
            }
          }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.bone; opacity: 0.16 }

        // the hours ahead, in equal cells so none can spill past the edge
        Row {
          Layout.fillWidth: true

          Repeater {
            model: root.slots

            Column {
              required property var modelData
              width: body.width / Math.max(1, root.slots.length)
              spacing: 5

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Sky.pad(modelData.hour) + ":00"
                color: root.bone
                opacity: 0.55
                font.family: "Noto Serif"
                font.pixelSize: 10
              }
              Ito.ItoImage {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 32
                height: 32
                source: root.skyArt(modelData.kind)
                fillMode: Image.PreserveAspectFit
                palette: cfg
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.temp + "°"
                color: root.bone
                font.family: "Noto Serif"
                font.pixelSize: 13
              }
            }
          }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.bone; opacity: 0.16 }

        // the days ahead, each with the range it covers on one shared scale
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 9

          Repeater {
            model: root.days

            RowLayout {
              required property var modelData
              required property int index
              Layout.fillWidth: true
              spacing: 10

              Text {
                Layout.preferredWidth: 84
                text: index === 0 ? "Today"
                  : Qt.formatDate(Date.fromLocaleDateString(Qt.locale(), modelData.date, "yyyy-MM-dd"), "dddd")
                color: root.bone
                opacity: index === 0 ? 0.95 : 0.75
                font.family: "Noto Serif"
                font.pixelSize: 13
                elide: Text.ElideRight
              }
              Ito.ItoImage {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                source: root.skyArt(modelData.hourly && modelData.hourly.length > 4
                  ? Sky.kind(modelData.hourly[4].weatherCode, false) : "cloud")
                fillMode: Image.PreserveAspectFit
                palette: cfg
              }
              Item { Layout.fillWidth: true }
              Text {
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignRight
                text: Math.round(Number(modelData.mintempC)) + "°"
                color: root.bone
                opacity: 0.55
                font.family: "Noto Serif"
                font.pixelSize: 13
              }
              Item {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 4
                Rectangle {
                  anchors.fill: parent
                  radius: 2
                  color: Qt.rgba(root.bone.r, root.bone.g, root.bone.b, 0.16)
                }
                Rectangle {
                  height: parent.height
                  radius: 2
                  x: parent.width * (Number(modelData.mintempC) - panel.lo) / panel.span
                  width: Math.max(6, parent.width * (Number(modelData.maxtempC) - Number(modelData.mintempC)) / panel.span)
                  color: root.blood
                  opacity: 0.85
                }
              }
              Text {
                Layout.preferredWidth: 28
                text: Math.round(Number(modelData.maxtempC)) + "°"
                color: root.bone
                font.family: "Noto Serif"
                font.pixelSize: 13
              }
            }
          }
        }
      }
    }
  }
}
