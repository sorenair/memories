# Memory design guide

Use this as the design and implementation standard for future memories. It is grounded in the authored **First Meeting** and **Football in the snow** scenes, their shared world/zone framework, and their rendered previews. Scene files are the source of truth; older previews and design reviews may show earlier layouts.

## 1. Begin with the memory

A memory is a place recalled together: a few recognizable details, a clear route, and room for two explorers. Choose the details that carry the memory before adding scenery. A large location can feel expansive while only a small part is walkable.

Write a short brief before building:

- **Confirmed context:** place, season, time, reference photos, and any exact colors or markings.
- **Emotional focus:** what should the shared visit feel like?
- **Recognizable details:** two or three essential objects or spatial relationships.
- **Zone plan:** each place/beat, its fragment, ambient sound, and connection to the next.
- **Player experience:** arrival, exploration, interaction or overlook, and return route.
- **Unknowns:** personal wording, dates, and other details that need the author's input. Mark placeholders explicitly; do not invent autobiographical facts.

Before proposing new components, **search `components/`, component READMEs, and existing memory scenes for reusable pieces**. Inspect their scenes and exported controls to see whether configuration, composition, or a small extension can meet the brief. Record the reusable components and any remaining gaps in the scene plan; create a new component only for a need the existing library cannot reasonably cover.

## 2. Keep the shared framework

Inherit [memory_template.tscn](../scenes/memories/memory_template.tscn) for a starting platform and zone, or [memory_base.tscn](../scenes/memories/memory_base.tscn) for an empty composition. Author places as inherited [memory_zone.tscn](../scenes/memories/memory_zone.tscn) scenes.

```text
MemoryWorld                    inherits memory_world_base.tscn
├── Memory                     inherits memory_base.tscn
│   ├── Entry / Exit            arrival and departure markers
│   ├── Environment             shared ground and routes
│   ├── Audio                   music, optional global bed, effect cues
│   └── Zones                   children in story/guidance order
│       └── Place               inherits memory_zone.tscn
│           ├── Scenery         components; optional section containers
│           ├── Fragment        one local story fragment
│           └── Ambience        zone's ambient player
└── inherited explorer, camera, controls, interaction and guidance
```

Each memory needs a unique, stable `memory_id` and a display name; each zone needs its own `zone_id`. Keep player, partner, camera, input, and shared UI in the world wrapper. It connects to the persistent LAN session and binds the local explorer as the audio listener.

Use a zone for a distinct place/beat with its own fragment and ambience. **A camera change or a second walking section does not require another zone.** Shared ground can live under Environment; ground belonging to one zone can live under its Scenery. The other base containers, including SignatureInteraction, are extension points. **Exit is a marker, not an implemented completion sequence.**

| Reference | Structure and route | Identity and presentation |
| --- | --- | --- |
| [First Meeting](../scenes/memories/first_meeting.tscn) | House → Arcade: two zones on one 34 × 19 m platform; gate, sidewalk, then an open triangle of activities. | Bungalow, large autumn tree, doorway vines, pale fence; pinball, punching bag, mechanical band. Close orthographic camera; wind blends into arcade hum. |
| [Football in the snow](../scenes/memories/snowy_stadium/stadium_zone.tscn) | One Stadium zone: intimate arrival landing with fragment → narrow aisle → viewing bay. One concave floor and continuous snow surface. | Minnesota maroon/gold, wordmarks and M, snowy field, distant bowl and lights. Camera reveals scale; field players and crowd add restrained movement. |

[First Meeting overview](previews/first-meeting-review-overview.png) · [Stadium overlook](previews/snowy-stadium-overlook.png)

## 3. Design walking space and camera together

- Block out arrival, fragment, approaches, and connecting paths before dressing the scene. Leave room to pass another explorer and operate props without standing inside foliage or collision.
- Use **MemoryPlatform** for finite supported ground. The world discovers it, disables infinite ground, and matches its dissolve to the void. Keep safe boundaries aligned with visible railings, fences, or edges.
- For connected landings/aisles, prefer **one custom-outline platform**. Separate platforms have closed safety rims that can block their joins. A concave outline preserves both narrow routes and surrounding empty space.
- Place Entry on the actual floor, including elevated decks. Allow the LAN guest's fallback spawn **1.2 m to the right**. Set the wrapper's `recalled_spawn_offset` deliberately; both authored memories use zero instead of the base world's 10 m offset.
- Check paths with the actual explorer: gates, stairs, benches, prop controls, fragments, and turnarounds. Decorative stadium tiers and field need no walking collision.
- Start with the inherited near-isometric orthographic camera. **Size 3.5** is the close exploration reference. Keep the explorer and nearby fragment readable without foreground objects hiding them.
- Stage a wide view through movement along a readable route. Football eases from **3.5 to 64** using transition markers and a fixed stadium focus. Keep camera yaw stable so movement directions remain predictable. Upper stands may crop; preserve the player, field, and important visual anchors.

See [platform authoring](../components/scenery/platforms/README.md) and [stadium camera/layout](../scenes/memories/snowy_stadium/README.md).

## 4. Maintain the visual language

**A small handcrafted world emerging from a generous warm-white void.** Use elevated three-quarter compositions, simplified geometry, matte painterly surfaces, broad pigment variation, gentle lighting, and soft contact shadows. The shared environment's warm ivory is approximately `#F0EEE3`.

