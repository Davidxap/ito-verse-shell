import QtQuick
import QtQuick.Layouts
import ".." as Ito
import "../ItoSurfaces.js" as Surfaces
import "../ItoLayouts.js" as Layouts

// Bars: the shape of the bar, which design it wears, and what its plate is made of.
ColumnLayout {
  id: page

  property var cc: null
  readonly property var pal: cc.pal
  readonly property var act: cc.actions
  readonly property color bone: pal.bone

  spacing: 10

  // ---------------------------------------------------------------- position
  CcSection {
    host: page.cc
    startOpen: true
    pal: page.pal
    label: "POSITION"
    note: "Which edge of the screen the bar takes. On the sides the widgets stack and show icons."


    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: Surfaces.positions

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.preferredHeight: 84
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: page.act.position === modelData.key
          visible: page.cc.match(modelData.name + " " + modelData.note + " position edge side")
          onActivated: page.act.setPosition(modelData.key)

          // the screen, and the bar along one of its edges
          Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            width: 60
            height: 38

            Rectangle {
              anchors.fill: parent
              radius: 3
              color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.06)
            }

            Rectangle {
              x: parent.width * modelData.x
              y: parent.height * modelData.y
              width: Math.max(6, parent.width * modelData.w)
              height: Math.max(6, parent.height * modelData.h)
              radius: 2
              color: parent.parent.current ? page.pal.blood : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.5)
              Behavior on color { ColorAnimation { duration: 140 } }
            }
          }
        }
      }
    }


    CcToggle {
      Layout.fillWidth: true
      host: page.cc
      pal: page.pal
      label: "Float off the edge"
      hint: "Off (default): the bar touches the screen edge it is on, with no gap. On: it floats clear of the edge as a pill."
      on: page.pal.get("barFloat", false) === true
      onActivated: page.act.set("barFloat", on ? "false" : "true")
    }
  }


  // ---------------------------------------------------------------- shape
  CcSection {
    startOpen: true
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "SHAPE"
    note: {
      var forms = Surfaces.forms
      for (var i = 0; i < forms.length; i++)
        if (forms[i].key === page.act.currentForm) return forms[i].note
      return ""
    }


    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: Surfaces.forms

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 88
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          current: page.act.currentForm === modelData.key
          visible: page.cc.match(modelData.name + " " + modelData.note + " shape")
          onActivated: page.act.applyForm(modelData.key)

          // a diagram of the form: the top of a screen, and the bar in it
          Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 12
            width: 104
            height: 34

            Rectangle {
              anchors.fill: parent
              radius: 3
              color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.06)
            }

            Rectangle {
              x: (parent.width - width) / 2
              y: modelData.gap
              width: parent.width * modelData.w
              height: 12
              radius: modelData.r * 6
              // a flush bar keeps its top square
              Rectangle {
                visible: modelData.flat && modelData.r > 0
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
              }
              color: parent.parent.current ? page.pal.blood : Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.5)
              Behavior on color { ColorAnimation { duration: 140 } }

              // the notch's shoulders: a lighter flare on each side, melting into the edge
              Repeater {
                model: modelData.notch ? [0, 1] : []

                Rectangle {
                  required property int modelData
                  x: modelData === 0 ? -6 : parent.width
                  y: 0
                  width: 6
                  height: 5
                  radius: 0
                  color: Qt.rgba(parent.color.r, parent.color.g, parent.color.b, 0.55)
                }
              }
            }
          }
        }
      }
    }


    RowLayout {
      Layout.fillWidth: true
      spacing: 8
      opacity: page.act.currentForm === "shibumi" ? 1 : 0.35
      visible: page.cc.match("cut islands split")

      Repeater {
        model: [
          { "index": 0, "label": "Cut  left | centre" },
          { "index": 1, "label": "Cut  centre | right" }
        ]

        CcToggle {
          required property var modelData
          Layout.fillWidth: true
          host: page.cc
          pal: page.pal
          label: modelData.label
          hint: "Split the bar into separate islands at this point. Only the Islands shape can be cut."
          on: page.act.cutOn(modelData.index)
          enabled: page.act.currentForm === "shibumi"
          onActivated: page.act.toggleCut(modelData.index)
        }
      }
    }
  }


  // ---------------------------------------------------------------- details of the shape
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "DETAILS"
    note: "How the bar is built: its corners, how tall it is, how far apart its widgets stand, and whether it casts a shadow."


    Repeater {
      model: [
        { "label": "Corners", "key": "barRadius", "fallback": "round", "tip": "How round the plate's corners are. Full runs edge to edge, so it has none.",
          "opts": [ { "v": "square", "n": "Square" }, { "v": "soft", "n": "Soft" }, { "v": "round", "n": "Round" } ] },
        { "label": "Height", "key": "barSize", "fallback": "46", "tip": "How tall the bar is. Icons and numbers grow with it.",
          "opts": [ { "v": "40", "n": "Slim" }, { "v": "46", "n": "Regular" }, { "v": "52", "n": "Tall" } ] },
        { "label": "Spacing", "key": "barGap", "fallback": "normal", "tip": "How far apart the groups of widgets stand.",
          "opts": [ { "v": "tight", "n": "Tight" }, { "v": "normal", "n": "Normal" }, { "v": "airy", "n": "Airy" } ] }
      ]

      RowLayout {
        id: detail
        required property var modelData
        Layout.fillWidth: true
        spacing: 8
        visible: page.cc.match(modelData.label + " " + modelData.tip + " corners height spacing details")
        // Full runs edge to edge, so it has no corners to round: say so instead of leaving the choice doing nothing.
        opacity: (modelData.key === "barRadius" && page.act.currentForm === "full") ? 0.4 : 1

        Text {
          Layout.preferredWidth: 80
          text: detail.modelData.label
          color: page.bone
          opacity: 0.75
          font.family: "Noto Serif"
          font.pixelSize: 12
        }

        Repeater {
          model: detail.modelData.opts

          CcCard {
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: 34
            radius: 17
            host: page.cc
            pal: page.pal
            showCaption: false
            hint: detail.modelData.tip
            current: String(page.pal.get(detail.modelData.key, detail.modelData.fallback)) === modelData.v
            onActivated: page.act.set(detail.modelData.key, modelData.v)

            Text {
              anchors.centerIn: parent
              text: modelData.n
              color: parent.current ? page.pal.lit : page.bone
              font.family: "Noto Serif"
              font.pixelSize: 12
            }
          }
        }
      }
    }


    CcToggle {
      Layout.fillWidth: true
      host: page.cc
      pal: page.pal
      label: "Shadow under the bar"
      hint: "A soft shadow that lifts the bar off what is behind it."
      on: page.pal.get("barShadow", false) === true
      onActivated: page.act.set("barShadow", on ? "false" : "true")
    }


    CcCard {
      Layout.preferredWidth: 170
      Layout.preferredHeight: 30
      radius: 15
      host: page.cc
      pal: page.pal
      showCaption: false
      hint: "Put corners, height, spacing, shadow and floating back to how they shipped."
      onActivated: page.act.unset(["barRadius", "barSize", "barGap", "barShadow", "barFloat"])

      Text {
        anchors.centerIn: parent
        text: "Reset the details"
        color: page.bone
        font.family: "Noto Serif"
        font.pixelSize: 11
      }
    }
  }


  // ---------------------------------------------------------------- designs
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "DESIGNS"
    note: "Where every widget sits. Any design goes on any shape, so mix them freely. The bar restarts for a moment; your look stays as it is."


    CcToggle {
      Layout.fillWidth: true
      host: page.cc
      pal: page.pal
      label: "A design also sets its own shape"
      hint: "Off: a design keeps the shape you chose above. On: it switches the bar to the shape it was made for (shown on its card)."
      on: String(page.pal.get("designShape", "keep")) === "design"
      onActivated: page.act.set("designShape", on ? "keep" : "design")
    }


    GridLayout {
      Layout.fillWidth: true
      columns: 3
      rowSpacing: 8
      columnSpacing: 8

      Repeater {
        model: Layouts.designs

        CcCard {
          id: design
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 84
          host: page.cc
          pal: page.pal
          caption: modelData.name
          hint: modelData.note
          visible: page.cc.match(modelData.name + " " + modelData.note + " design layout")
          onActivated: page.act.applyDesign(modelData)

          // the shape it was made for
          Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            text: page.act.formName(design.modelData.form)
            color: page.bone
            opacity: 0.4
            font.family: "Noto Serif"
            font.pixelSize: 9
            font.letterSpacing: 1
          }

          // where the widgets go: left, centre and right as three little runs of beads
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            spacing: 10

            Repeater {
              model: ["left", "center", "right"]

              Row {
                required property string modelData
                readonly property int n: design.modelData[modelData].length
                spacing: 2
                visible: n > 0

                Repeater {
                  model: parent.n
                  Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Qt.rgba(page.bone.r, page.bone.g, page.bone.b, 0.6)
                  }
                }
              }
            }
          }
        }
      }
    }
  }


  // ---------------------------------------------------------------- look
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "LOOK"
    note: "The plate is black. Every layer is its own switch, and they all combine."


    // the plate as it really is, with every layer applied, over a stand-in wallpaper
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 44
      radius: 22
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: "#3a2a57" }
        GradientStop { position: 1; color: "#1d5a6b" }
      }

      Ito.ItoPlate {
        readonly property var look: Surfaces.resolve(page.pal)
        palette: page.pal
        anchors.fill: parent
        radius: 22
        artBase: Qt.resolvedUrl("../ito-art/")
        plate: look.plate
        veins: look.veins
        wood: look.wood
        calm: look.calm
        grain: look.grain
        tone: look.tone
        lift: look.lift
        border: look.border
      }
    }


    RowLayout {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        model: Surfaces.presets

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 34
          radius: 17
          host: page.cc
          pal: page.pal
          showCaption: false
          hint: modelData.note
          visible: page.cc.match(modelData.name + " " + modelData.note + " look preset")
          onActivated: {
            var d = {}
            for (var f in modelData.set) d[f] = modelData.set[f]
            page.act.setMany(d)
          }

          Text {
            anchors.centerIn: parent
            text: modelData.name
            color: page.bone
            opacity: 0.85
            font.family: "Noto Serif"
            font.pixelSize: 11
          }
        }
      }
    }


    GridLayout {
      Layout.fillWidth: true
      columns: 3
      rowSpacing: 4
      columnSpacing: 6

      Repeater {
        model: Surfaces.layers

        CcToggle {
          required property var modelData
          Layout.fillWidth: true
          host: page.cc
          pal: page.pal
          label: modelData.name
          hint: modelData.note
          on: page.act.layerOn(modelData.flag)
          visible: page.cc.match(modelData.name + " " + modelData.note + " layer look")
          onActivated: page.act.toggle(modelData.flag)
        }
      }
    }


    CcMeter { Layout.topMargin: 4; host: page.cc; pal: page.pal; actions: page.act
      label: "Opacity"; key: "surfaceOpacity"; fallback: 1; lo: 0.1; hi: 1
      hint: "How solid the plate is. Lower it to let the wallpaper through." }

    CcMeter { host: page.cc; pal: page.pal; actions: page.act
      label: "Blood strength"; key: "surfaceVeins"; fallback: 0.6; lo: 0; hi: 1
      hint: "How strongly the veins show, when the Blood layer is on." }

    CcMeter { host: page.cc; pal: page.pal; actions: page.act
      label: "Grain strength"; key: "surfaceGrain"; fallback: 0.14; lo: 0; hi: 0.4
      hint: "How much press dirt is on the plate." }

    CcMeter { host: page.cc; pal: page.pal; actions: page.act
      label: "Pill opacity"; key: "surfacePill"; fallback: 0.78; lo: 0.2; hi: 1
      hint: "How dark the pill behind each widget is, when Widget pills is on." }
  }


  // ---------------------------------------------------------------- actions
  CcSection {
    host: page.cc
    Layout.topMargin: 8
    pal: page.pal
    label: "LAYOUT"
    note: "Drag any widget onto another to trade places. Reset puts things back the way they shipped."


    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: [
          { "label": "Move widgets", "tip": "Enter edit mode: drag the widgets wherever you want them.", "act": "edit" },
          { "label": "Reset look",   "tip": "Put the plate, effects, seal, workspaces and readings back to the defaults.", "act": "look" },
          { "label": "Reset layout", "tip": "Put every widget back where it started.", "act": "layout" }
        ]

        CcCard {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 38
          radius: 19
          host: page.cc
          pal: page.pal
          showCaption: false
          hint: modelData.tip
          current: modelData.act === "edit"
          onActivated: {
            if (modelData.act === "edit") { page.cc.close(); page.act.editLayout() }
            else if (modelData.act === "look") page.act.resetLook()
            else page.act.resetLayout()
          }

          Text {
            anchors.centerIn: parent
            text: modelData.label
            color: modelData.act === "edit" ? page.pal.lit : page.bone
            font.family: "Noto Serif"
            font.pixelSize: 12
          }
        }
      }
    }
  }

}
