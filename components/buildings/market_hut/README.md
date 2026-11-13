# Painterly market hut

Instance `painterly_market_hut.tscn` at ground level, front along local +Z. **Goods** selects Bakery, Handcrafted Gifts, or Warm Drinks. **Wood Color**, **Trim Color**, and **Paint Seed** control the matte finish. Native transforms position, rotate, or uniformly scale it.

Each hut combines an open counter, a vendor made from the existing crowd meshes, paneled wood, a wreath/garland, warm bulbs, and snow-capped pitched roof in one static mesh/material. A single box blocks the hut and counter; the roof is decorative. Generated children remain internal and rebuild only after authoring changes.

It exposes `excludes_ground_point(world_point)` and `ground_exclusion_changed` for existing snow/groundcover exclusions. Include it in a nearby snow component's Ground Exclusions, and place an existing light wash at the counter to suggest warmth on the snow. Lights use the shared material's restrained emissive kind; no real-time lamps or shadow maps are allocated.

See the [Christmas market memory](../../../scenes/memories/christmas_market/README.md) for six configured examples.
