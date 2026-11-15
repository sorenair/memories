# Painterly street

Instance `painterly_street.tscn` for continuous matte asphalt along local **Z**.
**Length** (2–200 m), **Width**, **Asphalt Color** and **Street Seed** set the road;
**End Fade** and **Edge Softness** dissolve its painted margins into the void.
Changes preview in the editor. The surface has broad, quiet pigment variation
without slab joints, repeating tiles or time-driven animation.

One plane, one opaque shader and an optional shallow continuous box collider.
Origin is ground center; the walking top is 0.0125 m high, matching existing
paving. Generated nodes stay internal. `excludes_ground_point(world_point)` and
`ground_exclusion_changed` integrate with planting and follow position/rotation.
Use separate paving for sidewalks and approaches.

The shared MemoryPlatform still defines the memory's safe outer boundary. Extend
its outline when lengthening a street beyond the current remembered ground.
`tests/street.gd` checks edited dimensions, transformed exclusions and actual
physics support. The first use is [Mifflin](../../../scenes/memories/mifflin/README.md).
