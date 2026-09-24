.pragma library

// The widgets the bar can show, in the order the default layout places them, with what each one is.
// The panel lists these so any of them can be switched on or off; the ids are the plugin ids.

var widgets = [
  { id: "ito.spiral",     name: "Menu spiral",  note: "The spiral that opens the application menu." },
  { id: "ito.workspaces", name: "Workspaces",   note: "The workspace rings, seals, eyes or marks." },
  { id: "ito.clock",      name: "Clock",        note: "The time. Click it for the calendar." },
  { id: "ito.tomie",      name: "Seal",         note: "The centre seal, and the door to this panel. It stays on, so the panel can always be reached.", locked: true },
  { id: "ito.notifications", name: "Notifications", note: "The bell: still, in blood when something waits, an eye when silenced. Click to silence." },
  { id: "ito.indicators", name: "Indicators",  note: "Stay awake, night light and recording, each in the version you choose." },
  { id: "ito.media",      name: "Media",        note: "Previous, play or pause, and next for whatever is playing." },
  { id: "ito.date",       name: "Date",         note: "The day. Click it for the calendar." },
  { id: "ito.weather", reading: true,    name: "Weather",      note: "The sky outside, and the days ahead." },
  { id: "ito.tray", reading: true,       name: "Tray",         note: "Apps running in the background, in one jar." },
  { id: "ito.network",  name: "Network",      note: "Wi-Fi or ethernet, and the signal." },
  { id: "ito.bluetooth", name: "Bluetooth",   note: "The Bluetooth rune, and what is connected." },
  { id: "ito.audio", reading: true,    name: "Volume",       note: "Output volume. Scroll on it to change it." },
  { id: "ito.display", reading: true, content: "icon",  name: "Brightness",   note: "Screen brightness. Scroll on it to change it." },
  { id: "ito.power", reading: true,    name: "Battery",      note: "The battery, when there is one." },
  { id: "ito.ai", reading: true,         name: "AI usage",     note: "How much of the AI quota is spent, as a brain." },
  { id: "ito.cpu", reading: true,        name: "Processor",    note: "CPU load." },
  { id: "ito.mem", reading: true,        name: "Memory",       note: "RAM in use." },
  { id: "ito.disk", reading: true,       name: "Disk",         note: "How full the disk is." }
]


// What a widget shows before the user has chosen: both its icon and its reading, except where the reading is
// something nobody watches (the screen's brightness), which shows the icon alone; the number is one click away.
function defaultContent(id) {
  for (var i = 0; i < widgets.length; i++)
    if (widgets[i].id === id) return widgets[i].content || "both"
  return "both"
}
