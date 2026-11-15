# Painterly vineyard details

`painterly_vineyard_detail.tscn` adds two small static details using the shared
painted scenery builder, one opaque mesh and optional assembled recall.

- **Grape Trellis:** along local Z. Length sets the row; slender timber posts,
  three wires and small muted grape bunches suggest its structure. Reuse existing
  bushes for foliage, as in the vineyard memory. Collision covers posts only.
- **Timber Rail:** along local X. Length sets the span; posts and two broad rails
  provide a simple viewing-deck boundary. One continuous collider prevents snagging
  between posts and keeps the explorer behind the rail.

Wood Color, Grape Color, seed, pigment, collision and Recall Enabled preview in
the editor. Optional Recall Anchor lets a deck's rails resolve from its ramp
approach. Default trellises are 18 m long; shorten rails to the desired span.
Generated geometry stays internal, with no per-frame updates.

The timber deck itself reuses `PainterlyStage` with its **Timber Skirt** finish;
its existing ramp/deck collision and board geometry remain unchanged. See the
[Vineyard memory guide](../../../scenes/memories/vineyard/README.md) for composition,
field recall, routes and checks.
