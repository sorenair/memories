# Painterly leaf litter

Instance `painterly_leaf_litter.tscn` at a known surface height. Local XZ is the placement plane; rotate the node to lay leaves on a roof or another angled surface. There is no raycast projection, collision, or backing rectangle. Use separate patches for paving, stair treads, lawn edges, and roof planes.

The default 70 leaves are small, gently folded rounded leaf dabs matching the tree canopy and falling leaves in ochre, rust, and cream. Each leaf has a smooth 24-segment oval rim and is 24 triangles, making a default patch 1,680 triangles in **one opaque instanced draw call**. No alpha textures, particles, shadow maps, per-leaf nodes, or CPU animation.

- **Leaf Seed / Leaf Count:** deterministic scatter and exact count.
- **Footprint:** rectangular XZ region in meters.
- **Size Range:** world radius in meters, default 0.06–0.13; each leaf is roughly twice this width, with additional mild aspect variation.
- **Edge Bias:** 0 scatters uniformly; 1 concentrates leaves near the footprint edges. Narrow strips work well beside fences and paving.
- **Pigment colors:** edit the shared ochre/rust/cream mix without changing placement.
- **Flutter Strength / Speed:** optional tiny GPU edge lift. Zero strength is completely static and is the default.
- **Visibility Distance:** whole-patch culling distance.

Leaf shapes are slightly asymmetric, with the tree leaf’s narrower oval proportions, a softly raised center, and one curled rounded end. A broad 13% tonal transition makes the fold legible at gameplay scale. Continuous pigment washes replace triangle-by-triangle shading; there are no sharp lobes, stalks, or drawn veins.

Generated nodes stay internal; edits preview in the editor. The CPU geometry/layout helper permits deterministic headless tests without MultiMesh transform readback. Run `godot --headless --path . --script res://tests/leaf_litter.gd`.
