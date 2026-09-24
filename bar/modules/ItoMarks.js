.pragma library

// The marks that stand for the shell: the seal in the middle of the bar, and the mark on the menu button.
// Each says what it is, in English, so a kanji is never just decoration. The control centre lists them and
// the widgets draw them from the same table.

var seals = [
  { key: "tomie",   text: "富\n江",     scale: 1.0,  name: "Tomie",
    note: "富江 — Tomie: the girl who will not stay dead, and keeps coming back." },
  { key: "uzumaki", text: "渦\n巻",     scale: 1.0,  name: "Uzumaki",
    note: "渦巻 — \"spiral\": the shape that curses a whole town." },
  { key: "ito",     text: "伊\n藤",     scale: 1.0,  name: "Junji Ito",
    note: "伊藤 — Ito: the family name of the artist himself." },
  { key: "silent",  text: "静\n丘",     scale: 1.0,  name: "Silent Hill",
    note: "静丘 — \"quiet hill\": the fog-eaten town this palette borrows its cold from." },
  { key: "remina",  text: "レ\nミ\nナ", scale: 0.72, name: "Remina",
    note: "レミナ — Remina: the planet that devours every world it passes." }
]

// `fx` is the effect a mark has by default (Effects page, "Auto"): a round mark turns, a face keeps a
// heartbeat, a figure breathes. Turning a mark that has an up and a down would only wreck it.
var menuMarks = [
  { key: "uzumaki",  art: "menu-uzumaki.png",       name: "Uzumaki", fx: "spin",
    note: "Two arms of the spiral wound together, bone and blood. The curse is already in the menu." },
  { key: "tomie",    art: "menu-tomie.png",         name: "Tomie", fx: "heartbeat",
    note: "Her face behind the long black hair, and the mole that always gives her away." },
  { key: "remina",   art: "menu-remina.png",        name: "Remina", fx: "pulse",
    note: "The planet that eats worlds: one bloodshot eye in it, and a small world on its way in." },
  { key: "amigara",  art: "menu-amigara.png",       name: "Amigara", fx: "breathe",
    note: "The mountain full of holes cut to the shape of people, and the one that is yours." },
  { key: "metatron", art: "menu-metatron-full.png", name: "Metatron", fx: "spin",
    note: "The Seal of Metatron of Silent Hill, as the game draws it: runes, three circles and an eye." },
  { key: "metatron-mini", art: "menu-metatron.png", name: "Metatron, plain", fx: "spin",
    note: "The same seal cut down to what survives at bar size: the ring, the eye, the three circles." },
  { key: "halo",     art: "menu-halo.png",          name: "Halo", fx: "spin",
    note: "The Halo of the Sun: a disc with flares that alternate long and short." },
  { key: "flauros",  art: "menu-flauros.png",       name: "Flauros", fx: "spin",
    note: "A ring cut by a cross, a small circle in every quarter, and blood where the arms meet." },
  { key: "spiral",   art: "system-normal.png",      name: "Sheet spiral", fx: "breathe",
    note: "The spiral from the design sheet, drawn by hand." }
]

// A mark the user added (see bin/ito-marks): its adapted picture lives in the cache folder.
function customArt(key) {
  return key.indexOf("custom:") === 0 ? key.substring(7) : ""
}

// Where a mark's picture is: the art folder for the built-in ones, the cache folder for the user's.
// `home` is the user's home directory, needed only for a custom one; `overrides` maps a built-in key to a picture
// of the user's own that replaces it (ItoConfig.markOverrides).
function source(artBase, key, home, overrides) {
  if (overrides && overrides[key]) return "file://" + overrides[key]
  var custom = customArt(key)
  if (custom !== "") return "file://" + home + "/.cache/ito/marks/" + custom + ".png"
  return artBase + "system/" + find(menuMarks, key).art
}

