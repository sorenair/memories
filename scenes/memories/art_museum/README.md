# Minneapolis Institute of Art — December 4, 2025

The third authored timeline memory. Recall **Minneapolis Institute of Art — DEC 4, 2025**, or run `scenes/world/art_museum_world.tscn` with F6.

This is an interpreted museum visit, organized as four remembered places in the white void. The entrance follows the supplied photograph's six Ionic columns, volutes, triangular pediment, and broad steps. It contains **only the portico**, with open space behind it: no building wings or enclosing museum exterior.

## Route and zones

| Zone scene | Shared visit | Main scenery |
| --- | --- | --- |
| `entrance_zone.tscn` | Forecourt → through the gate → marble gallery behind it | Isolated portico, continuous shallow steps, cold exterior wind |
| `marble_zone.tscn` | Central gallery; fork left to paintings or right to the busy room | Contrapposto athlete, draped figure, portrait bust; cool daylight wash |
| `paintings_zone.tscn` | Look at paintings on separated wall fragments | Van Gogh, Rembrandt, and Monet reproductions, muted frames, a gallery bench, warm floor traces |
| `crowded_room_zone.tscn` | Find each other in a busier room | 34 existing painterly visitors, Jade Mountain, Kii Tokugawa armor, The Veiled Lady, reserved walking aisles, quiet murmur |

Each is a standard **MemoryZone** with Scenery, one Fragment, and its own ambient bed. Their order under **Zones** defines the requested guidance sequence. Every note is explicitly placeholder text; no personal anecdotes or exact exhibition itinerary have been invented.

The plan is a **fork**, rather than a line of rooms. From arrival, walk north through the portico's central opening and down its rear steps into the marble gallery at `(0, 0, -10)`. Its left branch leads to paintings at `(-14.5, 0, -16)`; the right branch leads to the crowded room at `(14.5, 0, -16)`. The two wings are separated by open void. To move between them, return through the sculpture hub. Requested guidance follows that same route and works whichever branch you explore first.

One **MemoryPlatform** under `Environment/MuseumFloor` supplies the connected floor and a single outer safety rim. Narrow paving traces reveal the passages without filling the negative space. The portico's steps and landing are one extruded profile, with one matching **StairRamp** floor collider. There are no overlapping tread slabs, hidden sloping wedges, or paving laid across the steps. Column gaps, sculpture approaches, and the crowd's central, rear, and entrance-turn aisles leave room for both explorers.

Arrival is `(0, 0.04, 6)`, with the partner's usual supported 1.2 m X offset. The camera starts at orthographic **3.5**, matching First Meeting, and stays close for the first **1.5 m** along the path. It then eases open between local Z **4.5** and **1.5**, reaching the portico's **9.5** view centered on **Environment/EntranceFocus**. Standing still does not trigger the reveal. Crossing behind the columns returns to the close view, as does walking back to the start of the path. Passages use **3.5** and exhibits ease up to **4.8** so the artwork and player fit together. Tune **Portico Reveal Start / End** on CameraRig to move the approach transition. Gallery **ViewingFocus** markers in the `museum_camera_focus` group define the three exhibit moments. Framing always follows the local explorer, with fixed yaw and frame-rate independent smoothing.

## Reuse and new components

Planning searched the current library before adding geometry:

- Reused **MemoryScene / MemoryZone / MemoryPlatform**, the shared world, fragments, interaction and requested brushstroke guidance, mixer, and LAN character/presence behavior.
- Reused **PainterlyPaving** for faint floor/path fragments, **PainterlyLightWash** for quiet gallery light, and **PainterlyCrowd** for the occupied room. Visitors retain existing batched GPU idle poses and chunked static hitboxes; no new crowd simulation was added.
- The museum-specific models are reusable **MuseumPortico**, **MarbleStatue**, **MuseumHighlight**, and **GalleryDisplay** scenes under `components/scenery/museum/`. They inherit the stadium's existing batched scenery foundation and First Meeting's geometry builder/material language. A gallery display can be a framed painting partition or a bench. **MuseumHighlight** reuses the existing **BoulderGeometry** generator for the irregular jade relief; its other variant is the seated armor. The existing statue component adds the veiled bust variant.

## Editing

Open the individual zone scenes:

