# Painterly vineyard details

`painterly_vineyard_detail.tscn` adds two small static details using the shared
painted scenery builder, one opaque mesh and optional assembled recall.

- **Grape Trellis:** along local Z. Length sets the row; slender timber posts,
  three wires support the vine row. Collision covers posts only.
- **Timber Rail:** along local X. Length sets the span; posts and two broad rails
  provide a simple viewing-deck boundary. One continuous collider prevents snagging
  between posts and keeps the explorer behind the rail.

Wood Color, seed, pigment, collision and Recall Enabled preview in
the editor. Optional Recall Anchor lets a deck's rails resolve from its ramp
approach. Default trellises are 18 m long; shorten rails to the desired span.
Generated geometry stays internal, with no per-frame updates.

The timber deck itself reuses `PainterlyStage` with its **Timber Skirt** finish;
its existing ramp/deck collision and board geometry remain unchanged. See the
[Vineyard memory guide](../../../scenes/memories/vineyard/README.md) for composition,
field recall, routes and checks.

Instance `painterly_grapevine.tscn` at ground level with the vine arms along local Z.
Vine Height, Vine Length, Bunch Count, Grape Color, Foliage Palette and Prop Seed
control the result. Bunches hang from shoots on the woody arms. The leaf canopy
reuses bush wind and explorer response. Collision covers the trunk.
