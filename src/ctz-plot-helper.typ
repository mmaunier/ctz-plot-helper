#import "@preview/cetz:0.5.2": canvas, coordinate, draw
#import "@preview/cetz-plot:0.1.4": plot

/// Rotates the point (x, y) by `angle` around the center (cx, cy).
///
/// - cx (float, int): x-coordinate of the rotation center
/// - cy (float, int): y-coordinate of the rotation center
/// - x (float, int): x-coordinate of the point to rotate
/// - y (float, int): y-coordinate of the point to rotate
/// - angle (angle): rotation angle
/// -> array
#let rotate-point(
  /// X-coordinate of the rotation center.
  /// -> float | int
  cx,
  
  /// Y-coordinate of the rotation center.
  /// -> float | int
  cy,
  
  /// X-coordinate of the point to rotate.
  /// -> float | int
  x,
  
  /// Y-coordinate of the point to rotate.
  /// -> float | int
  y,
  
  /// Rotation angle.
  /// -> angle
  angle,
) = {
  let dx = x - cx
  let dy = y - cy
  let c = calc.cos(angle)
  let s = calc.sin(angle)
  (cx + dx * c - dy * s, cy + dx * s + dy * c)
}

/// Draws the "mark" of a point at a position ALREADY IN CANVAS
/// COORDINATES (x, y in cm). Shared by anchored-point (draws in cm,
/// outside the plot). Do not call directly in normal use.
///
/// - x (float, int): x-coordinate of the point, in canvas units
/// - y (float, int): y-coordinate of the point, in canvas units
/// - symbol (str): "o" (circle), "x" (cross), "+" (plus), "square" (square), "triangle", "diamond" (diamond)
/// - size (float, int): half-size of the symbol, in the same unit as x, y
/// - fill (color, auto): fill color for closed shapes ("o", "square", "diamond", "triangle") — NOT for "+"/"x" (strokes): use `stroke` instead, an explicit `fill` with "+"/"x" panics
/// - stroke (none, stroke, color): outline of closed shapes (none = no outline, just fill)
/// - angle (angle): orientation (relevant for "square", "triangle", "diamond", "+", "x" — no effect on "o")
/// -> content
#let draw-mark-shape(
  /// X-coordinate of the point, in canvas units.
  /// -> float | int
  x,
  
  /// Y-coordinate of the point, in canvas units.
  /// -> float | int
  y,
  
  /// "o" (circle), "x" (cross), "+" (plus), "square" (square), "triangle", "diamond" (diamond).
  /// -> string
  symbol: "o",
  
  /// Half-size of the symbol, in the same unit as x, y.
  /// -> float | int
  size: 0.06,
  
  /// Fill color for closed shapes; `auto` = red. Must NOT be set for "+"/"x" (use `stroke` instead).
  /// -> color | auto
  fill: auto,
  
  /// Outline of closed shapes (none = no outline, just fill).
  /// -> none | stroke | color
  stroke: none,
  
  /// Orientation (relevant for "square", "triangle", "diamond", "+", "x" — no effect on "o").
  /// -> angle
  angle: 0deg,
) = {
  import draw: circle, line

  if (symbol == "+" or symbol == "x") and fill != auto {
    panic(
      "marker: the symbol '" + symbol + "' is a stroke, not a filled shape — "
        + "use `stroke` to change its color, not `fill`.",
    )
  }

  let fill = if fill == auto { red } else { fill }
  
  if symbol == "o" or symbol == "circle" {
    circle((x, y), radius: size, fill: fill, stroke: stroke)
  } else if symbol == "square" {
    let pts = (
      ((-1, -1), (1, -1), (1, 1), (-1, 1)).map(((dx, dy)) => rotate-point(x, y, x + dx * size, y + dy * size, angle))
    )
    line(..pts, close: true, fill: fill, stroke: stroke)
  } else if symbol == "diamond" {
    let pts = (
      ((0, -1), (1, 0), (0, 1), (-1, 0)).map(((dx, dy)) => rotate-point(x, y, x + dx * size, y + dy * size, angle))
    )
    line(..pts, close: true, fill: fill, stroke: stroke)
  } else if symbol == "triangle" {
    let pts = (
      ((0, 1), (-0.87, -0.5), (0.87, -0.5)).map(((dx, dy)) => rotate-point(x, y, x + dx * size, y + dy * size, angle))
    )
    line(..pts, close: true, fill: fill, stroke: stroke)
  } else if symbol == "+" {
    let s = if stroke == none { 1pt } else { stroke }
    line(
      rotate-point(x, y, x - size, y, angle),
      rotate-point(x, y, x + size, y, angle),
      stroke: s,
    )
    line(
      rotate-point(x, y, x, y - size, angle),
      rotate-point(x, y, x, y + size, angle),
      stroke: s,
    )
  } else if symbol == "x" {
    let s = if stroke == none { 1pt } else { stroke }
    line(
      rotate-point(x, y, x - size, y - size, angle),
      rotate-point(x, y, x + size, y + size, angle),
      stroke: s,
    )
    line(
      rotate-point(x, y, x - size, y + size, angle),
      rotate-point(x, y, x + size, y - size, angle),
      stroke: s,
    )
  } else {
    panic("marker: unknown symbol '" + symbol + "'")
  }
}


