# Memory polish guide: all memories

Updated November 17, 2026. Use this guide to delegate visual and experiential
polish of the existing memories. It generalizes the First Meeting visual review;
it does not mean that every memory has the same deficiencies or needs the same
camera, palette, density or effects.

**Goal: beautiful, lush, engaging places remembered in fragments, with the ivory
void remaining an active part of their composition.** Improve the existing
memories' design, layout, aesthetics, effects and atmosphere while preserving
their core identity and content.

Use the [memory design guide](MEMORY_DESIGN_GUIDE.md) for the shared architecture
and authoring conventions, each memory's README and current scenes for its brief,
and the [effects audit](MEMORY_EFFECTS_AUDIT.md) for existing recall/foliage behavior.
The playable set is registered in `UI/memory_lane/memory_lane.gd`. Scene files and
runtime inspection take precedence over older screenshots or outdated descriptions.

## 1. Preserve the memory; improve its presentation

Retain the confirmed location, season, recognizable landmarks and props, personal
details, main activities, zone sequence and meaningful spatial relationships.
Preserve memory/zone identities, fragment identity and personal text, existing
interaction behavior, two-player access, arrival/departure, requested guidance,
and the shared recall/return experience. Flag inconsistent labels or placeholders;
do not reinterpret a memory or invent autobiographical facts to resolve them.

Appropriate polish includes regrouping supporting scenery, enriching planting,
refining paths and viewpoints, adjusting composition and camera transitions,
improving materials and lighting, integrating effects, and strengthening feedback
around existing interactions. Keep landmarks' relationships and approaches intact
when adjusting their placement. Decorative architecture can be reduced where it
adds enclosure without contributing to the memory's identity.

A zone does not become better simply by containing more objects. Judge additions
by the atmosphere, depth, movement, recognition or interaction they contribute.
Preserve the differences between a crowded celebration, a quiet bonsai display,
a forest trail, an open beach and a bare summit.

## 2. Balance richness with the void

The void belongs **within views and between groups**, as well as outside the
memory. Keep porous edges, gaps between silhouettes, open approaches and visible
breathing space. Zone transitions can use interrupted paths, loose planting and
fading pigment; they do not need continuous reconstructed buildings or landscape.

There is no fixed percentage of white space or universal object-count target.
Make the relationship deliberate at the actual gameplay camera.

| Setting | Add richness through | Keep open or incomplete |
| --- | --- | --- |
| Bar, arcade, café or domestic vignette | Recognizable activity props, selected furnishings, warm local light, a few personal details, tactile materials, sound and response. | Large floor rectangles, complete walls, ceilings and background furniture are unnecessary unless essential to the established memory. Leave ivory between meaningful groups. |
| Museum, shrine, campus or architectural landmark | Clear silhouettes, selected façade/structural fragments, framed art, planted accents, directional light and well-staged approaches. | Keep the building parts needed for recognition; allow courtyards, surrounding structure and approaches to fragment into the void. |
| Forest, garden, vineyard or lush shore | Layered canopies, varied shrubs, fine groundcover, flowers/ferns where appropriate, rocks, irregular banks and restrained ambient life. | Retain clearings, paths, sightlines, windows of ivory and soft outer breaks. Avoid a continuous perimeter hedge or equally dense planting everywhere. |
| Snow, beach, dunes, summit or open water | Landform, surface paint, light/shadow, banks, rock groupings, weather and sparse vegetation appropriate to the place. | Preserve the openness that makes the setting recognizable. Lush visual treatment does not require lush vegetation. |
| Concert, market, street party or city | Existing crowd groups, selected stalls/stage/city landmarks, changing silhouettes, light rhythm and fragments of a route. | Use clustered activity and suggested urban edges; avoid automatically completing a street grid, stadium shell or room around them. |

**Bar example:** a counter, a few stools, existing game/music props, warm light
pools and some suspended lights or fading floorboard strokes can evoke the place.
Supported walking ground can remain visually ivory. Adding a whole building and
continuous floor to justify those objects can make the zone feel detached from
the memory world. Improve the chosen details and their relationship first.

