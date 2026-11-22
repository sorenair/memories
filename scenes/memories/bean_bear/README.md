# Bean and Bear Lakes · July 25, 2026

A summer backpacking memory in northern Minnesota. Start beside the parked 4Runner, take a winding forest trail to the cliff lookout, then descend to the lakeside camp. Recall it between Southern Vietnam and Vineyard, or run `res://scenes/world/bean_bear_world.tscn` with F6.

## Three zones

- **Trailhead.** The main earth trail and a shorter side trail split around a cluster of granite boulders and meet at the first fragment. Pines, birches, ferns, and loose patches of forest floor frame the trails.
- **Overlook.** A climb follows the flank of the coastal headland. A short spur leads to the second fragment and opens the camera onto one lake, with patches of meadow and mixed-height forest along the shore. Three crows take flight when an explorer approaches. The trail continues from the spur junction around the opposite flank.
- **Campsite.** The tent, stove, and sculpted fire sit in a clearing framed by brush and tree clusters. A short path past the third fragment reaches the bank of the same lake. Tap the fire ring to light or extinguish the flame, warm light, and crackle. The tent uses the open-fly option to show the inner mesh door. [The North Face’s Stormbreak 2](https://www.thenorthface.com/en-us/p/bags-and-gear/camp-shop-829877/stormbreak-2-tent-NF0A8BDM)

## Editing

Edit **Fragment → Note Title / Notes** in each zone. The placeholders are **Into the north woods**, **Above the lake**, and **Camp beside the lake**. The three zone instances in `../bean_bear.tscn` set the forest ambience. Fire crackle plays on **Ambience** through a spatial player. Fragment cues use **SFX**, and **Memory/Audio** can carry music.

The camera starts at **3.5**, follows the trail at **4.6**, opens to **20** at the elevated lookout spur, and settles to **9.4** at camp. The framing shifts toward the lake as the player approaches the bank. The lookout temporarily hides camp scenery and the camp fragment’s orb from the local camera. Its route remains available to guidance. **Overlook Focus** and **Overlook Size** tune the reveal.

The hidden **Environment/ForestFloor** provides finite ground and boundary collision. **OverlookClimb** and **ToCamp** also provide continuous sloping collision, and the reused headland follows their profiles. Keep the spur junction near the headland’s **3.2 m** top height. Foreground routes use the shared earth-trail component’s end fades and soft shoulders. Keep foliage low along the lookout lip, the tent frontage, and the shoreline spur.

`../../../scripts/bean_bear_memory.gd` derives guidance from the authored trails. If their footprints change, regenerate the finite floor and check both directions:

```sh
godot --headless --path . --script tools/rebuild_bean_bear_floor.gd
godot --headless --path . --fixed-fps 60 --script tests/bean_bear_memory.gd
```

**ArrivalRecall**, **OverlookRecall**, and **CampRecall** place the major reveals on reachable ground. The lake uses the overlook anchor. The camp anchor sits near the bottom of the descent so the clearing is revealed on approach. Each player sees their own camera framing and fire state.

The route check walks the fork, lookout, descent, and shoreline spur, reads all three fragments, checks guidance and camera framing, triggers a crow, toggles the fire, and confirms the timeline keeps the chosen avatar.