/// Scatter plot: draws a marker at each point of `points`. To be used
/// like plot.add(...), INSIDE plot.plot(...) — i.e. directly inside
/// newFig's `body` — coordinates stay in DATA units, cetz-plot handles
/// the scaling itself. Thin wrapper around plot.add(...), with a
/// friendlier marker vocabulary (mark-fill/mark-stroke instead of
/// a raw mark-style dictionary).
///
/// - points (array): list of (x, y) point tuples, in data units
/// - mark (str): marker shape ("o", "x", "+", "square", "triangle", "diamond"...), forwarded to plot.add(mark:)
/// - mark-fill (color): marker fill color
/// - mark-stroke (none, stroke, color): marker outline (none = no outline)
/// - mark-size (float, int): marker size, forwarded to plot.add(mark-size:)
///
/// ```example
/// #newFig(x-min : 0, x-max:8, y-min: 0, y-max: 5,
///   {
///     scatter(
///       ((1, 4.8), (2, 3.8), (4, 3), (6, 1.7), (7, 1.3)),
///       mark: "x",
///       mark-stroke: blue,
///       mark-size: 0.2,
///     )
///   },
/// )
/// ```
///
/// -> array
#let scatter(
  /// List of (x, y) point tuples, in data units.
  /// -> array
  points,
  
  /// Marker shape ("o", "x", "+", "square", "triangle", "diamond"...), forwarded to plot.add(mark:).
  /// -> string
  mark: "o",
  
  /// Marker fill color.
  /// -> color
  mark-fill: black,
  
  /// Marker outline (none = no outline).
  /// -> none | stroke | color
  mark-stroke: 1pt + black,
  
  /// Marker size, forwarded to plot.add(mark-size:).
  /// -> float | int
  mark-size: 0.1,
) = {
  plot.add(
    points,
    style: (stroke: none),
    mark: mark,
    mark-style: (fill: mark-fill, stroke: mark-stroke),
    mark-size: mark-size,
  )
}

/// Scale factors (canvas units per data unit) of a plot whose physical
/// size and (fixed) domain of both axes are known. Used to convert a real
/// slope into a visual on-screen slope.
///
/// - size (array): physical size of the plot (width, height), in cm
/// - x-domain (array): domain (x-min, x-max) of the x-axis
/// - y-domain (array): domain (y-min, y-max) of the y-axis
/// -> dictionary
#let plot-scale(
  /// Physical size of the plot (width, height), in cm.
  /// -> array
  size,
  
  /// Domain (x-min, x-max) of the x-axis.
  /// -> array
  x-domain,
  
  /// Domain (y-min, y-max) of the y-axis.
  /// -> array
  y-domain,
) = {
  let (w, h) = size
  let (xmin, xmax) = x-domain
  let (ymin, ymax) = y-domain
  (sx: w / (xmax - xmin), sy: h / (ymax - ymin))
}

/// Resolves `origine` to a CANVAS position (cm): either an existing anchor
/// ("plot.<name>"), or (x, y) coordinates in the frame units (O ; i, j) —
/// in which case it starts from the "plot.O" anchor and applies sx, sy.
/// Used by anchored-basis-vectors, anchored-point and
/// anchored-derivative-arrow; not meant to be called directly.
///
/// - ctx (dictionary): current cetz context (provided by get-ctx)
/// - origine (str, array): anchor "plot.<name>", or (x, y) in data units
/// - sx (float, int): scale factor along x (cm per data unit)
/// - sy (float, int): scale factor along y (cm per data unit)
/// -> array
#let resolve-origine(
  /// Current cetz context (provided by get-ctx).
  /// -> dictionary
  ctx,
  
  /// Anchor "plot.<name>", or (x, y) in data units.
  /// -> string | array
  origine,
  
  /// Scale factor along x (cm per data unit).
  /// -> float | int
  sx,
  
  /// Scale factor along y (cm per data unit).
  /// -> float | int
  sy,
) = {
  if type(origine) == str {
    coordinate.resolve(ctx, origine)
  } else {
    let plot-name = ctx.at("plot-name", default: "plot")
    let (ctx, o) = coordinate.resolve(ctx, plot-name + ".O")
    let (ox, oy, ..) = o
    let (dx, dy) = origine
    (ctx, (ox + dx * sx, oy + dy * sy))
  }
}