- **Fragment → Note Title / Notes**: replace that zone's placeholder heading and pages.
- **Entrance / Scenery / Portico → Stone Color**: portico pigment. Its procedural geometry and stair layout live in `painterly_museum_portico.gd`.
- **Marble / Scenery / Athlete, DrapedFigure, PortraitBust**: choose **Figure**, marble color, placement, or rotation.
- **Paintings / Scenery / OliveTrees, Lucretia, Grainstack**: **Artwork**, **Canvas Size**, **Wall Color**, placement, and rotation. These canvases appear only in the painting zone.
- **CrowdedRoom / Scenery / JadeMountain, KiiTokugawaArmor, VeiledLady**: exhibit/figure variant, placement, rotation, and pigment seed. These are original stylized 3D studies of the collection highlights, rather than more canvas partitions.
- **CrowdedRoom / Scenery / Visitors**: count, seed, clothing palette, poses, motion, and **Empty Areas**. Preserve the three reserved aisle rectangles when increasing the population.
- Zone roots: **Ambience Stream**, volume, bounds, and blend distance. Shared **Audio** on `art_museum.tscn` owns the fragment chime and an empty music slot.
- `Environment/MuseumFloor → Custom Outline`: the complete connected walking surface.
- `Environment/Guidance`: safe fragment-to-fragment route definitions. Move their waypoints with the floor/scenery.
- **CameraRig** in the world wrapper and `scripts/museum_camera.gd`: near/wide framing. **Environment/EntranceFocus** controls the entrance view.

The indoor beds are original synthesized placeholders without intelligible speech; regenerate them with `python3 tools/generate_museum_audio.py`. Audio remains local to each explorer and uses the shared Ambience/SFX mixer and scene fades. Scenic visitors, notes, and activity states remain local, consistent with the current LAN framework.

## Artwork and reference provenance

The canvas images are Mia's public-domain collection reproductions, with compact metadata retained beside them in `components/scenery/museum/art/`:

- Vincent van Gogh, [Olive Trees, 1889](https://collections.artsmia.org/art/1218/olive-trees-vincent-van-gogh).
- Rembrandt van Rijn, [Lucretia, 1666](https://collections.artsmia.org/art/529/lucretia-rembrandt-van-rijn).
- Claude Monet, [Grainstack, Sun in the Mist, 1891](https://collections.artsmia.org/art/10436).

Metadata comes from [Mia's collection repository](https://github.com/artsmia/collection); images come from its [image CDN implementation](https://github.com/artsmia/art/blob/master/src/image-cdn.js): `0.api.artsmia.org/800/1218.jpg`, `4.api.artsmia.org/529.jpg`, and `6.api.artsmia.org/800/10436.jpg`. The artworks supply museum identity, not a claim that these particular works were viewed on the memory's date. The marble figures are original stylized classical studies, not scanned or labeled replicas of specific Mia objects. The portico reference is the user's attached entrance photograph.

The crowded room's three different sculptural exhibits were selected from [Mia's own Must-See Artworks guide](https://new.artsmia.org/programs/activities-for-self-guided-groups/must-see-artworks-at-mia), with collection photos used to guide their silhouettes:

- China, [Jade Mountain Illustrating the Gathering of Scholars at the Lanting Pavilion, 1790](https://collections.artsmia.org/art/4324): pale jade peaks, carved cypresses, paths, and a miniature pavilion.
- Japan / Saotome Iechika, [Red-and-blue-laced two-plate cuirass armor from the Kii Tokugawa family, mid 17th century](https://collections.artsmia.org/art/108860): seated lacquer armor, muted red and blue lacing, upright gold helmet crest, and fur boots.
- Raffaele Monti, [Veiled Lady, c. 1860](https://collections.artsmia.org/art/12092): marble bust with a flower wreath and carved veil, added as a variant of the existing statue component.

These objects are deliberately gathered into one remembered room. This is an artistic composition, not a reconstruction of the museum's actual gallery locations or a verified December 2025 display list. No new exhibit images are shipped; the three new works are code-authored opaque meshes.

## Checks and previews

```sh
godot --headless --path . --script tests/art_museum.gd
godot --path . --windowed --resolution 1600x738 --script tests/art_museum.gd -- --capture
```

The test walks the actual explorer through the portico and all four zones in both directions, checks both stair flights against their visible tread heights, safe spawns, guidance through the gate and fork, fragments, the crowd aisles, close/wide camera changes, and the dated third timeline entry. The updated two-process `tests/lan_multiplayer.gd` also visits the museum with both avatar choices and verifies partner motion and disconnect behavior.

[Overview](../../../docs/previews/museum-overview.png) · [Arrival](../../../docs/previews/museum-entrance.png) · [Portico reveal](../../../docs/previews/museum-portico.png) · [Sculptures](../../../docs/previews/museum-marble.png) · [Paintings](../../../docs/previews/museum-paintings.png) · [Crowded room](../../../docs/previews/museum-crowded-room.png)
