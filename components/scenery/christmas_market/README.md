# Christmas market scenery

`decorated_pine.tscn` combines the existing procedural Layered Pine with festive-light trimming. Scale the composition to vary the tree without separating its ornaments. Its pine parameters and light-trim parameters remain editable in the scene.

`painterly_market_stage.tscn` is a compact wooden acoustic stage with a partial snowy rear canopy, garland, speakers, and three musicians: guitar, fiddle, and upright bass. The open canopy preserves the view from the game's elevated camera. **Performance Strength** adjusts restrained body sway, strumming, and bow movement. Each performer has two connected arms with fixed upper-arm/forearm lengths. Fretting, strumming, plucking, and bowing use instrument-specific wrist positions; the forearms follow the hands and the bow slides along the violin’s string plane. Segment meshes are baked once and moved through node transforms, with no per-frame mesh rebuilding. Generated artists explicitly disable physics interpolation for these visual-only poses. The stage floor is scenic and blocked to explorers; keep an open listening area in front.

The stage has no independent audio player. Assign the performance stream on the memory's existing **Audio → Music Stream**, so it uses the standard Music bus and transition fade alongside zone ambience and fragment SFX. Its `excludes_ground_point` method keeps ground snow out of the wooden deck.

`market_geometry.gd` shares wreath/garland details and recolors the crowd's cached body/head geometry. Market huts and the live stage reuse it, along with First Meeting's builder and the existing scenery shader. None of these props change shared crowd meshes or materials.

See the [two-zone market memory](../../../scenes/memories/christmas_market/README.md) for the composition, sound, authoring, and validation.

Check arm/instrument clearance through a complete playing cycle with `godot --headless --path . --script tests/market_performers.gd`. Add `-- --capture` with the normal renderer to save the [performer close-up](../../../docs/previews/christmas-market-performers.png) and inspect four phases. The check compares real sleeve paths against instrument mesh triangles, including sleeve width, and verifies connected elbows/wrists at maximum animation strength.
