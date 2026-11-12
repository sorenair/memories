# Painterly standing crowds

Instance `painterly_crowd.tscn` under a memory zone's `Scenery`. The origin is ground
level, the footprint uses local X/Z, and people face local +Z by default. Generated
meshes appear in the editor and rebuild when Inspector placement settings change.

Standing poses use quiet breathing, weight shifts, and small head/hand movements.
Each person has a stationary capsule hitbox by default, so explorers stop and slide
around people. There is no locomotion, interaction, seating, or per-person AI.
Leave walking space for Soren and Vivian using **Empty Areas**, an array of local
X/Z rectangles; body clearance is included automatically.

## Main controls

- **Count / Crowd Seed:** requested population and deterministic variation.
- **Layout / Footprint / Spacing:** a loose gathering or standing rows. If the
  requested count cannot fit, the generator caps it and reports an Inspector warning.
- **Person Scale / Height Variation / Build Variation:** independent proportions.
  The default scale is 0.95, close to the explorers with a range of adult heights.
- **Silhouette Variation:** independent leg length, waist/shoulder proportions,
  head scale, resting lean, and head tilt. Zero removes these extra deformations.
- **Facing Degrees / Facing Variation:** group orientation and individual turns.
- **Palette:** quiet neutrals, summer, autumn, winter, or four custom clothing colors.
  Skin and hair have separate editable palettes. Empty palette entries have defaults.
- **Softness:** mixes the memory's atmosphere into the figures to preserve the
  explorers' stronger contrast. The default is a light 0.06 wash, allowing the
  clothing palette to stay colorful. This is opaque shading, not transparent people.
- **Motion Strength / Speed:** subtle asynchronous GPU motion with planted feet.
  Zero strength freezes every figure; zero speed holds each person's idle pose.
- **Pose Mix:** Everyday Mix distributes all 12 poses; Quiet omits the social gestures;
  Social favors listening, conversational, and greeting poses. Garments and heads
  are selected independently of poses. **Pose Strength** blends arms toward neutral.
- **Hitboxes:** collision enabled, capsule radius/height, and physics layer. Capsule
  dimensions follow individual width/height; static bodies are grouped by chunk.
  Use Person Scale rather than non-uniformly scaling the component's Node3D.
- **Contact Shadows / Chunk Size / Visibility Distance:** rendering controls.

## Preview

Open `res://scenes/previews/crowd_preview.tscn` and run the current scene (F6). It
shows 16 loosely gathered people and 36 standing spectators alongside the actual
Soren and Vivian models. Escape closes the preview. This standalone scene does not
change timeline memories, LAN state, or the game's camera settings.

## Rendering budget

Eight garment silhouettes and eight head/hair styles are cached and
shared between all crowds. Bodies include sweaters, layered jackets/cardigans,
shorts, a scarf/coat, a skirt, wide trousers, and a folded hood. Hair includes a
side-swept crop, bob, curls, long hair, bun, ponytail, receding hair, and a cap.

Twelve independent poses include relaxed arms, folded arms, left/right hand on hip,
hands in pockets, hands clasped, hands behind back, hand to chin, hand over chest,
a conversational gesture, hand behind head, and a small greeting. Pose ids and a
fractional identity seed share one instance-custom channel. Two-joint vertex
transforms bend arms and hands; extra elbow rings preserve rounded joints. This
does not multiply the eight cached garment meshes or require skeletons. Feet also
have varied planted stances. Heads, outfits, and poses combine independently.

Clothing, skin, hair, and shoes share one opaque shader/material per crowd. Each
occupied spatial chunk uses at most eight body batches, eight head batches, and
one optional contact shadow batch, rather than a node, skeleton, or animation
player for every person.
Shuffled bags distribute styles/colors before repeating them; exact head/outfit
twins are avoided among close neighbors. Pose selection has its own shuffled bag.
Loose groups use spatially hashed random
placement with minimum spacing rather than a visibly jittered grid. All generation
uses a local seeded RNG; idle motion has no CPU update callback.

The meshes average approximately 1,500 triangles/person including the head.
`get_statistics()` reports population, batches including contact shadows, body/head
triangles, distinct head/outfit/pose combinations, pose count, and hitbox count.
The default chunk size is 6 m to amortize the extra modular variants. A 40-person
test uses 17 rendering batches. Crowd capacity is limited to 1,000 people per component.
This is an authoring ceiling,
not a measured phone budget; use small populations/chunks and profile on the target
device. Real-time cast shadows are disabled, and custom bounds include idle motion.

Hitboxes approximate the torso/head with a capsule, leaving narrow limbs free so
raised arms do not snag players. They stay planted while shader animation runs.
They add one CollisionShape3D per person and one StaticBody3D per occupied chunk,
not a separately simulated character. Disable Collision Enabled for distant,
non-traversable crowds. Rebuilding or reducing Count removes the old shapes.
`person_index_from_hit(hit.collider, hit.shape)` resolves physics ray hits to the
person's zero-based generated index (or -1 for another component).

Validation:

```sh
godot --headless --path . --script res://tests/crowd.gd
godot --headless --path . --script res://tests/crowd_collision.gd
godot --path . --script res://tests/crowd_render.gd --windowed --resolution 1600x1000
```

The render check writes `docs/previews/crowd-preview.png` and `docs/previews/crowd-detail.png`, checks
visible GPU motion, and verifies that zero strength remains still over time.
Physics checks cover individual ray hits, scaled capsules, removal/rebuild, and
the actual explorer stopping at and walking around a crowd member.

## Design references

The independent body/clothing/hair approach was informed by
[Quaternius's modular characters](https://quaternius.com/packs/ultimatemodularcharacters.html),
the pose vocabulary in [Background Posed Humans](https://quaternius.com/packs/backgroundposedhumans.html),
and [Didimo's independent crowd variation rules](https://developer.didimo.co/docs/crowds).
Geometry here is generated specifically for this project; these are references,
not imported character assets.