// The effect a mark has when the user has left the choice on Auto.
function autoEffect(key) {
  return customArt(key) !== "" ? "pulse" : find(menuMarks, key).fx
}

function find(list, key) {
  for (var i = 0; i < list.length; i++)
    if (list[i].key === key) return list[i]
  return list[0]
}

// Not in `seals` on purpose: it would show as a sixth, directly-clickable card in the seal picker before
// any picture has actually been chosen, and picking it that way leaves the seal blank. The picker sets
// seal="custom" itself, only once sealPicker has actually adapted a picture -- see PageLogo.qml.
var customSeal = { key: "custom", text: "", scale: 1.0, name: "Your picture", custom: true,
  note: "Your own picture, adapted to the shell, in place of the letters." }

function findSeal(key) {
  return String(key) === "custom" ? customSeal : find(seals, key)
}


// What stands on both sides of the seal. `veins` is the design's own bloodline; the rest are drawn in the same
// ink (scripts/gen-decor.py). `none` leaves the seal alone. The right-hand one is the left mirrored.
var decorations = [
  { key: "veins", wide: 1.5,    art: "decor/veins.png", name: "Veins",    note: "The bloodlines of the original design, reaching out of the seal." },
  { key: "thorns", wide: 1.25,   art: "decor/thorns.png",     name: "Thorns",   note: "A barbed stem, blood at every tip." },
  { key: "curls", wide: 1.25,    art: "decor/curls.png",      name: "Curls",    note: "Two Uzumaki spirals on one stem." },
  { key: "hair", wide: 1.3,     art: "decor/hair.png",       name: "Hair",     note: "Long strands of black hair, one caught in a curl." },
  { key: "drips", wide: 1.05,    art: "decor/drips.png",      name: "Drips",    note: "Blood running down in three trails that end in drops." },
  { key: "eyes", wide: 1.6,     art: "decor/eyes.png",       name: "Eyes",     note: "Three eyes from the Uzumaki panel, stacked and watching; the middle one bloodshot." },
  { key: "cracks", wide: 1.3,   art: "decor/cracks.png",     name: "Cracks",   note: "A crack through the plate, branching, with blood in it." },
  { key: "stitches", wide: 1.15, art: "decor/stitches.png",   name: "Stitches", note: "A seam sewn shut, one drop coming through." },
  { key: "holes", wide: 1.2,    art: "decor/holes.png",      name: "Holes",    note: "The Amigara Fault's holes, bored straight through, a rim of blood on some." },
  { key: "teeth", wide: 1.15,   art: "decor/teeth.png",      name: "Teeth",    note: "Fangs breaking through a slim spine, red only at the root." },
  { key: "chain", wide: 1.1,    art: "decor/chain.png",      name: "Chain",    note: "A rusted chain, corroded where the links wear thin." },
  { key: "static", wide: 1.3,   art: "decor/static.png",     name: "Static",   note: "The pocket radio's warning, cut into the stem instead of heard." },
  { key: "fog", wide: 1.4,      art: "decor/fog.png",        name: "Fog",      note: "Silent Hill's own fog, drifting up the stem and dissolving at both ends." },
  { key: "none", wide: 1.0,     art: "",                     name: "None",     note: "Nothing beside the seal." }
]

function decoration(cfg) {
  var wanted = String(cfg.get("sealDeco", "veins"))
  for (var i = 0; i < decorations.length; i++)
    if (decorations[i].key === wanted) return decorations[i]
  return decorations[0]
}


// The picture for a decoration or for the seal: the art folder for the built-in ones, or the user's own (adapted by
// bin/ito-marks into the cache) for "@custom".
function decoSource(artBase, deco, home) {
  if (!deco || deco.art === "") return ""
  if (deco.art === "@custom") return "file://" + home + "/.cache/ito/marks/_deco.png"
  return artBase + deco.art
}

function sealPicture(home) {
  return "file://" + home + "/.cache/ito/marks/_seal.png"
}
