# Painterly bird

Place `painterly_bird.tscn` at ground level. A small, rounded bird waits with breathing, gentle looking-around, and occasional pecking motions. Its simple cream chest, tiny beak, dot eyes, folded wings, and broad softly edged toon tones match the meadow's painterly style.

When an explorer in the same viewport comes within **Scare Radius**, it crouches briefly, opens its wings, and accelerates into an upward, slightly curved flight away from the closest explorer. Wings flap independently; the contact shadow fades as the bird climbs. It hides and stops processing after departure. No pathfinding, collision, or physics body is required.

| Inspector control | Purpose |
| --- | --- |
| Bird Seed | Idle phase, starting orientation, and takeoff variation |
| Bird Size | Overall proportions / scale |
| Ground Offset | Raise the feet slightly for grass or uneven surfaces |
| Palette Preset | Sparrow, robin, bluebird, dove, or custom |
| Body / Belly / Wing / Beak Color | Custom plumage and beak tint |
| Scare Radius | Horizontal proximity trigger, with a vertical check to ignore distant floors |
| Idle Motion | Strength of breathing, looking, and pecking |
| Flight Speed / Ascent Speed | Departure speed and climb |
| Flight Duration | Seconds before the airborne bird disappears |
| Respawn Delay | Zero for once per visit; otherwise seconds to return to its original ground position |

Generated geometry remains internal; the editor previews idle motion. **Reset Bird** regenerates the component and restores its idle state. At runtime `state` exposes IDLE, TAKING_OFF, FLYING, and DEPARTED. `startled(explorer)` and `departed` signals support future sound or gameplay hooks. `flee_from(explorer)` can trigger the same flight from other events.

The bird is 2,352 triangles in three opaque geometry draws (merged body/details and two movable wings), plus one small contact-shadow draw. No textures, particles, shadow maps, animation skeleton, or navigation. Proximity scans run at most about eight times per second while idle. A departed one-shot bird performs no further updates.

Demo instances: `SummerSpring/MeadowSparrow`, `SummerSpring/PondRobin`, and `SummerSpring/FlowerBluebird`. They begin outside the entry's scare radius so players can approach them naturally.

Run `godot --headless --path . --script res://tests/bird.gd` for proximity, flight direction, flapping, departure, optional respawn, finite transforms, geometry budget, and demo-placement checks.
