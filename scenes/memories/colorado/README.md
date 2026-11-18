# Labor Day in Colorado · September 6, 2026

Three connected zones follow **Boulder's Flatirons → Quandary Peak summit →
Rocky Mountain National Park forest lake**. Recall from the timeline between First
Sail and Duluth, or run `res://scenes/world/colorado_world.tscn` with F6. Terrain
and distances are compressed for exploration. The lake is unnamed and all three
notes remain placeholders.

## Composition and routes

- **Flatirons:** A close approach through tawny grasses, dry blooms and scattered
  sandstone opens onto three sloping formations. Smaller angled shelves tie their
  toes into the pines and field. **FieldWalk** leads to the fragment. **FieldExit**
  fades into a gap where successive outcrops, low grasses and the first gray
  rocks of the summit lead the turn. The hidden **ToSummit** curve connects both
  ends for floor authoring and requested guidance.
- **Quandary:** The ascent cuts through a cluster of angular granite blocks.
  Broad faces, buried outcrops and loose scree mark the turns. The continuous
  bedrock ledge uses the same alpine stone palette and face lighting as the
  surrounding boulders. Three goats stand on the open saddle at **Y = 3.6**.
  The far ledge rolls down into the shore approach.
  **SummitClimb** and **ToLake** give **QuandaryTerrain** its grades and act as
  guidance curves. The same triangulated rock surface supplies the visible
  mountain and walking collision.
- **Forest lake:** Pines of several heights, pale aspens and smaller understory
  form groups around an irregular cove. A single connected bank wash underpins
  the planting and shore stones. **LakeshoreWalk** ends in an open pocket beside
  the seven-elk herd and a nearby cow. Both goats and elk use the existing planted
  idle poses. The water has a slower surface treatment and a low line of foam
  shaped by the cove and shore stones.

The memory reuses the existing [surface paths](../../../components/groundcover/paths/README.md),
[Flatirons](../../../components/scenery/flatirons/README.md),
[rock clusters](../../../components/scenery/rock_clusters/painterly_rock_cluster.tscn),
[goats](../../../components/animals/mountain_goat/README.md), and
[elk](../../../components/animals/elk/README.md). Zone-local palettes give the
meadow, summit and lake their separate colors. The shallow washes use the
existing sand component with relief, footsteps and collision disabled.

## Authoring

Edit **Fragment → Note Title / Notes** in each zone scene:

| Zone | Placeholder title |
| --- | --- |
| Flatirons | Beneath the Flatirons |
| Summit | On Quandary Peak |
| Forest Lake | By the forest lake |

The [camera script](../../../scripts/colorado_camera.gd) holds size **4.8**
through the field, foothill gap, mountain ascent and descent, and the forest
approach. Near each fragment it eases into a fixed scenic frame at **29** for the
Flatirons, **8.8** for the goats and **16.5** for the lake and herd. A slightly
larger exit area holds the wide view while players move around the viewpoint.
Review the camera focus and note's screen space together when moving a viewpoint.

Edit **Ambience Stream** on each zone root to replace its placeholder recording.
The zone beds loosely overlap at transitions, with field wind, stronger summit
wind and a quieter forest bed. The memory uses the shared Audio node for music
and fragment SFX. Distant scenery recalls from reachable anchors. Foliage reacts
to both explorers, and animal idles and note reading run locally.

**ColoradoFloor** is the finite, hidden support for level walking, including the
ivory gap. On the mountain, edit the grades in the two Curve3D resources and the
outer footprint on **QuandaryTerrain**. The terrain rebuilds when a curve changes.
Keep the curves level at joins with the ivory floor. If editing **ToSummit**,
align the short **FieldExit**
surface and the loose wayfinding scenery to its revised route. Update the water
outline, shore obstacles and ground exclusions together when reshaping the cove.
After changing a path footprint, the mountain outline, or a zone position, rebuild the floor outline:

```sh
godot --headless --path . --script tools/rebuild_colorado_floor.gd
```

## Validation and views

```sh
godot --headless --path . --fixed-fps 60 --script tests/colorado_memory.gd
godot --path . --fixed-fps 60 --script tests/colorado_memory.gd -- --capture
```

The walkthrough checks grounded travel in both directions, support on both
sides of the trail, requested guidance, all three notes, crest and wildlife
framing, recall, ambience and timeline avatar selection. Run paired
`-- host` and `-- guest` processes on the local machine to check arrival and
replicated walking on isolated UDP **24795**.

The [matched before and after views](../../../docs/previews/colorado-polish-comparison.jpg)
use the same inspection camera and fully recalled scenery on both sides.
Gameplay captures show the revised follow camera at the
[field arrival](../../../docs/previews/colorado-memory-field-arrival.png),
[Flatirons reveal](../../../docs/previews/colorado-memory-flatirons-field.png),
[foothill gap](../../../docs/previews/colorado-memory-foothill-gap.png),
[climb](../../../docs/previews/colorado-memory-quandary-climb.png),
[summit](../../../docs/previews/colorado-memory-quandary-goats.png),
[descent](../../../docs/previews/colorado-memory-ridge-descent.png), and
[lake](../../../docs/previews/colorado-memory-forest-lake-elk.png).
Captures used Godot's Mobile renderer on macOS.
