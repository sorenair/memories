# Duluth in the Fall · October 12, 2026

Three zones recall a wooded hike, a walk out into Lake Superior, and the Peace Bell garden at Enger Park. Select **Duluth in the Fall** after Colorado, or run `res://scenes/world/duluth_autumn_world.tscn` with F6.

## Zones

- **Fall trail.** The forest track winds through clustered trees, ferns, and leaf litter in gold, copper, and red. Dense overlapping groves and lower brush fill the slope below the lookout. It fades into a short climb cut into faceted bedrock, with brush and grass tucked around loose boulders. A small overlook holds the first fragment. The descent leaves the exposed rock and re-enters the woods before reaching the shore.
- **North Pier Light.** Boulders, golden sedges, and staggered riprap frame the walk from shore onto the concrete breakwater. The track opens onto a flared octagonal landing with an ivory tower, dark base, and warm beacon. White birds flush from the pier and circle the lantern. A scaled Ensign follows a looping offshore tack. The fragment sits at the landing. Return along the pier and follow the shore-side turn toward Enger Park. [U.S. Coast Guard lighthouse reference](https://www.history.uscg.mil/Browse-by-Topic/Assets/Land/All/Article/1914028/duluth-north-pier-light/)
- **Enger Park.** A shaded gravel approach gives way to flagstones and bends around a dry, raked lake. The vermilion pavilion shelters a bronze Peace Bell, with a stone lantern and a dry pebble stream. Small groups of grasses and brush hug the gravel edge and root its stones. Five visitors idle in pockets around the loop. The optional loop changes from flagstone to gravel behind the pavilion. [Enger Park](https://duluthmn.gov/parks/parks-trails/parks-listing/enger-park/) · [Landscape architect's project photos](https://saslandarch.com/portfolio/parks-public-spaces/ohara-japanese-peace-bell-japanese-garden/)

## Authoring

Edit the **Fragment → Note Title / Notes** in each zone scene for personal text. The zone root's **Ambience Stream** controls its ambience. **Memory/Audio** holds the music slot and fragment cue. Local camera, note, audio, and scenery recall state are independent on each device.

The follow camera holds **4.35** for walking. It opens to **14** on the lookout, **18** near the end of the pier, and **12** at the garden fragment. The Peace Bell approach frames the striker and pavilion at **6.8**, and the uphill gravel spur opens to **12.4** to frame Enger Tower. Keep tall plants away from the walking sightline and check fragment tap picking if you move it. The pier fragment's higher float offset clears the hidden boundary in the actual camera.

`LookoutClimb` and `ToLighthouse` describe grades for `RockLookout` and guidance. The generated terrain supplies both rock surface and collision. `ForestTrail` and `ForestReturn` are the painted earth surfaces at each end. The breakwater supplies its own deck and landing, with the finite floor outline following their join. The garden's guidance and floor use the full curves while painted gravel and flagstone segments fade where their materials change.

Edit the garden’s finite ground footprint in `garden_walk_outline.tres`. The sailing route is the `OffshoreSailing` curve. Keep it at the lake’s waterline when moving the water or the path.

Tap the wooden striker from beside the Peace Bell pavilion to ring it. The striker draws back, pauses, and swings into the bell. **Strike Sound** on the Peace Bell component sets the gong cue. The garden inherits this setting. Follow the gravel spur from the back of the garden loop to reach the tower viewpoint.

After changing the walking routes, garden footprint, or pier, rebuild the finite outline and run the walkthrough.

```sh
godot --headless --path . --script tools/rebuild_duluth_floor.gd
godot --headless --path . --fixed-fps 60 --script tests/duluth_autumn_memory.gd
```

Pass `-- --capture` to the desktop renderer to capture previews. The walkthrough exercises the route in both directions, the optional garden loop, the pier boundary, camera reveals, fragment taps, and timeline recall. Separate `-- host` and `-- guest` processes use isolated UDP 24785.
