#import "@preview/tidy:0.4.3"
#import "@preview/cetz-plot:0.1.4": plot
#import "@preview/cetz:0.5.2": canvas, draw
#import "@local/ctz-plot-helper:0.1.0" : newFig, setAxes, setExtraStyles, anchored-point-marker, anchored-derivative-arrow, anchored-lines

// Parse the module containing your doc-comments
#let docs = tidy.parse-module(
  read("../src/ctz-plot-helper.typ"),
  name: "ctz-plot-helper — manual",
  preamble: "#import \"@local/ctz-plot-helper:0.1.0\": *\n",
)

// Render the documentation using a predefined style

#align(center)[
  #text(size: 24pt, weight: "bold")[ctz-plot Helper]

  #v(.5em)

  #text(
    size: 16pt,
    weight: "bold",
  )[-- Quick reference --]

  #v(.5em)



#newFig(
  size: (8, 6),
  x-min: -3.0,
  x-max: 3.0,
  y-min: -3.5,
  y-max: 2.0,
  {
    plot.add(domain: (-3, 3), x => .5 * x * x - 3, style: (stroke: blue + 1.2pt), samples: 100)
  },
  extra: (sx, sy) => {
    let x1 = -1
    let x2 = 2
    let y(x) = .5 * x * x - 3
    let yp(x) = x

    anchored-lines((0, y(x1)), (x1, y(x1)), (x1, 0), stroke: (thickness: 0.75pt, dash: "dashed", paint: red))
    anchored-point-marker(
      (x1, y(x1)),
      marker: (marker-fill: red, marker-size: 0.04),
      label: (
        label-text: text(size: 0.9em, fill: red, $A$),
        label-position: -135deg,
      ),
    )
    anchored-derivative-arrow((x1, y(x1)), yp(x1), length: 2, fill: red, stroke: red + 1.2pt)

    anchored-lines((0, y(x2)), (x2, y(x2)), (x2, 0), stroke: (thickness: 0.75pt, dash: "dashed", paint: purple))
    anchored-point-marker(
      (x2, y(x2)),
      marker: (marker-symbol: "+", marker-stroke: purple + .5pt),
      label: (
        label-text: text(size: 0.9em, fill: purple, $B$),
        label-distance: 7pt,
        label-position: -45deg,
      ),
    )
    anchored-derivative-arrow((x2, y(x2)), yp(x2), length: 2, fill: purple, stroke: purple + 0.8pt)
  },
)

]

#v(.5em)

#tidy.show-module(docs, style: tidy.styles.default, show-module-name: false)
