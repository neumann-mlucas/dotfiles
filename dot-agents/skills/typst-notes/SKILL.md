---
name: typst-notes
description: House style for PDF notes and reports, built with Typst. Use when the user asks for a PDF, a write-up, a report, notes, a handout, or "make this a document" about a topic under discussion. Provides the template (notes.typ), the plot theme (plots.typ), typography and chart rules, and the compile-render-inspect loop. For Typst syntax and API questions, load the `typst` skill.
---

# Typst notes

Every PDF uses one template, so all documents look the same. The `typst` skill covers syntax. This skill covers look, structure, and verification.

## Workflow

1. Choose the output folder. If the user names no path, use `~/Documents/notes/<YYYY-MM-DD>-<slug>/`.
2. Copy the template files into that folder. Typst cannot import files outside the project root.
   ```bash
   cp ~/.agents/skills/typst-notes/assets/notes.typ "$dir/"
   cp ~/.agents/skills/typst-notes/assets/plots.typ "$dir/"   # only if the document has plots
   ```
3. Write `main.typ`. Start from `assets/example.typ`, which uses every feature once.
4. Compile and render each page to PNG:
   ```bash
   typst compile main.typ main.pdf
   pdftoppm -png -r 80 main.pdf /tmp/page
   ```
5. Read every PNG. Fix the problems in the checklist below, then repeat step 4.
6. Report the PDF path and the page count to the user.

## Document skeleton

```typst
#import "notes.typ": *
#show: notes.with(
  title: "Title in sentence case",
  subtitle: none,          // optional one-line framing
  author: "Lucas Neumann",
  abstract: [2–3 sentences: question, answer, why it matters.],
  toc: false,              // true when the document has more than ~6 pages
)
```

Helpers from `notes.typ`:
- `#note(title: "Key point")[...]`: aside for one takeaway, warning, or definition. Max one per page.
- `palette`: Okabe–Ito colors, for non-lilaq graphics.

## Writing rules

- Lead with the answer. The abstract and the first paragraph state the conclusion, not the plan.
- Use 3 heading levels at most. Never skip a level. One idea per section.
- Prose carries the argument. Use lists only for 3+ parallel items or steps.
- Bold is for the `note` title and table headers only. For emphasis, use _italic_ sparingly. Never underline.
- Every table and figure gets a `<label>`, a caption that states the finding, and a reference in the text (`@fig:x`).
- Cite sources with `#link("url")[text]` or a `#bibliography`. Never use a bare URL in prose.
- Use real typography: curly quotes come from `lang`, an en dash for ranges (`10–20`), and `...` becomes an ellipsis.

## Tables

The template draws booktabs rules: top, under the header, bottom. It never draws vertical lines.
- Left-align text columns. The template right-aligns all other columns, so numbers line up.
- Use the same decimals in a column. Put units in the header (`Latency (ms)`), not in the cells.
- Wrap each table in `figure(table(...), caption: [...])`. The caption goes on top automatically.
- If a table has more than ~8 columns, split it or transpose it.

## Plots

Use lilaq through `plots.typ`. It renders vector graphics in the document font.

```typst
#import "plots.typ": lq, plot-style
#show: plot-style

#figure(
  lq.diagram(
    xlabel: [Requests per second], ylabel: [Latency (ms)],
    lq.plot(xs, ys, label: [Pooled], mark: "o"),
    lq.bar(xs, ys),   // bar chart
  ),
  caption: [State the finding, not the chart type.],
  alt: "One sentence describing the data trend.",
) <fig:latency>
```

- `plot-style` applies the Tufte defaults: no grid, no top/right spines, no minor ticks, no axis exponent, a legend outside the data, and an Okabe–Ito color cycle.
- Show one message per chart. Prefer small multiples (a `grid` of small diagrams) over one crowded chart.
- Use a line for trends, a bar for comparisons of categories, and a scatter for relations. Bars start at zero.
- Do not use pie charts, 3D, dual y-axes, or decorative fills.
- Label axes with quantity and unit. With 1–2 series, label lines directly (`lq.place`) and drop the legend.
- Load data with `csv("data.csv")` or `json("data.json")`. Convert to arrays of numbers before passing to lilaq: `rows.map(r => float(r.at(1)))`.
- If a plot needs statistics that lilaq lacks, generate an SVG with matplotlib. Use the same palette (`#0072B2 #E69F00 #009E73 #D55E00 #CC79A7`), turn the grid off, remove the top/right spines, and use `font.family: serif`. Then use `#figure(image("plot.svg", alt: "..."), caption: [...])`.

## Code and math

- Use fenced blocks with a language tag. In Typst 0.15, a tag like `c++` needs `#raw(..., lang: "c++")`.
- Keep code blocks under ~25 lines. Show the relevant part and link the full source.
- Use display math (`$ x $` with spaces) for any formula the reader must study. Use inline math for symbols only.

## Visual checklist (step 5)

- No page is more than a third empty, except the last one.
- No heading sits alone at the bottom of a page.
- Every figure and table is readable at 100% zoom. Tick labels do not overlap.
- No text, table, or code line runs into the margin. Check for overfull lines in tables and code.
- Numbers in tables line up on the right.
- Typst prints no warnings. Fix each warning; do not ignore it.

## Template design (why the numbers)

- Body: Libertinus Serif 11pt, justified, with hyphenation from `lang`. Line spacing is about 130% (Butterick: 120–145%).
- Measure: A4 with 3.2cm side margins gives a 14.6cm text width, about 75 characters per line (Butterick: 45–90).
- Paragraphs: 0.8em space between them and no first-line indent. Use one or the other, never both.
- Color: near-black text, one accent (`#1f4e9c`, 8.5:1 contrast) for links and notes. Plot colors carry data only.
- The PDF is tagged for accessibility by default. Give every image and plot an `alt`.
