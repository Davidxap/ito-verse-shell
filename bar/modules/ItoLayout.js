.pragma library

// How large a popup may be, whichever edge the bar is on.
//
// Omarchy's own panel measures the room left beside the bar from the bar's window. This engine's bar window covers
// the whole screen (the bar itself is drawn and masked inside it), so that measure comes back as 120 px on a side
// bar and the popup is squeezed to a sliver. These take the bar's real thickness from `bar.barSize` instead.

function thickness(panel) {
  return panel.bar && panel.bar.barSize ? Number(panel.bar.barSize) : 46
}

function popupWidth(panel, desired) {
  var pos = panel.barPos
  var side = (pos === "left" || pos === "right") ? thickness(panel) + panel.gap + panel.margin : panel.margin * 2
  var avail = panel.screenW > 0 ? panel.screenW - side : desired
  return Math.round(Math.max(Math.min(desired, 240), Math.min(desired, avail)))
}

function popupHeight(panel, implicitHeight, cap) {
  var pos = panel.barPos
  var desired = Math.max(panel.verticalContentInset, (Number(implicitHeight) || 0) + panel.verticalContentInset)
  var edge = (pos === "top" || pos === "bottom") ? thickness(panel) + panel.gap + panel.margin : panel.margin * 2
  var avail = panel.screenH > 0 ? panel.screenH - edge : desired
  var most = cap !== undefined && Number(cap) > 0 ? Math.min(avail, Number(cap)) : avail
  return Math.round(Math.min(desired, most))
}
