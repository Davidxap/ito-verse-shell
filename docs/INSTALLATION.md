# Installation

Requires an existing Omarchy install running Hyprland. There is no installer script beyond
`scripts/deploy.sh` and `scripts/shell-switch` — both are safe to run repeatedly.

## Requirements

- **Omarchy** with **Hyprland**, on Arch Linux (developed and tested on Omarchy 4.0.4, Quickshell 0.3.x, Hyprland 0.56,
  Qt 6.11). The bar is a plugin of Omarchy's shell engine; it does not run without it.
- Fonts: `noto-fonts` and `noto-fonts-cjk` (the numbers, the clock and the kanji seal).
- Tools the installer and the panel use: `rsync`, `jq`, `python` with `python-pillow` and `python-numpy` (to adapt your own
  pictures), `zenity` (or `kdialog`/`yad`, the file dialog), `wl-clipboard` (to copy the Health report), `librsvg` (only for SVG
  pictures).

Install them with your package manager. On Arch the packages are named `noto-fonts`, `noto-fonts-cjk`, `rsync`, `jq`,
`python-pillow`, `python-numpy`, `zenity`, `wl-clipboard` and `librsvg`.

`bar/modules/bin/ito-health` checks all of this and says what is missing.

## First install

**Option A: the Omarchy plugin.** `omarchy plugin add https://github.com/Davidxap/ito-verse-shell`, enable the *Install
Ito-verse Shell* widget on your bar, and click it. A terminal opens, says what it will do (copy the shell into
`~/.config/omarchy`, keep your own settings, keep the shell you use now as its own entry) and asks before it changes anything;
it then offers to switch to Ito-verse Shell. It is the same as running `install.sh` from the plugin's folder.

**Option B: by hand.** Download the repository from GitHub (the green **Code** button, then **Download ZIP**), unzip it and open a
terminal in the folder:

```bash
# 1. System colours (GTK, terminal, Hyprland borders, ...) via Omarchy's own theme switcher.
cp -r themes/ito-verse ~/.config/omarchy/themes/ito-verse
omarchy theme set ito-verse

# 2. The bar and its widgets: copy the repo onto the live config.
scripts/deploy.sh
```

`scripts/deploy.sh` (a thin wrapper over `scripts/sync.sh push`) copies `bar/modules/`, every
`plugins/ito.*` folder and `themes/ito-verse/` onto `~/.config/omarchy`, preserving your own
`ito-style.json` settings if one already exists, and regenerates the bar engine's suite-marker
signature (`scripts/gen-itobar-marker.py`) so the engine doesn't refuse to start. It restarts the
shell itself, but only if it detects the shell is already running and something actually changed. On a machine
that has never run Ito-verse it first keeps the shell you are on now (Omarchy's default, Shibumi, …) as a variant of its own, so you can switch back to it, and then creates `~/.config/omarchy/shell.ito.json` (your own shell config plus the
Ito-verse bar, from `seed/shell.ito.json`) so that the next step can find it; an existing one is never overwritten.

```bash
# 3. Make Ito-verse's shell the active one.
scripts/shell-switch ito
```

`scripts/shell-switch` detects every shell it can find (Omarchy variants by their
`shell.<name>.json`, plus Caelestia if installed), saves whatever was active before switching, and
swaps cleanly (stop → save → swap → start → verify, rolling back automatically if the new shell
fails to come up). Run it with no argument to list what it found.

### Optional: the cursor and the icons

The Tomie colour theme (step 1) does not select a cursor or icon theme by itself. To build and install them:

```bash
python3 scripts/gen-cursors.py            # the Ito-verse cursor theme, into ~/.local/share/icons/Ito-verse
python3 scripts/gen-icons.py --install    # the inked icon theme, into ~/.local/share/icons/Ito-verse-icons
```

Installing them changes nothing until something selects them (your desktop's cursor and icon settings).
`ito-health` reports whether they are installed.

## Updating

```bash
git pull
scripts/deploy.sh
```

That's the whole update: deploy.sh only touches what changed and only restarts if it needs to.

## Verifying it worked

```bash
bar/modules/bin/ito-health --text
bar/modules/bin/ito-restart status    # {"shells":1,"launchers":1,"headless":[]} is a clean result
```

`ito-health` should report every check `ok`. If it doesn't, it names what's wrong and how to fix it
— `ito-health --fix all` applies every fix it considers safe. See `docs/TROUBLESHOOTING.md` for what
each check means.

## Uninstalling

```bash
scripts/shell-switch <whatever you were on before>   # e.g. omarchy
omarchy theme set <whatever theme you were on before>
rm -rf ~/.config/omarchy/plugins/ito.*
rm -rf ~/.config/omarchy/bar/modules       # only if nothing else uses this folder
rm -rf ~/.config/omarchy/themes/ito-verse
```

Switch shells and revert the colour theme **before** deleting any files — `shell-switch` needs the
files present to shut the shell down cleanly.

## What "reversible" means here

Every step above is reversible on its own: the colour theme through `omarchy theme set`, the bar
through `shell-switch`, individual settings through the Control Centre's own reset buttons or
`bin/ito-config reset`. Nothing here modifies Omarchy's own stock bar or theme files in place — a
clone (`ito.audio` etc.) lives beside the original Omarchy widget it was cloned from, not over it.
