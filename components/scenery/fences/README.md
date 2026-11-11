# Painterly yard fence

Instance `painterly_yard_fence.tscn` with its origin centered on the ground. The fence runs along **local X**, its front is **local +Z**, and the mesh occupies a thin vertical XY plane. Rotate around Y for another side of a yard. Place separate spans on either side of an entrance to leave an open gate; each span's collider stops at its exact length.

The pale, warm metal uses broad toon tones, thin geometric diamond wires, simple round posts, and soft post caps. It is designed as a quiet domestic boundary rather than an industrial barrier.

| Inspector control | Purpose |
| --- | --- |
| Length / Height | Exact span and panel height |
| Post Spacing | Maximum distance between posts; bays divide evenly |
| Diamond Size | Scale of the clipped diagonal mesh |
| Wire Radius / Post Radius | Readability and silhouette weight |
| Wire Color / Post Color | Painted metal colors |
| Collision Enabled | Optional thin rectangular solid span |

All rods, posts, caps, and rails are merged into **one opaque surface / draw call**. There are no alpha cards, textures, per-wire nodes, or shadow-map passes. The generated nodes stay internal and do not serialize into authored memories. The default 4 m × 0.95 m span is below 5,000 triangles; longer spans and smaller diamonds increase the count.

The mesh is deterministic. Editing dimensions rebuilds the geometry and collider together. The collider intentionally represents the solid fence span, not every wire diamond, so players cannot snag on the mesh. Place the span endpoints outside an intended passage and keep at least 2.2 m clear for two explorers.

Run `godot --headless --path . --script res://tests/yard_fence.gd` for geometry budget, bounds, determinism, dimension edits, and collision checks.