/// Draws a polyline (successive segments) between several points of the
/// frame (O ; i, j) — each point is a "plot.<name>" anchor or (x, y)
/// coordinates in data units, as in resolve-origine. The points are
/// converted to canvas coordinates BEFORE being connected, so the stroke
/// stays straight on screen even in an anisotropic frame (unlike a line
/// drawn in data units inside the plot). To be called OUTSIDE
/// plot.plot(...). Automatically retrieves sx, sy (computed by newFig):
/// nothing to pass again.
///
/// - points (str | array): "plot.<name>" anchors and/or (x, y) coordinates, at least two
/// - stroke (stroke): line stroke
/// - mark (none | dictionary): arrowheads at the ends (see line(mark:))
///
/// ```example
/// #newFig(
///   extra: (sx, sy) => {
///     import draw: *
///     // dashed lines (0 ; f) -- (x ; f) -- (x ; 0)
///     anchored-lines((0, 1), (1, 1), (1, 0), stroke: (thickness: 0.75pt, dash: "dashed", paint: red))
///   },
///   { plot.add(domain: (-2, 2), x => calc.pow(x, 2), style: (stroke: blue + 0.5pt), samples: 50) },
/// )
/// ```
///
/// -> content
#let anchored-lines(
  /// "plot.<name>" anchors and/or (x, y) coordinates, at least two.
  /// -> string | array
  ..points,
  
  /// Line stroke.
  /// -> stroke
  stroke: black + 1pt,
  
  /// Arrowheads at the ends (see line(mark:)).
  /// -> none | dictionary
  mark: none,
) = {
  import draw: get-ctx, line
  
  let pts = points.pos()
  
  get-ctx(ctx => {
    let (sx, sy) = ctx.at("helper-scale", default: (1, 1))
    let ctx = ctx
    let canvas-pts = ()
    for p in pts {
      let (new-ctx, pos) = resolve-origine(ctx, p, sx, sy)
      ctx = new-ctx
      let (x, y, ..) = pos
      canvas-pts.push((x, y))
    }
    
    if mark == none {
      line(..canvas-pts, stroke: stroke)
    } else {
      line(..canvas-pts, stroke: stroke, mark: mark)
    }
  })
}


// Detection of a bare coordinate (x, y): an array of two numbers.
#let _is-bare-coord(v) = (
  type(v) == array
    and v.len() == 2
    and (type(v.at(0)) == int or type(v.at(0)) == float)
    and (type(v.at(1)) == int or type(v.at(1)) == float)
)

// Normalizes the `marker:` dictionary — accepted under two vocabularies:
//   - internal: (marker-symbol, marker-size, marker-fill, marker-stroke, marker-angle)
//   - cetz (like plot.add): (mark, mark-fill, mark-stroke, mark-size)
// Returns a complete dictionary (defaults merged) in the internal vocabulary,
// or `none` if `marker` is `none`.
#let _normalize-marker(marker) = {
  if marker == none { return none }
  if marker.at("mark", default: none) != none {
    // cetz style: conversion to the internal vocabulary
    (
      marker-symbol: marker.at("mark", default: "o"),
      marker-size: marker.at("mark-size", default: 0.06),
      marker-fill: marker.at("mark-fill", default: auto),
      marker-stroke: marker.at("mark-stroke", default: none),
      marker-angle: marker.at("marker-angle", default: 0deg),
    )
  } else {
    // internal style: simple merge with the defaults
    (marker-symbol: "o", marker-size: 0.06, marker-fill: auto, marker-stroke: none, marker-angle: 0deg) + marker
  }
}


