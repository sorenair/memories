# Painterly festive lights

`painterly_festive_lights.tscn` reuses the shared opaque painterly geometry/material batch. **Layout** selects Festoon or Tree Trimming.

- **Festoon** runs across local X. Set **Span**, **Height**, **Sag**, and optional **Poles**. Pole collision keeps walking routes honest; the suspended cord is decorative.
- **Tree Trimming** adds a tapered spiral of bulbs, muted red/brass ornaments, a star, and three parcels. Match **Height** and **Tree Radius** to the supporting tree. Parcels have one small collider.

Both layouts are static single-mesh props with a faint warm emission and no per-bulb nodes, scripts, shadow maps, or animated flashing. Use the existing light-wash component for a soft pool beneath them. `components/scenery/christmas_market/decorated_pine.tscn` composes the trimming with the existing Layered Pine variant and a restrained evergreen palette.
