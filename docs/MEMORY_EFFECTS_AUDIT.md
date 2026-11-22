# Memory recall and foliage audit

Verified against every world in `UI/memory_lane/memory_lane.gd` on November 17,
2026. Bean and Bear Lakes, Vineyard, First Sail, and Colorado were rechecked on November 21, 2026.
Duluth was rechecked on November 22, 2026. Counts include generated child components, such as arcade light washes.

| Timeline memory | Recall components | Foliage responding to players |
| --- | ---: | ---: |
| First Meeting | 44 | 24 |
| Football in the snow | 4 | 0 |
| Minneapolis Institute of Art | 15 | 0 |
| Christmas market | 127 | 95 |
| New Year's Eve | 14 | 0 |
| Como Conservatory | 157 | 142 |
| Postcard Cabin | 158 | 149 |
| Mifflin Block Party | 92 | 61 |
| Graduation | 53 | 42 |
| Tokyo | 125 | 105 |
| Northern Vietnam | 197 | 144 |
| Central Vietnam | 178 | 155 |
| Southern Vietnam | 178 | 157 |
| Bean and Bear Lakes | 374 | 347 |
| Vineyard | 139 | 89 |
| First Sail | 33 | 27 |
| Labor Day in Colorado | 241 | 158 |
| Duluth in the Fall | 392 | 293 |
| Seasonal Demo | 62 | 46 |
| **Total** | **2583** | **2034** |

The stadium, museum and New Year's Eve currently contain no reactive foliage.
Their scenery, displays, crowds and lighting still recall. Library studies and
empty/template scenes are outside the playable timeline audit.

## Implemented behavior

- Each scenery component starts independently when either visible explorer
  approaches. All adapters use the shared distance in
  `components/effects/recall/recall_settings.tres`.
- Added the solid upward white-edge scan to the newer stadium/museum pieces,
  market buildings and stage, crowds, flowers and arcade atmospheric traces.
  Fire uses a smooth fade through the same shared proximity system as smoke.
- Enabled recall on authored instances in every memory, including nested market
  pines/trimmings and generated arcade washes. Market grass/bush response is
  enabled again; tree canopies now respond gently where their leaves are reachable.
- Local and LAN players both affect nearby grass, bushes, trees, vines and flowers.
  Grass supports both positions; vertical filtering prevents wrong-floor bending.
  A departing or hidden actor no longer drives recall or foliage response.
- The stadium field recalls from the accessible viewing platform. Elevated scenic
  props may use a recall anchor without changing the global distance.

Ground, platforms, paving, snow cover, weather, fragment beacons and guidance stay
available throughout exploration. Solid architecture retains collision during its
scan so stairs and navigation remain safe.

## Verification

`tests/memory_effects.gd` reads the live timeline catalog and loads each world. It
checks every recall controller, far/near triggers for both actors, completion,
hidden-player filtering, and two-player inputs on each reactive foliage component.
The graphical pass captures hidden, midway and nearby-completed states across all
six earlier worlds. Como's additional scene walkthrough captures its garden,
jungle and bonsai views; Postcard Cabin's walkthrough captures its winter trail,
ice and fireside clearing. Mifflin adds street, porch and bar views, with its complete
two-zone composition shown in a fully recalled overview. Vineyard adds vine-aisle,
deck and field views. Graduation adds arches, portico and ceremony views with
53 recallable pieces and 42 responsive foliage components. The catalog baseline
covered all nineteen worlds. Tokyo's updated shrine, temple and city views have
125 recallable pieces and 105 responsive foliage components. Northern Vietnam's
updated streets, lake and bay have 197 recallable pieces and 144 responsive foliage
components. Central Vietnam's limestone grove, terraced shrine and imperial
court have 178 recallable pieces and 155 reactive foliage components.
Southern Vietnam's cove, lighthouse ridge, dunes and crowded skyline have 178
recallable pieces and 157 reactive foliage components. Bean and Bear Lakes adds
the forked forest trail, single-lake overlook, and camp, with 374 recallable
pieces and 347 reactive foliage components. The distant shore and camp reveal
from separate reachable anchors. First Sail has both sailboats, dock, lake and
planted banks, with 33 recallable pieces and 27 reactive foliage components. Duluth has a wooded bedrock hike, a concrete lighthouse pier, and Enger Park,
with 374 recallable pieces and 279 reactive foliage components. Colorado's polish pass verified 241
recallable pieces and 158 foliage components that respond to both explorers.
Existing grass, bush, shared-distance, fire and smoke checks pass.
Two separate LAN host/guest processes also pass, including remote foliage-group
membership while remaining outside the local input/interaction group.

```sh
godot --headless --path . --script tests/memory_effects.gd
godot --path . --script tests/memory_effects.gd -- --capture
```

The captures are written to `/tmp/memory-effects-{memory_id}-{phase}.png`.
Godot's headless renderer still logs its existing remote-avatar material warnings
in the LAN check; graphical recall captures have no shader or script errors.

## Adding another memory

Enable **Recall Enabled** on each recallable scenery instance and on any nested
component that owns a separate controller. Enable **React to Explorer(s)** on
foliage. Keep library preview defaults visible. For a component outside the
walkable area, choose a reachable **Recall Anchor** where supported. Run the
catalog audit after registering the memory, then inspect the graphical capture.

See [component recall](../components/effects/recall/README.md) for adapter behavior
and [memory authoring](../scenes/memories/README.md) for scene structure.
