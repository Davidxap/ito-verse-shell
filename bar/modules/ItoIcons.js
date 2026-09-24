.pragma library

// The indicator icons and the versions each one comes in (see scripts/gen-indicator-icons.py). The user picks
// a version per indicator on the Icons page; the widget and the page read the same table.
//
// Pictures are ito-art/indicators/<id>-<version>-<off|on>.png. The first version of each is the default.

var indicators = [
  { id: "awake", name: "Stay awake", note: "Keeps the screen from locking or sleeping.",
    versions: [
      { key: "coffee",     name: "Coffee",     note: "A cup that fills with blood while you stay up." },
      { key: "radio",      name: "Radio",      note: "Silent Hill's pocket radio: it hisses when something is near." },
      { key: "flashlight", name: "Flashlight", note: "Silent Hill's flashlight: its beam held on." }
    ] },
  { id: "night", name: "Night light", note: "Warms the screen's colours.",
    versions: [
      { key: "moon", name: "Moon", note: "A moon, full of blood when it is on." },
      { key: "fog",  name: "Fog",  note: "Silent Hill's fog, with the red sun behind it." }
    ] },
  { id: "record", name: "Recording", note: "Whether the screen is being recorded.",
    versions: [
      { key: "eye",  name: "Eye",  note: "Closed until it is recording; then it opens, ringed." },
      { key: "tape", name: "Tape", note: "Silent Hill 2's videotape, the red light on." }
    ] }
]

function find(id) {
  for (var i = 0; i < indicators.length; i++)
    if (indicators[i].id === id) return indicators[i]
  return indicators[0]
}

// The version chosen for one indicator (or its default).
function version(cfg, id) {
  var wanted = String(cfg.get("icon:" + id, ""))
  var list = find(id).versions
  for (var i = 0; i < list.length; i++)
    if (list[i].key === wanted) return wanted
  return list[0].key
}

function art(artBase, cfg, id, on) {
  return artBase + "indicators/" + id + "-" + version(cfg, id) + "-" + (on ? "on" : "off") + ".png"
}