**Nature example:** deepen a forest with overlapping crowns, uneven understory,
smaller ground plants, stones and a softly planted bank. Allow the path to pass
through a rich pocket, then open to a clearing or distant view. Taper the edges
through smaller groups and pale ground pigment. Richness should have rhythm.

Use three levels of emphasis in each zone:

- **Focal areas:** the most meaningful details, strongest controlled contrast and
  richest close inspection around an existing landmark, fragment or activity.
- **Supporting areas:** layered scenery that establishes place, depth and mood,
  with quieter detail and sufficient separation from the focal areas.
- **Open areas:** clear walking space, quiet surfaces and ivory gaps that make
  the other two levels readable and connect the zone to the void.

If a place feels empty, identify what is missing: recognition, framing, layers,
grounding, movement or feedback. If it feels enclosed, reduce or interrupt
nonessential structure and uniform coverage while retaining its meaningful core.

## 3. Priorities for each memory's pass

Apply these according to runtime evidence. The first pass should address the
largest relationships in the frame before polishing small accents.

### Composition, camera and navigation

- Stage arrival, the first landmark/fragment, major interactions, scenic pauses,
  and the approach to the next zone. Establish a leading subject in each view.
- Compose through the real follow camera, not only a high overview. Preserve
  readable players, nearby destinations and comfortable mobile touch targets.
  Use existing scenic framing and transitions where they already work.
- Tune size, focus and foreground placement together. A First Meeting study of
  sizes 3.5 / 5.5 / 6.5 is evidence for that scene, not a new global camera rule.
  Avoid continuous zoom pumping or camera rotations that undermine movement.
- Frame landmarks with asymmetric vegetation/architecture and leave openings
  toward the void. Keep foreground leaves, roofs and signs from hiding players,
  fragments and controls. Solve placement before adding complicated occlusion FX.
- Keep both arrivals, passing space, routes, ramps, stairs and return travel safe.
  Update ground outlines, exclusions, guidance and bounds alongside layout edits.
  Existing curve-based paths should remain the source of connected route data.

### Nature enrichment and foliage hierarchy

- Nature scenes can generally gain more depth and richness. Identify thin spots
  and build intentional pockets of overlapping large, medium and small forms.
  Use suitable existing tree variants, shrubs, ferns, flowers, grasses and rocks.
- Separate canopy, shrub and ground scales. Smaller, quieter ground plants can
  support a much fuller landscape without becoming oversized angular leaf clutter.
  Add irregular clumps, varied heights, seeds and rotations rather than increasing
  every scatter count or filling each patch uniformly.
- Keep clearings, banks and path edges distinct. Concentrate detail near focal
  approaches and vary coverage across the rest. Use Ground Exclusions so growth
  does not bury paving, steps, water, props or interaction positions.
- Respect ecology and season. Preserve exposed rock on an alpine summit, open
  sand on a beach, calm space around bonsai, and useful visibility around wildlife.
  Ordered grape rows, terraces and formal gardens can retain their meaningful
  patterns; vary margins and supporting growth without erasing those patterns.
- Preserve and tune existing two-player foliage response and falling leaves.
  Larger masses should move more slowly; ground plants can respond locally and
  settle gently. Repeated synchronized motion makes a rich scene feel mechanical.

### Light, color, materials and contact

- Give related components a coherent artistic key direction, fill and shadow
  palette. Use selective canopy/eave shading, grounded object bases and readable
  recesses to connect objects to the place. Unshaded painted materials need their
  own coordinated shading; changing a world light alone may not affect them.
- Build value hierarchy before adding saturation. Support lush scenery with
  quieter areas; concentrate stronger contrast and color around meaningful
  subjects. Give each memory/zone its own appropriate relationships rather than
  spreading First Meeting's amber palette across the whole game.
- Distinguish wood, stone, fabric, leather, glass and metal through broad directed
  strokes, soft material-specific shading and selective edges. Brushwork should
  describe structure. Avoid adding uniform noise or photographic wear everywhere.
- Balance large shapes, medium detail and small accents. Soften appropriate prop
  corners and simplify thin repetitive detail that flickers or dominates on a
  phone. Preserve recognizable proportions, markings and personal objects.
