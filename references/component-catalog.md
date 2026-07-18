# Component Catalog and Selection Guide

Source framework: [stackblitz/bolt-slides](https://github.com/stackblitz/bolt-slides). Confirm component props against the checked-out source when the upstream pin changes.

## Core composition

```tsx
<Deck>
  <Cover
    nav="Cover"
    kicker="Context"
    title={<>A short <span className="accent-text">specific</span> title</>}
    subtitle="One sentence that establishes the promise."
    notes="Speaker-only guidance."
  />

  <Slide center nav="Thesis" notes="Pause before the reveal.">
    <h2 className="headline" style={{ marginInline: 'auto' }}>One idea.</h2>
    <Build at={1}><p className="lead">Its consequence.</p></Build>
  </Slide>
</Deck>
```

Each top-level child of `Deck` is one slide. `nav` labels the sidebar. `notes` appears in presenter mode.

## Workhorse layouts

| Component | Use when | Avoid when |
|---|---|---|
| `Cover` | Opening context, promise, title | Mid-deck content |
| `Slide` | Custom composition or statement | A purpose-built component already fits |
| `Split` | Text has a real balancing image, app, chart, or visual | The media side would be decorative filler |
| `Bento` | A small asymmetric set of related capabilities or proof points | The content is a sequential process |
| `StatGrid` | Two to four comparable sourced metrics | One metric clearly dominates |
| `Section` | A real chapter break in a longer deck | Short decks without chapters |

## Evidence and data components

### `BigNumber`

Use one sourced hero figure and cite it in `foot`.

```tsx
<BigNumber
  kicker="Delivery"
  value={<CountUp to={97.4} decimals={1} suffix="%" />}
  caption="of orders shipped on or before the committed date."
  foot="Source: ERP shipment export, trailing 12 months"
/>
```

Normally use no more than one per deck. Never invent a number to earn the layout.

### `Table`

Use for exact values. Keep to about five columns and seven rows. Include a source caption. Use `Pricing` for pricing tiers and `Comparison` for feature ticks.

### Charts

- `BarChart`: category comparison.
- `LineChart`: ordered trend.
- `DonutChart`: one part-to-whole ratio.
- `CountUp`: animation for a genuinely important number.

Charts are presentation components, not an analysis engine. Compute and verify data before embedding it. Preserve the source dataset alongside the project when practical.

## Narrative components

| Component | Entry condition |
|---|---|
| `Contrast` | Defensible before/after or current/future comparison |
| `Comparison` | Honest side-by-side criteria with evidence |
| `Steps` | Sequential process with a clear order |
| `Timeline` | Events or milestones where time/order matters |
| `Quote` | Real, attributable wording; never fabricate testimonials |
| `Agenda` | Formal or long deck where orientation helps |
| `Chat` | The product or workflow is genuinely conversational |

## Product and technical components

- `BrowserFrame`: show a real screenshot or build a faithful working mock. Fill the frame rather than placing a tiny card inside it.
- `CodeWindow`: short, readable code only; highlight the line being discussed.
- `Tabs`: optional detail viewers can explore without adding slides.
- `Accordion`: FAQ or drill-down content; do not hide the central argument in it.
- `Pricing`: two to four real tiers when pricing is part of the decision.
- `Team`: people whose identities and roles are material to credibility.

## Geographic and visual components

### `Globe`

Use only for real geography. Marker coordinates and labels must correspond to verified locations. Label a few hero points, not every point.

```tsx
<Globe
  title={<>Where the work <span className="accent-text">happens.</span></>}
  markers={[{ location: [29.4241, -98.4936], label: 'San Antonio' }]}
  stats={[{ value: '1', label: 'verified site' }]}
/>
```

### Image-capable patterns

- `Cover image`, `Section image`, and `Quote image`: full-bleed backgrounds under a scrim.
- `Bento` image tiles: editorial photo rhythm.
- `Split` media: product screenshots, diagrams, photography.
- `BrowserFrame`: screenshots or live-looking application views.

Use real licensed assets or generated assets with documented provenance. Do not embed text inside generated images.

## Motion and interaction

- `Build at={n}`: click-to-reveal; use for the punchline, stages, or controlled disclosure.
- `Reveal`: animate on slide entry without another click.
- `CountUp`, charts, and timelines: self-animate on view.
- `TiltCard` and `SpotlightCard`: pointer interaction; use sparingly.
- `Tabs` and `Accordion`: audience-controlled exploration.

One or two motion ideas per slide is usually enough. All custom animation must honor `prefers-reduced-motion`.

## Responsive composition rules

Use:

```css
font-size: clamp(2rem, 5vw, 4.5rem);
max-width: 70rem;
grid-template-columns: repeat(auto-fit, minmax(min(15rem, 100%), 1fr));
```

Or the framework's `.cols`, `.appmock`, and `.hide-narrow` utilities.

Avoid:

- Fixed content heights.
- `repeat(3, 1fr)` without a narrow-screen fallback.
- Long unbroken strings.
- Tiny screenshots floating in large empty areas.
- Left-aligned text-only blocks with no balancing visual.
- Content that needs vertical scrolling.

## Narrative rhythm

Vary the silhouette of adjacent slides:

1. Cover or full-bleed opener.
2. Centered thesis.
3. Split evidence or demonstration.
4. Data/proof block.
5. Process or comparison.
6. Focused close/CTA.

Do not alternate components mechanically. The story controls the layout.
