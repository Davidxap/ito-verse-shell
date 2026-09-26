# Changelog

## Unreleased

- **Motion** setting (Effects): off, calm or lively. Labels, popups, the Control Centre and the workspace marks follow it;
  numbers glide to their new value.
- Popups are drawn as manga panels (ruled frame, torn corners, blood, screentone) with a burst of static on opening, an eye
  that opens at the head, a crack when something is wrong and a short note at the foot. Switch: Bars > "Manga frame on popups".
- Media player popup: right-click the media rings (or `omarchy-shell ito.player toggle`) for the cover, the title, a progress
  line you can seek on, shuffle, repeat and the controls.
- Labels over the bar follow the theme; "Tint labels with the accent" brings the accent back.
- The idle cost of the shell dropped from about 3% to 0.5% of one core: the seal only breathes while an effect is on.
- Removed old sheet-derived icons that carried text and were not used by the shell.

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
