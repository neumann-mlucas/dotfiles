// House template for notes and reports. Typst 0.15+.
// Usage:
//   #import "notes.typ": *
//   #show: notes.with(title: "Title", author: "Name", abstract: [...])

#let ink = luma(12%)
#let muted = luma(40%)
#let rule = luma(70%)
#let accent = rgb("#1f4e9c") // 8.5:1 contrast on white

// Okabe–Ito: colorblind-safe categorical palette for plots.
#let palette = (
  rgb("#0072B2"), // blue
  rgb("#E69F00"), // orange
  rgb("#009E73"), // green
  rgb("#D55E00"), // vermillion
  rgb("#CC79A7"), // purple
  rgb("#56B4E9"), // sky
  rgb("#F0E442"), // yellow: lines only, too light for text
  rgb("#000000"),
)

/// Aside box for warnings, definitions, key takeaways.
#let note(title: none, body) = block(
  width: 100%,
  inset: (x: 10pt, y: 8pt),
  fill: accent.lighten(93%),
  stroke: (left: 2pt + accent),
  breakable: true,
)[
  #if title != none [#text(weight: "bold", fill: accent, title) \ ]
  #body
]

#let notes(
  title: none,
  subtitle: none,
  author: none,
  date: datetime.today(),
  abstract: none,
  toc: false,
  lang: "en",
  body,
) = {
  set document(
    title: title,
    author: if author == none { () } else { author },
    date: date,
  )
  set text(font: "Libertinus Serif", size: 11pt, lang: lang, fill: ink)

  // ~14.6cm measure ≈ 75 characters per line at 11pt.
  set page(
    paper: "a4",
    margin: (x: 3.2cm, top: 2.8cm, bottom: 3cm),
    header: context if counter(page).get().first() > 1 {
      set text(size: 8.5pt, fill: muted)
      title
      h(1fr)
      if author != none { author }
    },
    footer: context align(center, text(size: 9pt, fill: muted, counter(page).display())),
  )
  set par(justify: true, spacing: 0.8em)

  // Headings: numbered, three levels max, same family, scale by size.
  set heading(numbering: "1.1")
  show heading: set text(fill: ink, weight: "bold")
  show heading: set block(above: 1.6em, below: 0.8em, sticky: true)
  show heading.where(level: 1): set text(size: 1.35em)
  show heading.where(level: 2): set text(size: 1.15em)
  show heading.where(level: 3): set text(size: 1em, style: "italic")

  // Code.
  show raw: set text(font: ("Fira Code", "DejaVu Sans Mono"))
  show raw.where(block: true): set text(size: 8.5pt)
  show raw.where(block: true): block.with(
    width: 100%,
    inset: 8pt,
    radius: 2pt,
    fill: luma(96.5%),
  )
  show raw.where(block: false): box.with(
    fill: luma(94%),
    inset: (x: 2.5pt),
    outset: (y: 2.5pt),
    radius: 1.5pt,
  )

  // Tables: booktabs rules, no vertical lines, bold header, caption on top.
  set table(
    stroke: (_, y) => if y == 0 { (top: 0.8pt + ink, bottom: 0.4pt + ink) },
    inset: (x: 6pt, y: 4.5pt),
    align: (x, _) => if x == 0 { left } else { right },
  )
  show table: t => box(stroke: (bottom: 0.8pt + ink), t)
  show table.cell.where(y: 0): set text(weight: "bold")
  show figure.where(kind: table): set figure.caption(position: top)

  // Figures and captions.
  set figure(gap: 0.8em)
  // Images and plots float to the nearest page top/bottom; no half-empty pages.
  show figure.where(kind: image): set figure(placement: auto)
  show figure: set block(above: 1.4em, below: 1.4em)
  show figure.caption: set text(size: 9pt)
  show figure.caption: it => {
    text(weight: "bold", it.supplement + " " + context it.counter.display(it.numbering) + it.separator)
    it.body
  }

  // Links and lists.
  show link: set text(fill: accent)
  set list(indent: 0.6em)
  set enum(indent: 0.6em)

  // Title block.
  if title != none {
    block(below: 0.6em, {
      set par(justify: false, leading: 0.4em)
      text(size: 1.7em, weight: "bold", std.title())
    })
  }
  if subtitle != none {
    block(below: 0.6em, text(size: 1.2em, fill: muted, subtitle))
  }
  {
    set text(size: 9.5pt, fill: muted)
    let meta = (author, if date != none { date.display("[day] [month repr:long] [year]") })
    meta.filter(x => x != none).join(" · ")
  }
  if abstract != none {
    v(0.8em)
    block(inset: (x: 1.2em), text(size: 9.5pt, abstract))
  }
  line(length: 100%, stroke: 0.4pt + rule)
  if toc {
    outline(depth: 2)
    line(length: 100%, stroke: 0.4pt + rule)
  }

  body
}