/// Optional marker and/or label at a plot anchor OR at (x, y) coordinates
/// in the frame units (O ; i, j) — see resolve-origine. Automatically
/// retrieves sx, sy (computed by newFig). To be called OUTSIDE
/// plot.plot(...). Each item is independent: if `marker` or `label` is
/// `none`, it is not drawn (both `none` → nothing at all).
///
/// - origine (str, array): anchor "plot.<name>", or (x, y) in data units
/// - marker (dictionary, none): (marker-symbol, marker-size, marker-fill, marker-stroke, marker-angle) — see draw-mark-shape ; none = no point
/// - label (dictionary, none): (label-text, label-distance, label-anchor, label-position, label-rotate, label-styles) ; none = no label
///
/// ```example
/// #newFig(
///   extra: (sx, sy) => {
///     import draw: *
///     // marker + label (each is optional)
///     anchored-point((1, 1), marker: (marker-fill: red), label: (label-text: "A", label-position: 90deg))
///     // label only, without a point, rotated 20°
///     anchored-point((-1, 1), marker: (marker-symbol: "x", marker-size: 0.06, marker-stroke: 1pt+purple), label: (label-text: text(fill: purple)[B], label-position: -135deg, label-rotate: 20deg))
///   },
///   { plot.add(domain: (-2, 2), x => calc.pow(x, 2), style: (stroke: blue + 0.5pt), samples: 50) },
/// )
/// ```
///
/// -> content
#let anchored-point(
  /// Anchor "plot.<name>", or (x, y) in data units.
  /// -> string | array
  origine,
  
  /// Marker dictionary — two accepted vocabularies, see draw-mark-shape ;
  /// `none` = no point:
  ///   - internal: (marker-symbol, marker-size, marker-fill, marker-stroke, marker-angle)
  ///   - cetz/plot.add style: (mark, mark-fill, mark-stroke, mark-size)
  /// -> dictionary | none
  marker: (marker-symbol: "o", marker-size: 0.06, marker-fill: auto, marker-stroke: none, marker-angle: 0deg),
  
  /// (label-text, label-distance, label-anchor, label-position, label-rotate, label-styles) ; none = no label.
  /// -> dictionary | none
  label: (
    label-text: "",
    label-distance: 8pt,
    label-anchor: "center",
    label-position: 0deg,
    label-rotate: 0deg,
    label-styles: (:),
  ),
) = {
  import draw: content, get-ctx
  
  // Nothing to draw: do nothing at all
  if marker == none and label == none {
    return ()
  }
  
  // Normalize the marker dictionary (two accepted vocabularies) then
  // merge the defaults; `none` = no point.
  let m = _normalize-marker(marker)
  let l = if label == none {
    none
  } else {
    (
      (
        label-text: "",
        label-distance: 8pt,
        label-anchor: "center",
        label-position: 0deg,
        label-rotate: 0deg,
        label-styles: (:),
      )
        + label
    )
  }
  
  get-ctx(ctx => {
    let (sx, sy) = ctx.at("helper-scale", default: (1, 1))
    let (ctx, pos) = resolve-origine(ctx, origine, sx, sy)
    let (x, y, ..) = pos
    
    // Marker (point), drawn at (x, y) if requested
    if m != none {
      draw-mark-shape(
        x,
        y,
        symbol: m.marker-symbol,
        size: m.marker-size,
        fill: m.marker-fill,
        stroke: m.marker-stroke,
        angle: m.marker-angle,
      )
    }
    
    // Label, placed at `label-distance` from the point in the direction
    // `label-position` (0deg = right, 90deg = up...), with `label-anchor`
    // as the text anchor at that position, and rotated `label-rotate`
    // around its own center
    if l != none {
      // label-styles is spread into text(...): content with its own styles
      // (e.g. text(fill: purple)[B]) keeps priority; label-styles only fills
      // in what is not already specified.
      let body = text(..l.label-styles, l.label-text)
      // distance in canvas units (1 unit = 1 cm): a length (pt, cm...)
      // is converted; a raw number is taken as is (already in cm)
      let dist = if type(l.label-distance) == length {
        l.label-distance / 1cm
      } else {
        l.label-distance
      }
      content(
        (x + dist * calc.cos(l.label-position), y + dist * calc.sin(l.label-position)),
        anchor: l.label-anchor,
        angle: l.label-rotate,
        body,
      )
    }
  })
}


/// Draws several points (and, optionally, their labels) in one call.
/// Each item may be either:
///   - a bare coordinate (x, y) or a bare anchor "plot.<name>": no label,
///   - a pair (origine, label-text): same `origine` vocabulary as
///     anchored-point, and label-text is either the text/content for THIS
///     point's label, or `none` to skip the label for that point.
/// The two forms can be mixed freely: each item is detected automatically
/// (an item whose first element is itself an array/string is treated as
/// (origine, label-text)). The `marker:`/`label:` options are shared by
/// every point (same vocabulary as anchored-point) — `label: none` (or
/// `marker: none`) turns off labels (or markers) for ALL points at once,
/// regardless of what each item says. The shared `label:` options also
/// accept `label-styles`, a dictionary spread into `text(...)` to style
/// every label at once (an explicitly styled `label-text` keeps priority).
///
/// - points (array): per point, a bare (x, y) / anchor string, or a pair (origine, label-text) — label-text may be none
/// - marker (dictionary, none): shared marker options (marker-* or cetz mark:* vocabulary), see anchored-point ; none = no markers at all
/// - label (dictionary, none): shared label options (label-text here is overridden per point, label-styles is spread into text()), see anchored-point ; none = no labels at all
///
/// ```example
/// #newFig(y-min: -1, y-max: 5,
///   extra: (sx, sy) => {
///     import draw: *
///     anchored-points(
///       (1, 1),             // bare point, no label
///       ((2, 4), "B"),      // point with label
///       ((3, 2), none),     // point, label explicitly disabled
///       marker: (mark: "o", mark-fill: red, mark-stroke: 1pt + blue),
///       label: (label-position: -45deg, label-distance: 6pt, label-styles: (fill: blue, size: 0.8em)),
///     )
///   },
///   { plot.add(domain: (-3, 3), x => calc.pow(x, 2), style: (stroke: blue + 0.5pt), samples: 50) },
/// )
/// ```
///
/// -> content
#let anchored-points(
  /// Per point: a bare (x, y) / anchor string, or a pair (origine, label-text) — label-text may be none.
  /// -> array
  ..points,
  
  /// Shared marker options (marker-* or cetz mark:* vocabulary), see anchored-point ; none = no markers at all.
  /// -> dictionary | none
  marker: (marker-symbol: "o", marker-size: 0.06, marker-fill: auto, marker-stroke: none, marker-angle: 0deg),
  
  /// Shared label options (label-text here is overridden per point, label-styles is spread into text()), see anchored-point ; none = no labels at all.
  /// -> dictionary | none
  label: (
    label-text: "",
    label-distance: 8pt,
    label-anchor: "center",
    label-position: 0deg,
    label-rotate: 0deg,
    label-styles: (:),
  ),
) = {
  for item in points.pos() {
    // Detect the type of each item:
    //  - bare coordinate (x, y) or bare anchor "plot.<name>" → no label;
    //  - otherwise pair (origine, label-text), label-text may be none.
    let (origine, txt) = if _is-bare-coord(item) or type(item) == str {
      (item, none)
    } else {
      (item.at(0), item.at(1))
    }
    let this-label = if label == none or txt == none {
      none
    } else {
      label + (label-text: txt)
    }
    anchored-point(origine, marker: marker, label: this-label)
  }
}