- Match terrain to the geometry and palette of nearby components. For exposed
  rock, use defined boulder silhouettes and broad planar faces. Carry walkable
  grades through those forms so the trail reads as part of the landform.
- Refine surface transitions: water to bank, snow to steps, soil to path, props to
  ground. Match footprints, exclusion fields, shore masks and physical support.
  Let visible surfaces fade into ivory before accidental platform sides or seams
  become the subject. A safe supported floor need not be a fully visible floor.
- Keep foreground, focal area and background distinguishable. Tune distant
  simplification and haze without washing away nearby landmarks or hiding the
  scene's weak composition under a blanket of fog.

### Effects, motion and engagement

- Reuse the existing component library and inspect its exported controls first.
  Many effects already exist inside other components. Configure or extend them
  coherently before creating another standalone system.
- Preserve individual **proximity-triggered recall** through the shared settings.
  Enable it for added recallable scenery and use existing reachable anchors for
  distant scenic groups. Keep stable navigation and collision during recall.
  Do not introduce a memory-wide wave or another independent distance control.
- Let broad forms establish a place while finer details and ambient life complete
  it. Integrate existing solid, foliage, water and atmospheric recall families;
  do not replace them with unrelated effects in each memory.
- Make fragments clear against ivory and dense scenery. Give their silhouettes a
  screen-space pocket through placement and surrounding composition, including
  when a player stands near them. Keep guide strokes legible on the real route.
- Choreograph different motion rhythms: slow landscape movement, occasional
  coherent gusts, quiet water, brief local responses and deliberate stillness.
  Select a small number of atmospheric accents that suit the place. Rich scenes
  should not require every object to pulse, sparkle or shed particles.
- Strengthen anticipation, contact, response and settling around existing
  interactions where needed. Small local light/sound/animation changes can make
  an established activity feel more present without inventing a new story beat.
  Preserve optional exploration and the player's control over note reading.
- Build on the existing zone ambience and audio routing. Improve local texture,
  tactile cues and transitions where evidence supports it; avoid stacking loud
  loops or assuming that an unreviewed mix is already balanced.

## 4. Starting points for the current memories

These are **candidate opportunities, not a verified defect list**. Inspect the
current scene and README before selecting work. Retain existing zone order and
core elements, including intentional open or densely planted sections.