- Build clear silhouettes and concentrate detail around meaningful objects. Suggest the rest with fragments, interrupted scenery, haze, and fading ground. Avoid enclosing every place in complete walls or a hard rectangular border.
- Keep the overall palette restrained. Use stronger accents where identity requires them: autumn amber/red, muted arcade cabinets, or Minnesota's maroon/gold markings. Reuse [foliage palettes](../components/foliage/PALETTES.md) across related components.
- Translate references selectively. Preserve recognizable proportions, entrances, colors, logos, and relationships; omit incidental street clutter. Authentic world markings can matter more than generic decoration.
- Compose foliage in uneven clusters with varied seeds, spacing, rotation, and scale. Keep walking approaches legible. Let paths, leaves, and partial architecture connect places through the white space.
- Make groundcover fit its supporting geometry. Football shares a Custom Outline between deck and **WalkableSnow**, giving one continuous bank and footprint field. Use exclusions around objects and water. Scatter field snow organically; avoid repeated oval patches, regular bands, or an added snow border around the pitch.
- Match existing house/arcade/stadium materials when adding models: softened edges, vertex color, broad washes and restrained shading. Avoid photographic textures, glossy plastic, harsh outlines, dense tiny detail, and spectacle that competes with the memory.

## 5. Fragments, interactions, and guidance

Place each zone's **Fragment** on supported, approachable ground near its visual anchor. Edit **Note Title / Notes** on that instance; each Notes entry is one page. Both authored memories still contain placeholder personal prose. Reuse the shared reading panel, tap feedback, collection effect, and completion lifecycle.

Use the existing interaction contract for new activities: join `memory_interactables`, provide a side-effect-free `can_interact(actor)`, and recheck conditions in `try_activate(actor)`. The shared controller supplies range/occlusion checks and white silhouette feedback. Give small controls comfortable touch targets.

Guidance is **requested**, using the HUD circle or E: one finite brushstroke toward the first unfinished fragment. Default order is Zones child order; `guidance_fragments` overrides it. Author hidden route definitions under Environment/Guidance when gates or scenery require a particular path. Hints should follow safe ground, never cut through obstacles, and never start automatically after reading.

Details: [fragments](../components/interactables/fragments/README.md), [interactions](../scripts/interaction/README.md), [brushstroke routes](../components/guidance/brushstroke/README.md).

## 6. Give each place a sound identity

Assign the zone root's **Ambience Stream**, volume, Size, Blend Distance, and Response Seconds. These bounds control audio coverage, not navigation. Beds follow the local explorer, normalize overlaps, and fade smoothly; the elevated camera and partner do not drive the mix.

The memory's **Audio** owns music, optional global ambience, and shared fragment cues. Components can add short effects through the existing cue helpers or SFX bus. The routing is **Music / Ambience / SFX → Memory → Master**, with **UI → Master**. Let the shared transition system control the Memory fade. Balance clips at player level and keep ambience quiet enough for small effects to register.

First Meeting demonstrates wind → arcade hum plus instrument/game effects; Football uses quiet wind. Music slots exist but are currently unassigned in both. See [audio authoring](../audio/README.md).

## 7. Add life economically

Reuse components before creating new ones. Favor seeded procedural meshes, shared materials, batched static scenery, and MultiMesh repeated geometry. Keep generated children internal and rebuild only when authoring parameters change.

Use shader motion for background life: leaves, weather, and Football's individually phased crowd bounce. A small number of scenic actors can use instanced animated poses, as the 22 field players do. Avoid per-person nodes or per-frame mesh regeneration for a distant crowd. Include animation displacement in culling bounds; judge cost in the real Mobile renderer.

Enable proximity recall per instance where approaching a component should assemble the memory, as in First Meeting. Keep ground/routes readable and collision safe during recall. Distant stadium scenery stays visible so the overlook works. See [component recall](../components/effects/recall/README.md).

LAN currently shares **avatar choice and player movement/contact** when both devices occupy the same memory ID. Notes, interactions, recall, audio, and scenic animation remain local; design any required shared event explicitly rather than assuming it replicates. See [network behavior](../scripts/network/README.md).

## 8. Build and review a new memory

1. Confirm the brief and search the existing component library and memories for reusable pieces before planning new components. Then block out the floor, two spawns, fragment, route, and camera.
2. Create memory/zone scenes with stable IDs; add reusable components and a few distinctive details.
3. Tune materials, edges, groundcover, recall, ambience, effects, and any small interaction.
4. Inherit [memory_world_base.tscn](../scenes/world/memory_world_base.tscn), instance content as **Memory**, and configure arrival/camera overrides. Add the wrapper to `MEMORIES` in [memory_lane.gd](../UI/memory_lane/memory_lane.gd).
5. Walk the whole route in both directions. Check close/wide framing, touch targets, note completion, requested guidance, audio blends, safe boundaries, both avatars, and partner arrival/departure. Use two processes for LAN checks.
6. Save a short memory-specific README and rendered close/overview previews in **docs/previews/**. Concept/reference art and prompts belong in **docs/concept-art/**. Update links and capture paths together.

Useful existing checks are `tests/memory_zones.gd`, `tests/memory_audio.gd`, `tests/first_meeting_guidance.gd`, and `tests/snowy_stadium.gd`; render the actual world as well. Follow the [LAN guide](../scripts/network/README.md) for current two-process checks. Existing tests are examples to adapt to the new layout, not proof that a new memory is complete.
