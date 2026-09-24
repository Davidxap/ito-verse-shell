import QtQuick

// A sheet image that follows the shell's colour mode.
//
// The pre-drawn art is bone and crimson. With the shell following the installed theme, a shader moves both
// onto the theme (bone to its foreground, crimson to its accent) while keeping every pixel's brightness, so
// the engraving survives. With the shell on its own palette it costs nothing: the effect only exists
// while there is a theme to follow.
Image {
  id: root

  // The ItoConfig the colours come from (any widget's own instance will do).
  property var palette: null

  fillMode: Image.PreserveAspectFit
  smooth: true
  mipmap: true

  layer.enabled: !!palette && palette.tinted
  layer.effect: ItoThemeEffect { palette: root.palette }
}