| Memory / authored scene | Candidate polish focus |
| --- | --- |
| [First Meeting](../scenes/memories/FIRST_MEETING.md) | Porch/arcade framing, finer groundcover, fuller supporting plant masses, coherent light, clear fragments and a more evocative open arcade atmosphere. |
| [Snowy stadium](../scenes/memories/snowy_stadium/README.md) | Arrival-to-overlook staging, snow contact, crowd/field readability, depth and restrained light. Keep the existing stadium identity and scenic scale. |
| [First date at MIA](../scenes/memories/art_museum/README.md) | Selected artwork, plinths, wall fragments and light pools; give each display breathing room without reconstructing a complete museum interior. |
| [Christmas market](../scenes/memories/christmas_market/README.md) | Layer snowy evergreens and hut details, refine warm lighting, and compose the gathering while retaining the open turn and pockets of ivory. |
| [New Year's Eve](../scenes/memories/new_years_eve/README.md) | Coordinate stage, crowd, screen and light rhythms; keep activities legible and an open boundary around the remembered concert. |
| [Como Conservatory](../scenes/memories/como_conservatory/README.md) | Richer botanical layering and light in garden/jungle areas; retain the bonsai zone's calm spacing and the selected structural frame. |
| [Postcard Cabin](../scenes/memories/postcard_cabin/README.md) | Deepen winter forest layers and snow surfaces, improve warm cabin/fire contact, and preserve clearing and frozen-water sightlines. |
| [Mifflin](../scenes/memories/mifflin/README.md) | Compose party groups and bar furnishings into evocative open clusters; use light, materials and sound without enclosing the bar in a complete room. |
| [Graduation](../scenes/memories/graduation/README.md) | Frame the existing campus landmarks, enrich spring planting, and clarify the ceremony's visual hierarchy while retaining open transitions. |
| [Tokyo](../scenes/memories/tokyo/README.md) | Layer shrine/temple planting and approaches; give the crossing a distinct urban rhythm, with void visible between selected city masses. |
| [Northern Vietnam](../scenes/memories/northern_vietnam/README.md) | Refine inhabited street clusters, leafy lakeside depth and temple framing; stage the limestone/water layers with open seascape between them. |
| [Central Vietnam](../scenes/memories/central_vietnam/README.md) | Improve shoreline and crop/landmark compositions, tactile surfaces and appropriate tropical layers; preserve open beach and the authored places. |
| [Southern Vietnam](../scenes/memories/southern_vietnam/README.md) | Contrast lush coastal pockets, open wind-shaped dunes and selected city activity; retain the authored landmarks and meaningful empty areas. |
| [Bean and Bear Lakes](../scenes/memories/bean_bear/README.md) | Layer the forest trail and camp margins, integrate gear/fire/steam, and keep the two-lake overlook open and readable. |
| [Vineyard](../scenes/memories/vineyard/README.md) | Refine the ordered rows, irregular planted margins and meadow depth; keep the deck's view and quiet space between meaningful groups. |
| [First Sail](../scenes/memories/first_sail/README.md) | Enrich the shore, refine dock/hull/water contact and sail motion, and preserve the open lake. Keep the boat's established scenic behavior. |
| [Colorado](../scenes/memories/colorado/README.md) | Give field, bare summit and forest lake distinct density and material rhythms; frame formations and wildlife without planting over their identity. |
| [Duluth in autumn](../scenes/memories/duluth_autumn/README.md) | Build varied autumn canopy/understory, refine rocky shore and lighthouse contact, and preserve the garden's deliberate quiet areas. |

The Seasonal Demo and component studies are useful regression/reference scenes;
they are not a reason to replace a memory's identity with a generic showcase.

## 5. Delegation and shared ownership

Assign a whole memory where possible so one agent can compose the journey between
its zones. Give large memories explicit zone ownership if splitting them. Reserve
shared files for a coordinated owner; agents should inspect the working tree and
preserve others' edits.

| Work scope | Typical ownership and boundary |
| --- | --- |
| One memory's composition and atmosphere | Its world wrapper, memory/zone scenes, local resources, authoring script, README and relevant captures/tests. Prefer existing instance controls and local resource overrides. |
| Shared lighting/materials or reusable VFX | One assigned system owner. Verify in several contrasting memories, including bright/nature and architectural or winter settings. Record defaults and compatibility. |
| Shared avatars, HUD, audio framework or LAN presentation | Separate coordinated work. Per-memory agents can improve local use and identify needs without forking the global system. |
| Cross-memory visual review | Compare the finished passes for cohesive paint, lighting, recall, scale, interface and void boundaries while retaining differences in place and mood. |

Do not change a shared default to solve one zone's palette, camera or density
problem. Use the intended per-instance/resource controls. A genuine shared defect
belongs in the coordinated shared pass; complete independent local improvements
and report that dependency clearly. Avoid duplicate implementations of shared
materials, recall, collision, audio or guidance.

Shared presentation candidates from the original review include consistent
painted lighting, avatar finish and motion, HUD typography/debug visibility, and
shared interaction feedback. Reinspect current code before treating those as
outstanding defects. A polish assignment does not by itself call for protocol,
save-system, timeline, avatar-identity or gameplay redesign.

## 6. Agent workflow and deliverables

1. **Inspect and capture.** Read the memory's brief, current scene and relevant
   component docs. Launch its actual world. Check arrival, each fragment/activity,
   connectors, viewpoints and the return route. Capture gameplay views plus a
   separate overview; do not assume an attractive overview means good gameplay.
2. **State the zone's intent briefly.** Record its recognizable core, emotional
   tone, focal areas, opportunities for lush support, and where the void should
   remain visible. Choose a few high-impact edits from observed weaknesses.
3. **Implement within scope.** Improve composition and routes first, then
   supporting layers, materials/light, and effects/feedback. Reassess the void
   after enriching a zone. Keep the camera, visible ground and safe floor aligned.
4. **Verify the result.** Walk both directions using the real explorer, check
   both arrival positions and two-player space, guidance, steps/ramps, exclusions,
   recall and interaction access. Run checks relevant to changed behavior. Retain
   safety/identity assertions when updating intentional layout expectations.
5. **Compare honestly.** Match before/after viewpoint, resolution, recall state
   and animation time where possible. Label camera studies separately. Judge
   thumbnail hierarchy, normal close play and motion; keep distant inspection
   haze from being confused with gameplay color. Report actual-device review only
   if performed. Watch screen coverage/overdraw as well as object counts.
6. **Hand back a concrete result.** Provide changed files, the visual problems
   addressed, baseline/after images, relevant checks and remaining dependencies.
   Update the memory README with important authoring changes. Put captures under
   `docs/previews/`; preserve the current memory's stable identifiers and content.

### Copyable assignment

```text
Polish <MEMORY NAME / WORLD SCENE> using docs/MEMORY_POLISH_GUIDE.md and its
current memory README. Inspect the live scene and existing components first.

Keep the established memory identity, core landmarks/activities, personal text,
zone order, shared framework and two-player exploration intact. Improve the
design, layout, aesthetics, effects and atmosphere within the assigned scope.

Treat interiors/social places as selective evocative vignettes. Preserve visible
ivory gaps and porous boundaries. Enrich natural areas through appropriate
layering and variation while retaining paths, clearings, views and local ecology.

Owned files/scope: <MEMORY / ZONES / LOCAL RESOURCES / SCRIPTS / TESTS>.
Shared-system owner or dependencies: <IF APPLICABLE>.
Priority opportunities: <OBSERVED ISSUES OR LEAVE TO RUNTIME INSPECTION>.

Capture a baseline, implement the highest-impact improvements, verify actual
player routes/recall/interactions, and provide matching before/after captures.
Report changes, checks and shared follow-ups. Keep unrelated work intact.
```

## 7. Acceptance criteria

- The place remains recognizable and retains its established content and order.
- Each important gameplay view has a clear subject, readable players and useful
  approaches; scenery does not bury fragments or activity controls.
- Richness is concentrated and varied. Natural zones gain appropriate depth;
  intentionally open or minimal places retain that character.
- The ivory void is visibly connected to the composition through gaps, porous
  boundaries or transitions. Nonessential room shells/floor coverage do not seal
  the scene off from it, and missing world detail does not look accidental.
- Light, material finish, scale and ground contact support a coherent painted
  world. No conspicuous patch seams, clipping, accidental platform walls or noisy
  fine detail spoil the normal camera view.
- Motion and effects add life and meaning while preserving quiet areas. Recall,
  foliage response and requested guidance continue to use the shared systems.
- Both players can enter, pass, approach activities and return safely. Physical
  support remains valid even where visible scenery dissolves into ivory.
- Evidence includes actual gameplay captures and a concise change/verification
  report. A global component-count increase or a distant beauty shot is not the
  acceptance target.

## 8. Visual references and earlier evidence

Useful lessons from the original reference comparison:

- [Dordogne](https://www.focus-entmt.com/en/games/dordogne): broad watercolor
  masses, intentional surface strokes and selective painted boundaries.
- [GRIS](https://www.conradroset.com/gris/): silhouettes, value grouping, controlled
  color relationships and expressive negative space.
- [The Gardens Between](https://www.thegardensbetween.com/): composed miniature
  places, readable progression and meaningful everyday objects.
- [Tiny Glade](https://store.steampowered.com/app/2198150/Tiny_Glade/): tactile
  contact, cohesive environmental layering and convincing light.

These are visual lessons, not a mandate to copy their rendering technology or
change Evermore's identity. First Meeting's November 16
[camera study](previews/first-meeting-visual-review-camera-study.jpg),
[walkthrough](previews/first-meeting-visual-review-walkthrough.gif),
[house view](previews/first-meeting-visual-review-house.jpg) and
[arcade view](previews/first-meeting-visual-review-arcade.jpg) remain examples of
the review method. They are historical evidence for that scene, not a completed
all-memory audit or universal camera/palette/density prescription.
