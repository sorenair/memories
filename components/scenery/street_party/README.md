# Painterly street-party decor

`painterly_street_party_decor.tscn` is a small static prop using the shared painted
scenery batch, editor rebuilds and assembled recall.

- **Pennant Strand:** local-X cord with a shallow sag, alternating muted accent
  and cream triangles. Span and Height control its size; place the ends at porch
  posts or other scenery. The suspended decoration has no collision or animation.
- **Street Sign:** one post and rounded green nameplate. Height and Street Name
  control its appearance; the text is merged into the mesh. Front faces local +Z.
  Optional solid collision covers the pole.

One opaque surface per prop; no per-pennant or per-letter nodes. Recall Enabled,
optional Recall Anchor, collision and pigment use the shared framework. This is
world signage rather than UI. The first use is
[Mifflin Block Party](../../../scenes/memories/mifflin/README.md).