/// Derivative arrow with a FIXED size (cm), with the slope corrected to
/// stay geometrically consistent in an anisotropic frame. To be called
/// OUTSIDE plot.plot(...). Automatically retrieves sx, sy (computed by
/// newFig): nothing to pass again.
///
/// - origine (str, array): anchor "plot.<name>", or (x, y) in data units
/// - slope (float, int): REAL slope in data units (e.g. spline-dy(...))
/// - fill (color): arrow color
/// - length (float, int): FIXED length of the arrow, in cm
/// - stroke (stroke): stroke thickness/color
/// - mark-scale (float, int): arrowhead size
///
/// ```example
/// #newFig(
///   extra: (sx, sy) => {
///     import draw: *
///     // tangent at point (1, f(1)) with slope 2
///     anchored-derivative-arrow((1, 1), 2, fill: red, stroke: red + 1.2pt)
///   },
///   { plot.add(domain: (-2, 2), x => calc.pow(x, 2), style: (stroke: blue + 0.5pt), samples: 50) },
/// )
/// ```
///
/// -> content
#let anchored-derivative-arrow(
  /// Anchor "plot.<name>", or (x, y) in data units.
  /// -> string | array
  origine,
  
  /// REAL slope in data units (e.g. spline-dy(...)).
  /// -> float | int
  slope,
  
  /// Arrow color.
  /// -> color
  fill: black,
  
  /// FIXED length of the arrow, in cm.
  /// -> float | int
  length: 1,
  
  /// Stroke thickness/color.
  /// -> stroke
  stroke: 1pt,
  
  /// Arrowhead size.
  /// -> float | int
  mark-scale: .6,
) = {
  import draw: get-ctx, line
  let mark = (start: "stealth", end: "stealth", scale: mark-scale, fill: fill)
  get-ctx(ctx => {
    let (sx, sy) = ctx.at("helper-scale", default: (1, 1))
    let (ctx, pos) = resolve-origine(ctx, origine, sx, sy)
    let (x, y, ..) = pos // x/y of the origin, in canvas units
    
    // slope "adjusted" to the real drawing scale
    let screen-slope = slope * (sy / sx)
    let norm = calc.sqrt(1 + screen-slope * screen-slope)
    let dx = (length / 2) / norm
    let dy = dx * screen-slope
    
    line((x - dx, y - dy), (x + dx, y + dy), stroke: stroke, mark: mark)
  })
}

