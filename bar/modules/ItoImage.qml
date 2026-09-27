import QtQuick

// A sheet image that follows the shell's colour mode.
//
// The pre-drawn art is bone and crimson. With the shell following the installed theme, a shader moves both
// onto the theme (bone to its foreground, crimson to its accent) while keeping every pixel's brightness, so
// the engraving survives. With the shell on its own palette it costs nothing: the effect only exists
// while there is a theme to follow.
//
// That rule only holds for art drawn that way. A picture the user chose themselves (a manga panel, a photo) is
// full of colour and shade the shader has no rule for; pushed through it, every tone gets flattened onto the
// two or three colours of the theme and the picture is ruined. `tintable: false` leaves a picture exactly as
// the user chose it, whatever the theme.
Image {
  id: root

  // The ItoConfig the colours come from (any widget's own instance will do).
  property var palette: null
  property bool tintable: true

  fillMode: Image.PreserveAspectFit
  smooth: true
  mipmap: true

  layer.enabled: !!palette && palette.tinted && tintable
  layer.effect: ItoThemeEffect { palette: root.palette }
}
