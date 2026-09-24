.pragma library

// How the shell moves.
//
// Caelestia is the reference for feel: nothing snaps, nothing is linear, and arrivals are quick then settle
// (long deceleration tails) while departures are brisk. That comes from a few bezier curves and three
// durations used everywhere, not from every widget picking its own numbers. A component takes a curve
// with `easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.decel`.
//
// Curves are cubic-bezier control points [x1, y1, x2, y2, 1, 1], the form QML's BezierSpline takes.

var fast = 140          // hover, press, a mark lighting
var normal = 260        // a card, a page, a value settling
var slow = 440          // a panel arriving, a plate changing shape

var decel = [0.05, 0.7, 0.1, 1, 1, 1]              // arrivals: quick out of the gate, a long soft landing
var accel = [0.3, 0, 0.8, 0.15, 1, 1]              // departures: they leave briskly
var standard = [0.2, 0, 0, 1, 1, 1]                // state changes that stay in place
var spring = [0.38, 1.21, 0.22, 1, 1, 1]           // spatial moves that overshoot a hair and settle
var soft = [0.34, 0.8, 0.34, 1, 1, 1]              // effects: opacity, colour
