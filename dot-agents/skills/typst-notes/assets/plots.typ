// Plot theme for lilaq, matching notes.typ. Import only when a document has plots:
//   #import "plots.typ": lq, plot-style
//   #show: plot-style
// Style: no grid, no top/right spines, no minor ticks, no axis exponent,
// legend outside the data area, colorblind-safe Okabe–Ito cycle.
#import "@preview/lilaq:0.6.0" as lq

#let plot-style = it => {
  show: lq.set-diagram(
    width: 10cm,
    height: 5.5cm,
    cycle: lq.color.map.okabe-ito,
    xaxis: (subticks: none, mirror: false, exponent: 0),
    yaxis: (subticks: none, mirror: false, exponent: 0),
  )
  show: lq.set-grid(stroke: none)
  show: lq.set-tick(inset: 0pt, outset: 3pt)
  show: lq.set-legend(position: top + left, dx: 100%, stroke: none, fill: none)
  it
}
