import QtQuick

// The shader that moves the shell's pre-drawn art onto the installed theme (see shaders/ito-theme.frag).
// Used as a layer effect: Qt hands the layer to `source` itself.
ShaderEffect {
  id: root

  property var palette: null
  property variant source

  // what the art is drawn in, and what it should become
  property color fg: palette ? palette.bone : "#c7ccd1"
  property color accent: palette ? palette.blood : "#c4162a"
  property color bg: palette ? palette.ink : "#050607"
  property color baseFg: "#c7ccd1"
  property color baseAccent: "#c4162a"

  fragmentShader: Qt.resolvedUrl("shaders/ito-theme.frag.qsb")
}