/// Draws the two basis vectors of (O ; vec(i), vec(j)), with a length of
/// `length` DATA units (default 1 = unit vector). Shaft and arrowhead are
/// drawn directly in the canvas frame: no distortion from the frame
/// anisotropy. The two segments form ONE continuous polyline
/// (i) -- (O) -- (j): no "step" at the origin. To be called OUTSIDE
/// plot.plot(...). Automatically retrieves sx, sy (computed by newFig):
/// nothing to pass again.
///
/// - origine (str, array): anchor "plot.<name>" ("plot.O" by default), or (x, y) in data units
/// - x-length (float, int): length of vec(i), in data units
/// - y-length (float, int): length of vec(j), in data units
/// - fill (color): color of the arrows and labels
/// - stroke (auto, stroke): stroke (auto = fill + 1pt)
/// - mark-scale (float, int): arrowhead size
/// -> content
#let anchored-basis-vectors(
  /// Anchor "plot.<name>", or (x, y) in data units; `auto` = "<plot-name>.O" (default plot name "plot").
  /// -> string | array
  origine: auto,
  
  /// Length of vec(i), in data units.
  /// -> float | int
  x-length: 1,
  
  /// Length of vec(j), in data units.
  /// -> float | int
  y-length: 1,
  
  /// Color of the arrows and labels.
  /// -> color
  fill: red,
  
  /// Stroke (auto = fill + 1pt).
  /// -> auto | stroke
  stroke: auto,
  
  /// Arrowhead size.
  /// -> float | int
  mark-scale: .5,
) = {
  import draw: content, get-ctx, line
  
  let stroke = if stroke == auto { fill + 1pt } else { stroke }
  let mark = (start: "stealth", end: "stealth", scale: mark-scale, fill: fill)
  
  get-ctx(ctx => {
    let (sx, sy) = ctx.at("helper-scale", default: (1, 1))
    let plot-name = ctx.at("plot-name", default: "plot")
    let origine = if origine == auto { plot-name + ".O" } else { origine }
    let (ctx, pos) = resolve-origine(ctx, origine, sx, sy)
    let (x, y, ..) = pos
    
    // 1 data unit = sx cm in x, sy cm in y.
    // A single continuous polyline (i) -- (O) -- (j), no step at O.
    line(
      (x + x-length * sx, y),
      (x, y),
      (x, y + y-length * sy),
      stroke: stroke,
      mark: mark,
    )
    
    // vec(i) south of the tip of i ; vec(j) west of the tip of j
    content(
      (x + x-length * sx, y),
      anchor: "north",
      padding: 0.15,
      text(fill: fill, size: 0.7em)[$arrow(i)$],
    )
    content(
      (x, y + y-length * sy),
      anchor: "east",
      padding: 0.15,
      text(fill: fill, size: 0.7em)[$arrow(j)$],
    )
  })
}

/// Extra styles (axis arrowheads), to merge with those of setAxes() via
/// `set-style(axes: axes + extraStyles)`.
///
/// - x (dictionary): style of the arrowhead of the x-axis
/// - y (dictionary): style of the arrowhead of the y-axis
/// -> dictionary
#let setExtraStyles(
  /// Style of the arrowhead of the x-axis.
  /// -> dictionary
  x: (mark: (end: "stealth", fill: black)),
  
  /// Style of the arrowhead of the y-axis.
  /// -> dictionary
  y: (mark: (end: "stealth", fill: black)),
) = (
  x: x,
  y: y,
)

/// Axis style dictionary, to pass to `set-style(axes: ...)` (via
/// `newFig(axes: ...)`).
///
/// - grid (stroke): main grid style
/// - minor-grid (stroke): minor grid style
/// - shared-zero (content): label shown at the common origin of both axes
/// - padding (length): offset beyond the axes
/// - overshoot (length): overshoot of the axis arrowheads
/// - tick-stroke (stroke): color/thickness of major ticks
/// - tick-length (float, int): length of major ticks
/// - tick-minor-stroke (stroke): color/thickness of minor ticks
/// - tick-minor-length (float, int): length of minor ticks
/// -> dictionary
#let setAxes(
  /// Main grid style.
  /// -> stroke
  grid: (stroke: gray + 0.4pt),
  
  /// Minor grid style.
  /// -> stroke
  minor-grid: (stroke: gray.lighten(60%) + 0.2pt),
  
  /// Label shown at the common origin of both axes.
  /// -> content
  shared-zero: text(size: 8pt, fill: red)[$O$],
  
  /// Offset beyond the axes.
  /// -> length
  padding: 0pt,
  
  /// Overshoot of the axis arrowheads.
  /// -> length
  overshoot: 8pt,
  
  /// Color/thickness of major ticks.
  /// -> stroke
  tick-stroke: black + 0.5pt,
  
  /// Length of major ticks.
  /// -> float | int
  tick-length: 0.1,
  
  /// Color/thickness of minor ticks.
  /// -> stroke
  tick-minor-stroke: gray + 0.3pt,
  
  /// Length of minor ticks.
  /// -> float | int
  tick-minor-length: 0,
) = (
  grid: grid,
  minor-grid: minor-grid,
  shared-zero: shared-zero,
  padding: padding,
  overshoot: overshoot,
  tick: (stroke: tick-stroke, length: tick-length, minor-stroke: tick-minor-stroke, minor-length: tick-minor-length),
)

/// Alias for compatibility with the old name.
/// -> function
#let mesaxes = setAxes

