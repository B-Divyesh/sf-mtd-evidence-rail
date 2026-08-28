# Visual thesis — the paper moon evidence railway

## Direction and rationale

MTD Evidence Rail uses **surreal editorial scenery**: a midnight railway carries
small paper records across a quarterly landscape towards a lit archive. The
scene turns an abstract compliance task into a visible route with a destination.
It is calm, specific to evidence gathering, and deliberately unlike accounting
software dashboards. The interface borrows the scene's paper labels, punched
ticket corners, thin rail lines, and warm pools of light.

## Palette

| Token | Hex | Use |
| --- | --- | --- |
| Ink | `#102520` | Main text and deep surfaces |
| Night | `#092a32` | Scene and dark treatment |
| Paper | `#f4efe2` | Main background |
| Chalk | `#fffaf0` | Raised surfaces |
| Moss | `#245c4f` | Secondary actions |
| Signal | `#e35f3d` | Primary action and focus |
| Brass | `#e8bf62` | Evidence links and highlights |
| Sage | `#c8d8bf` | Success |
| Fog | `#66746e` | Muted text (on light only) |
| Danger | `#a3362d` | Errors |

All text and control combinations target WCAG AA. This is an explicitly warm,
light utility treatment with a dark illustrated masthead, rather than a user
theme switch that might hide document-state signals.

## Type and spacing

Display type uses the locally served `Fraunces` variable serif for editorial
headings. Body and tabular data use the locally served `Atkinson Hyperlegible`
family. If either file fails, Georgia and system sans-serif preserve hierarchy.
The type scale is 16, 18, 23, 32, 48, and 64 px. Spacing follows an 8 px base,
with 4 px used only inside compact status labels. Reading measure stays under
70 characters. Data uses tabular figures.

## Shape and interaction grammar

Sections alternate between open paper and ruled ledgers. Independent records
have clipped ticket corners; grouped controls are not put in decorative cards.
The current quarter is a physical rail with four stations. Linked evidence is
a brass punched circle; missing evidence is an outlined stop. Primary buttons
are signal-red with a small rightward rail mark. Focus uses a 3 px brass ring
with a dark offset edge. Touch targets are at least 44 px.

## Motion

On first view, the paper train advances once along the rail over 700 ms. New
records enter from the point that created them in 180 ms. Nothing loops. With
`prefers-reduced-motion: reduce`, transforms and smooth scrolling are removed;
state changes use an instant border and text update.

## Asset plan and provenance

Hero: a wide surreal editorial collage of a tiny night train carrying receipts
and invoice papers through four seasonal hills towards a cabinet-shaped moon.
No text appears inside the image. A hand-authored SVG rail motif supports empty
states and the favicon. The social image is composed from the hero art and local
HTML/CSS without third-party assets.

Art prompt (source of truth):

> Surreal editorial paper-cut landscape at blue-green midnight, a miniature
> brass railway crossing four gentle seasonal hills, a tiny train carrying
> blank cream receipts and invoice papers, heading toward a glowing archive
> cabinet shaped like a crescent moon, British countryside hints without flags,
> tactile cut paper, soft gouache grain, warm coral signal lamps, restrained
> cream moss brass coral palette, wide cinematic composition, ample quiet dark
> sky, no people, no text, no numbers, no logos, no watermark, no brands.

Generation: OpenAI image model through the Param Factory Azure image script,
2026-08-28. Generated assets are original to this product. Source PNG and prompt
sidecar are retained in `assets/src/`; WebP output is optimised for delivery.

## Plain-word terminology

- A financial line is a **transaction**.
- A receipt, invoice PDF, or note is **evidence**.
- A three-month MTD window is a **quarter**.
- The exported accountant file is an **evidence pack**.
- The attention list is **missing evidence**.

