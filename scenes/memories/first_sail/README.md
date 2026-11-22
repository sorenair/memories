# First Sail · August 22, 2026

One lake-focused zone runs from the planted summer bank to a wooden dock with a Pearson Ensign and a Club 420.
Recall it after Vineyard, or run `res://scenes/world/first_sail_world.tscn` with F6.
The date and sailing theme are confirmed; the lake's name, time of day and personal
wording are unspecified. The scene keeps the shared soft daylight and warm-white void.

## Composition and reused pieces

`lake_zone.tscn` inherits the standard MemoryZone. It instances the existing
**PainterlyWoodenDock** as a T landing, **PainterlyEnsign**, **PainterlyC420**, and
**PainterlyWater**. A soft-edged earth trail fades at the ramp. Grasses, bushes, stone
clusters and trees frame the bank and continue along the opposite shore. The main
planting leaves the ramp and walking approach open.

The 9 m dock has a 2.4 m main pier, 6 m landing, side rails and its existing sloped
shore ramp. The Ensign sits east of the landing, and the shorter Club 420 sits west. Both share
the same waterline and use shader-driven rocking and sail flutter. Three white birds
circle over separate parts of the lake. Three others hop along the pier and landing,
then fly off when an explorer approaches.
See the [sailing kit](../../../components/scenery/sailing/README.md) for controls.

One hidden **Environment/ShoreAndDockFloor** supplies finite support and outer
safety boundaries along the bank, ramp, pier and landing. The dock supplies its
actual elevated collision. Keep the floor's **Custom Outline** aligned with the
pier and landing when changing dimensions. **Lake → Block Water Entry** stays off
so shoreline barriers do not cut across the access ramp. The finite floor stops
explorers before the open landing edges. Entry and the guest's **+1.2 m X** fallback
both fit on the shore approach.

## Authoring

Edit **Lakeside → Fragment → Note Title / Notes** in `lake_zone.tscn`. The placeholder
is titled **Our first sail** and asks for your own words about the Ensign. It stands
on the landing, with room for both explorers. Requested guidance follows the same
shore curve, then the real ramp and pier; it is derived by
`../../../scripts/first_sail_memory.gd` and updates when the path or dock changes.
If changing dock length/height, reposition the fragment, floor and Entry as needed.

`../../../scripts/first_sail_camera.gd` starts at **3.5**, gradually opens through
**6** on the ramp/pier, and reaches **17** at the landing. The fixed-yaw reveal
fits both boats from bows to mastheads. **Sailing Focus** and **Sailing Size** tune
the view. Walking back to shore smoothly restores close framing.

**ShoreReveal** reveals the water and dock from the bank. **DockReveal** reveals both
boats and the far bank as the player walks onto the pier. Foliage responds to both explorers. Boat and
sail motion run in the existing shader without per-frame geometry updates.

The **Lakeside** instance in `../first_sail.tscn` sets the water ambience.
**Memory/Audio** provides the music slot and fragment SFX cue. LAN shares avatar
choice and player movement. Recall, notes, audio and scenic motion are local.

## Validation and previews

```sh
godot --headless --path . --fixed-fps 60 --script tests/first_sail_memory.gd
godot --path . --fixed-fps 60 --script tests/first_sail_memory.gd -- --capture
godot --headless --path . --script tests/sailing_components.gd
godot --headless --path . --script tests/memory_effects.gd
```

The memory check walks the shore, ramp, both landing arms, and return route. It checks
both boats' recall and framing, dock bird takeoff, fragment guidance, edge safety,
ambience, and timeline avatar choice. Rendered previews can be generated with
`--capture`. The automated LAN check uses isolated UDP 24775 with separate `-- host`
and `-- guest` processes.
