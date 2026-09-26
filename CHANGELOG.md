# Changelog

## Unreleased

**Popups**
- Every popup is drawn as a manga panel: ruled double edge, torn corners, blood and screentone, a burst of static as it opens,
  an emblem for what it watches (waves, web, rune, flame, hourglass, spiral, bell, mind, the sky) and a note at the foot chosen
  from several original lines. Switch: Bars > "Manga frame on popups".
- New: a **media player** (cover, title, seekable progress, shuffle, repeat, controls; right-click the media rings), a
  **notification history** (right-click the bell), and a redesigned **calendar**, **forecast** and **AI usage** panel.
- Popups open beside the bar on any edge (top, bottom, left, right) and fit the screen. Fixed: on a side bar the audio,
  network and other popups came out 120 px wide.
- Fixed: the forecast's icons were unsized, so they came out huge and the hourly row ran off the edge.
- IPC for keybindings: `ito.player`, `ito.calendar`, `ito.weather`, `ito.notifycenter`, `ito.aiusage` (each `open`, `close`,
  `toggle`).

**Motion and cost**
- **Motion** setting (Effects): off, calm or lively. Popups, labels, the Control Centre and the workspace marks follow it;
  numbers glide to their new value.
- The idle cost of the shell dropped from about 3 % to 0.5 % of one core: the seal only breathes while an effect is on.

**Look**
- Labels over the bar follow the theme; "Tint labels with the accent" brings the accent back.
- Removed old sheet-derived icons that carried text and were not used by the shell. The "Eyes" decoration and effect now use
  original artwork committed to the repository instead of untracked third-party art.
- The Control Centre footer credits the author with a link.

**Compatibility**
- Tested: bar on top, bottom, left and right; Islands, Full, Fit, Dock and Notch; motion off, calm and lively; frame on and off.
- Ryoku: not supported yet (see the README's Compatibility table).

## 0.1.0-beta

The first public version.

**The bar**
- Bar engine forked from Shibumi-Shell (HANCORE, MIT) with its own `itoverse` style; shapes Islands, Full, Fit, Dock, Notch;
  any of the four edges; corners, heights, spacings, shadow, float.
- 19 widgets: menu spiral, workspaces, clock, date, seal, weather, AI usage, indicators (stay awake, night light,
  recording), media, tray, notifications, network, Bluetooth, volume, brightness, battery, CPU, memory, disk.
- Readings that say what they measure: `CPU 4%`, `RAM 17/32G`, `DISK 210/930G`; Percent, Amount, Number or Off.
- Popups that close by themselves after a few seconds (adjustable, or never).
- Stay awake and Do Not Disturb read through `ito-host`, independent of Omarchy's own services.

**The Control Centre**
- Nine pages with foldable sections, search that opens matches, and a footer that says what a control does.
- Icons: your bar in three columns with a switch and arrows per widget.
- Eight workspace styles (Seals, Rings, Tomie, Remina, Uzumaki, Marks, Halo, Flauros) and a Custom style from four pictures.
- Five seals, thirteen decorations, nine menu marks, eight motions, six media effects.
- Your own pictures and GIFs for the menu mark, seal, decoration, workspaces and media effect, with exact sizes and limits.
- Setup: named setups (`ito-profile`), switching between Omarchy's default bar, Shibumi, Caelestia and Ito-verse.
- `omarchy-shell ito.controlcenter toggle|open|close|page <name>` from a key or a script.

**Themes**
- Works on light and dark themes alike: the art is mapped between the theme's background and foreground (it used to keep a black
  plate under a light theme, which made the text unreadable), and the accent follows the theme.

**Health**
- Checks for the engine, the state, settings, fonts, themes, widgets, the seal, duplicate bars, virtual screens, the engine's
  signature, the active bar, art files, your pictures, slider ranges, helper programs and the log.
- A Fix for most, `Fix everything`, and a report written for AI assistants (`ito-health --report`).

**Install**
- `deploy.sh` stops the shell before copying when anything changed, refreshes the engine signature and restarts once; it does
  nothing when nothing changed.
- `seed-variant.py` makes `shell.ito.json` on a fresh machine and keeps the shell you were on as its own variant.

**Licence and credits**
- Code under PolyForm Noncommercial 1.0.0; the forked engine and five re-skinned Omarchy widgets keep their MIT licences with
  the original notices; the art is for personal, non-commercial use. See `NOTICE`.