/// Default options of `plot.plot(...)`, as a dictionary.
/// Can be called as is ("generic" values), but `newFig` calls it while
/// injecting ITS OWN size/x-min/x-max/y-min/y-max (and x-format/y-format
/// depending on `repere:`), so that you never have to repeat these values
/// in two places. Any extra parameter not explicitly anticipated
/// (e.g. y-equal:) passes through `..more` and is forwarded to plot.plot.
///
/// - size (array): physical size of the plot (width, height), in cm
/// - x-min (float, int): lower bound of the x domain
/// - x-max (float, int): upper bound of the x domain
/// - y-min (float, int): lower bound of the y domain
/// - y-max (float, int): upper bound of the y domain
/// - name (str): name of the plot (for "plot.<name>" in plot.add-anchor)
/// - x-tick-step (float, int): step between two major graduations on x
/// - x-minor-tick-step (float, int): step between two minor graduations on x
/// - y-tick-step (float, int): step between two major graduations on y
/// - y-minor-tick-step (float, int): step between two minor graduations on y
/// - axis-style (str): axis style ("school-book", etc.)
/// - x-format (function): formatting of the values shown on the x-axis
/// - y-format (function): formatting of the values shown on the y-axis
/// - x-label (content): label of the x-axis
/// - y-label (content): label of the y-axis
/// - x-grid (str, none): vertical grid ("major", "minor", "both" or none)
/// - y-grid (str, none): horizontal grid ("major", "minor", "both" or none)
/// -> dictionary
#let setPlot(
  /// Physical size of the plot (width, height), in cm.
  /// -> array
  size: (12, 6.5),
  
  /// Lower bound of the x domain.
  /// -> float | int
  x-min: -3,
  
  /// Upper bound of the x domain.
  /// -> float | int
  x-max: 3,
  
  /// Lower bound of the y domain.
  /// -> float | int
  y-min: -3.5,
  
  /// Upper bound of the y domain.
  /// -> float | int
  y-max: 3,
  
  /// Name of the plot (for "plot.<name>" in plot.add-anchor).
  /// -> string
  name: "plot",
  
  /// Step between two major graduations on x.
  /// -> float | int
  x-tick-step: 1,
  
  /// Step between two minor graduations on x.
  /// -> float | int
  x-minor-tick-step: 0.1,
  
  /// Step between two major graduations on y.
  /// -> float | int
  y-tick-step: 1,
  
  /// Step between two minor graduations on y.
  /// -> float | int
  y-minor-tick-step: 0.1,
  
  /// Axis style ("school-book", etc.).
  /// -> string
  axis-style: "school-book",
  
  /// Formatting of the values shown on the x-axis.
  /// -> function
  x-format: v => if v != 1 { text(size: 8pt)[#v] },
  
  /// Formatting of the values shown on the y-axis.
  /// -> function
  y-format: v => if v != 1 { text(size: 8pt)[#v] },
  
  /// Label of the x-axis.
  /// -> content
  x-label: text(size: 0.8em)[$x$],
  
  /// Label of the y-axis.
  /// -> content
  y-label: text(size: 0.8em)[$y$],
  
  /// Vertical grid ("major", "minor", "both" or none).
  /// -> string | none
  x-grid: "both",
  
  /// Horizontal grid ("major", "minor", "both" or none).
  /// -> string | none
  y-grid: "both",
  
  /// Extra parameters forwarded as is to plot.plot.
  /// -> any
  ..more,
) = (
  size: size,
  name: name,
  x-min: x-min,
  x-max: x-max,
  y-min: y-min,
  y-max: y-max,
  x-tick-step: x-tick-step,
  x-minor-tick-step: x-minor-tick-step,
  y-tick-step: y-tick-step,
  y-minor-tick-step: y-minor-tick-step,
  axis-style: axis-style,
  x-format: x-format,
  y-format: y-format,
  x-label: x-label,
  y-label: y-label,
  x-grid: x-grid,
  y-grid: y-grid,
  ..more.named(),
)

/// Wraps `plot.plot(...)`: takes a ready-made options dictionary
/// (typically produced by `setPlot(...)`) and the `body` that goes INSIDE
/// the plot (your `plot.add(...)`, `plot.add-anchor(...)`,
/// `plot.annotate(...)`). Automatically adds `plot.add-anchor("O", (0, 0))`:
/// you no longer need to do it yourself, the "plot.O" anchor is always
/// available for `anchored-basis-vectors(...)` etc.
///
/// - options (dictionary): options of plot.plot, typically produced by setPlot(...)
/// - body (content): content placed in plot.plot (plot.add, plot.add-anchor, plot.annotate...)
/// -> content
#let monplot(
  /// Options of plot.plot, typically produced by setPlot(...).
  /// -> dictionary
  options,
  
  /// Content placed in plot.plot (plot.add, plot.add-anchor, plot.annotate...).
  /// -> content
  body,
) = {
  plot.plot(
    ..options,
    {
      plot.add-anchor("O", (0, 0))
      body
    },
  )
}

/// "All-in-one" function to build a figure: computes sx, sy automatically
/// (no more need to call plot-scale yourself), opens the canvas and
/// applies the axis style, calls monplot(...) with the merged options of
/// setPlot(...), and adds, if provided, the content OUTSIDE the plot but
/// INSIDE the canvas (access to sx, sy). If repere: true (default),
/// automatically adds the frame (O ; i, j) AND hides the "1" graduation
/// on the axes (since it duplicates the i, j arrows); if repere: false,
/// no arrows, and the "1" graduation becomes visible again like the
/// others. An x-format/y-format given in `plot:` takes precedence over
/// the one controlled by `repere:` — but do not set both at once for the
/// same key (x-format or y-format), Typst rejects a duplicate named
/// argument.
/// - size (array): physical dimensions of the plot (width, height), in cm
/// - x-min (float | int): lower bound of the x domain
/// - x-max (float | int): upper bound of the x domain
/// - y-min (float | int): lower bound of the y domain
/// - y-max (float | int): upper bound of the y domain
/// - axes (dictionary): axis style, see setAxes()
/// - extraStyles (dictionary): styles of the basis arrows (i, j), see setExtraStyles()
/// - repere (bool): shows/hides (O ; vec(i), vec(j)) and the "1" graduation (see description)
/// - plot (dictionary): override of the setPlot() options (e.g. (x-tick-step: 0.5))
/// - extra (function, none): (sx, sy) => content, drawn after the plot, inside the canvas
/// - body (content): content placed INSIDE plot.plot (plot.add, plot.add-anchor, plot.annotate...)
/// ```
/// #newFig(
///   // content INSIDE plot.plot
///   {
///     plot.add(domain: (-3, 3), x => x * 0, style: (stroke: gray + 0.5pt), samples: 2)
///     plot.add-anchor("p0", (-2, -1))
///   },
///   // content OUTSIDE the plot, inside the canvas (access to sx, sy)
///   extra: (sx, sy) => {
///     import draw: *
///     anchored-point("plot.p0", marker: (marker-fill: red), label: (label-text: "A", label-position: 90deg))
///     anchored-basis-vectors(fill: red)
///   },
/// )
/// ```
/// -> content
#let newFig(
  /// Physical dimensions of the plot (width, height), in cm.
  /// -> array
  size: (12.0, 6.5),
  
  /// Lower bound of the x domain.
  /// -> float|int
  x-min: -3.0,
  
  /// Upper bound of the x domain.
  /// -> float|int
  x-max: 3.0,
  
  /// Lower bound of the y domain.
  /// -> float|int
  y-min: -3.5,
  
  /// Upper bound of the y domain.
  /// -> float|int
  y-max: 3.0,
  
  /// Axis style, see setAxes().
  /// -> dictionary
  axes: setAxes(),
  
  /// Styles of the basis arrows (i, j), see setExtraStyles().
  /// -> dictionary
  extraStyles: setExtraStyles(),
  
  /// Shows/hides (O ; vec(i), vec(j)) and the "1" graduation ; if false, the origin is labeled "0" (without the red of O).
  /// -> bool
  repere: true,
  
  /// Override of the setPlot() options (e.g. (x-tick-step: 0.5)).
  /// -> dictionary
  plot: (:),
  
  /// (sx, sy) => content, drawn after the plot, inside the canvas.
  /// -> function | none
  extra: none,
  
  /// Content placed INSIDE plot.plot (plot.add, plot.add-anchor, plot.annotate...).
  /// -> content
  body,
) = {
  let (sx, sy) = plot-scale(size, (x-min, x-max), (y-min, y-max))
  
  // With repere: true, the value "1" is hidden (the i, j arrows already
  // show it) ; with repere: false, everything is shown, "1" included.
  let tick-format = if repere {
    v => if v != 1 { text(size: 8pt)[#v] }
  } else {
    v => text(size: 8pt)[#v]
  }
  
  // With repere: false, the origin is labeled "0" (without the red of O).
  let axes = if repere {
    axes
  } else {
    axes + (shared-zero: text(size: 8pt)[$0$])
  }
  
  let plot-options = setPlot(
    size: size,
    x-min: x-min,
    x-max: x-max,
    y-min: y-min,
    y-max: y-max,
    x-format: tick-format,
    y-format: tick-format,
    ..plot,
  )
  
  canvas({
    import draw: *
    
    // Makes sx, sy and plot-name retrievable via get-ctx (used by
    // anchored-basis-vectors, anchored-point...) without passing them again.
    set-ctx(ctx => ctx + (helper-scale: (sx, sy), plot-name: plot-options.name))
    
    set-style(axes: axes + extraStyles)
    
    monplot(plot-options, body)
    
    if extra != none {
      extra(sx, sy)
    }
    
    if repere {
      anchored-basis-vectors(fill: red)
    }
  })
}
