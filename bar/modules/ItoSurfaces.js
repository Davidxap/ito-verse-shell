.pragma library

// What the bar's plate is made of.
//
// There is no "pick a style" here, on purpose. The plate is black, and every layer that makes it
// Ito is independent: smoked glass and manga paper can sit together, blood can run through either,
// the wood grain can be laid over all of it. A layer is one sidecar flag (`fx*`) and, where it has a
// strength, one tuning key (`surface*`). PRESETS are only shortcuts that set several flags at once.

var layers = [
  { flag: "fxPlate",  name: "Plate",         note: "The black plate itself. Off leaves only the icons floating on the desktop." },
  { flag: "fxGlass",  name: "Smoked glass",  note: "Makes the plate translucent, so the wallpaper shows through it darkened." },
  { flag: "fxPaper",  name: "Manga paper",   note: "A hair off pure black, with press dirt on it, like a printed page." },
  { flag: "fxBlood",  name: "Blood",         note: "Blood veins spreading through the plate, from the design sheet." },
  { flag: "fxWood",   name: "Uzumaki grain", note: "Wood grain winding into spiral knots, kept to the ends of the bar." },
  { flag: "fxTone",   name: "Screentone",    note: "The manga halftone screen laid over everything." },
  { flag: "fxGrain",  name: "Grain",         note: "Fine dirt over the whole plate." },
  { flag: "fxCalm",   name: "Calm centre",   note: "Darkens the middle so readings stay legible over blood and grain." },
  { flag: "fxPills",  name: "Widget pills",  note: "Every widget sits in its own dark pill, like Shibumi. Makes the Floating look readable." },
  { flag: "fxBorder", name: "Border",        note: "A pale line drawn around the plate." },
  { flag: "fxTorn",   name: "Torn edge",     note: "The border reads as hand-torn paper instead of a ruled line. Needs Border on." },
  { flag: "fxFog",    name: "Fog",           note: "Silent Hill's fog, two wisps drifting across the plate all the time, faint enough to read as atmosphere." }
]

// What is on when the user has never said otherwise: a clean black plate with a little dirt.
var defaults = {
  fxPlate: true, fxGlass: false, fxPaper: false, fxBlood: false, fxWood: false,
  fxTone: false, fxGrain: true, fxCalm: true, fxBorder: true, fxPills: false, fxTorn: false, fxFog: false
}

var presets = [
  { key: "clean", name: "Clean ink", note: "Plain black plate, a little dirt, the pale border.",
    set: { fxPlate: true, fxGlass: false, fxPaper: false, fxBlood: false, fxWood: false,
           fxTone: false, fxGrain: true, fxCalm: true, fxBorder: true, fxPills: false } },
  { key: "bloodline", name: "Bloodline", note: "The design mock-up: black with blood veins running through it.",
    set: { fxPlate: true, fxGlass: false, fxPaper: false, fxBlood: true, fxWood: false,
           fxTone: false, fxGrain: true, fxCalm: true, fxBorder: true, fxPills: false } },
  { key: "glass", name: "Smoked glass", note: "Translucent black over the wallpaper, nothing else.",
    set: { fxPlate: true, fxGlass: true, fxPaper: false, fxBlood: false, fxWood: false,
           fxTone: false, fxGrain: false, fxCalm: false, fxBorder: true, fxPills: false } },
  { key: "page", name: "Manga page", note: "Printed black paper with the halftone screen.",
    set: { fxPlate: true, fxGlass: false, fxPaper: true, fxBlood: false, fxWood: false,
           fxTone: true, fxGrain: true, fxCalm: true, fxBorder: true, fxPills: false } },
  { key: "uzumaki", name: "Uzumaki", note: "Paper with spiral wood grain at both ends.",
    set: { fxPlate: true, fxGlass: false, fxPaper: true, fxBlood: false, fxWood: true,
           fxTone: false, fxGrain: true, fxCalm: true, fxBorder: true, fxPills: false } },
  { key: "floating", name: "Floating", note: "No plate: each widget floats in its own dark pill over the desktop.",
    set: { fxPlate: false, fxGlass: false, fxPaper: false, fxBlood: false, fxWood: false,
           fxTone: false, fxGrain: false, fxCalm: false, fxBorder: false, fxPills: true } }
]

// The bar's shapes. The fork owns the geometry (it is Shibumi's shell-form work). Each one is drawn with a
// diagram: `w` is how much of the screen's width it takes, `gap` how far it floats off the top edge, `r` its
// corner shape (0 square, 1 fully round), `flat` whether its top edge is flush.
var forms = [
  { key: "shibumi", name: "Islands", w: 0.94, gap: 3, r: 1, flat: false,
    note: "A floating pill across the screen, inset from its edges. The only form that can be cut into islands." },
  { key: "full", name: "Full", w: 1, gap: 0, r: 0, flat: true,
    note: "Edge to edge and square: the bar is the top of the screen." },
  { key: "fit", name: "Fit", w: 0.66, gap: 0, r: 0.4, flat: true,
    note: "As wide as what is in it, hanging from the top edge with its bottom corners rounded." },
  { key: "dock", name: "Dock", w: 0.66, gap: 3, r: 1, flat: false,
    note: "As wide as what is in it, floating clear of the edge like a pill." },
  { key: "notch", name: "Notch", w: 0.66, gap: 0, r: 0.4, flat: true, notch: true,
    note: "Hangs from the edge with flowing shoulders that melt into the screen." }
]

// Where the bar sits on the screen. `x`,`y`,`w`,`h` draw it on the little screen of the card.
var positions = [
  { key: "top",    name: "Top",    x: 0.0,  y: 0.0,  w: 1.0,  h: 0.28, note: "Along the top edge." },
  { key: "bottom", name: "Bottom", x: 0.0,  y: 0.72, w: 1.0,  h: 0.28, note: "Along the bottom edge." },
  { key: "left",   name: "Left",   x: 0.0,  y: 0.0,  w: 0.16, h: 1.0,  note: "Down the left edge, widgets stacked." },
  { key: "right",  name: "Right",  x: 0.84, y: 0.0,  w: 0.16, h: 1.0,  note: "Down the right edge, widgets stacked." }
]

function on(cfg, flag) {
  var value = cfg.get(flag, defaults[flag])
  return value === true || value === "true" || value === 1
}

// Every layer folded into the values ItoPlate paints with. The bar and the panel's preview both
// call this, so what the panel shows is exactly what the bar draws.
function resolve(cfg) {
  var glass = on(cfg, "fxGlass"), paper = on(cfg, "fxPaper")
  var dirt = Math.max(on(cfg, "fxGrain") ? cfg.get("surfaceGrain", 0.14) : 0, paper ? 0.3 : 0)
  return {
    // The user's opacity always applies; smoked glass takes a further slice off it.
    plate: on(cfg, "fxPlate") ? cfg.get("surfaceOpacity", 1) * (glass ? 0.74 : 1) : 0,
    veins: on(cfg, "fxBlood") ? cfg.get("surfaceVeins", 0.6) : 0,
    wood: on(cfg, "fxWood") ? cfg.get("surfaceWood", 0.26) : 0,
    calm: on(cfg, "fxCalm") ? cfg.get("surfaceCalm", 0.4) : 0,
    grain: dirt,
    tone: on(cfg, "fxTone") ? cfg.get("surfaceTone", 0.15) : 0,
    lift: paper ? 0.045 : 0,
    border: on(cfg, "fxBorder"),
    torn: on(cfg, "fxTorn"),
    fog: on(cfg, "fxFog") ? cfg.get("surfaceFog", 0.05) : 0
  }
}
