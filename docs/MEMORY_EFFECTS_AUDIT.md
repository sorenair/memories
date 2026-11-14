# Memory recall and foliage audit

Verified against every world in `UI/memory_lane/memory_lane.gd` on November 13,
2026. Counts include generated child components, such as arcade light washes.

| Timeline memory | Recall components | Foliage responding to players |
| --- | ---: | ---: |
| First Meeting | 44 | 24 |
| Football in the snow | 4 | 0 |
| Minneapolis Institute of Art | 15 | 0 |
| Christmas market | 77 | 47 |
| New Year's Eve | 14 | 0 |
| Como Conservatory | 140 | 130 |
| Seasonal Demo | 62 | 46 |
| **Total** | **356** | **247** |

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
jungle and bonsai views; the headless catalog audit passes for all seven worlds.
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
