# Painterly bird

Instance `painterly_bird.tscn`. Pick **Black** or **White** in **Colors → Palette Preset**. Choose the color that reads against the location. The silhouette uses broad tapered wings, a short beak, and a forked tail with a restrained tonal wash.

| Behavior | Placement and controls |
| --- | --- |
| Ground | Place the origin on a flat patch. The bird pecks and makes short hops within **Hop Radius**. Set that radius to zero for stationary idle. |
| Flee On Approach | Starts on the ground, then climbs away when an explorer crosses **Scare Radius**. **Flight Duration** sets the minimum time before it can disappear outside the camera. **Respawn Delay** defaults to zero for one departure per visit. |
| Circling | Place the origin at the center of the loop. **Circle Radius**, **Circle Height**, and **Flight Speed** set the flight path. Wingbeats alternate with short banked glides. |

Call `take_off(world_direction)` to cue a ground bird from another scene action. The component is decorative and assumes the small hop area is level.
