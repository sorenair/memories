# Painterly stadium scenery

Reusable editor-previewable components use First Meeting's `arcade_geometry.gd` SurfaceTool builder: vertex-painted boxes, softened profiles, rods, and small rounded figures. Field and stands each produce one batched mesh without real-time shadow maps; the moving teams use six lightweight MultiMesh batches. Minnesota seat art uses the supplied logo texture on a curved, alpha-tested paint surface in the same mesh; field markings and text are baked geometry. `stadium_paint.gdshader` follows the house/arcade's broad pigment washes and soft stepped lighting, with a longer haze range for the stadium scale.

- **painterly_football_field.tscn**: art-scaled American football field, alternating muted turf bands, painted yard lines and hash marks, warm end zones, two yellow goalposts, and two animated teams. Exposes **Field Size**, **Turf Color**, **End Zone Color**, **Snow Coverage**, **Show Teams**, and **Animate Players**. `football_players.gd` samples individual routes, delayed pursuit, heading, bob and opposed leg strides every rendered frame. A carried football follows one runner. The editor keeps a static pose; runtime animation is cosmetic and requires no actor physics or network updates.
- **painterly_stadium_stands.tscn**: descending near bleachers, a distant horseshoe of terraces/crowd dabs, open stair aisles, fragmented roof trim, four floodlight masts, guardrails, and two upper-deck benches. Exposes **Seat Color**, **Concrete Color**, **Far Rows**, **Crowd Bounce Height / Speed**, and the shared pigment/seed controls.

The field's local X axis is the long axis, with its center at the origin. Default dimensions are 84 × 37.3 art-scaled meters, preserving a long football-field silhouette without requiring a full-size gameplay map. Change **Snow Coverage** to tune the irregular, domain-warped fractal snow drifts; **Paint Seed** changes their repeatable distribution. There is no animated sliding pattern or regular sine-wave snow mask; physical-looking drifts and footsteps are supplied by the existing snow component in the memory.

- **painterly_stadium_concourse.gd**: arrival landing with bench and rails, or a narrow connecting aisle when **Bridge Only** is enabled. The playable memory assembles these above one continuous custom-outline platform.

The stands use a field center at world Z=−26 and an upper cross-aisle at Y=10.5, Z=12. Two bench collision boxes occupy the rear of the viewing deck, with the left bench shortened to leave the connecting aisle open. The scene's separate **MemoryPlatform** supplies the walkable floor and a continuous safety rim matching the guardrails; decorative lower tiers and field are outside the walkable area. If changing the stands layout, move the deck platform, snow patches, section scenery, and camera transition markers with it.

The small crowd figures bounce gently in the vertex shader. Each figure has a seeded phase and pace stored in its UVs, shared by all its vertices so it moves as one solid shape. **Crowd Bounce Height** defaults to 0.14 m and **Crowd Bounce Speed** to 1.0; set the height to zero for a still crowd. Both controls update shader uniforms immediately without rebuilding the mesh. Crowd movement uses the existing single stands draw surface, with no extra nodes, CPU animation callbacks, physics, or mesh uploads per frame. The movement remains within the stands mesh's existing vertical bounds.

Generated children remain internal; scenes serialize authoring parameters only. **Regenerate scenery** and exported-field changes rebuild the mesh, not its parent memory. The large scenery remains visible from the stands, rather than using proximity recall that would hide the distant field.

See [the playable stadium memory](../../../scenes/memories/snowy_stadium/README.md).

## Minnesota reference styling

Enable **Minnesota Branding** on the field/stands to add gold **MINNESOTA** wordmarks in both maroon end zones, a traced midfield M, a large seating-level M, and upper-bank MINNESOTA lettering. The snowy stadium zone enables both and assigns the reference's maroon/gold palette. The end-zone text automatically fits the field width.

`minnesota_marks.gd` contains contours traced from the user's supplied M. Its original PNG is retained at `art/minnesota_m_reference.png`. The detached registered-trademark glyph is outside the painted mark's crop. Field geometry uses layered contours; the seating mark follows a finely tessellated curve with the supplied image so broad polygon triangles cannot sink into the terraces. Wordmarks are built from bold TextMesh glyphs into the same vertex-painted batch.

Every light bank has an independent basis aimed from its lamp center inward and downward toward midfield. The mast remains vertical; the board and all emitting faces share the rotated basis.

`tests/stadium_styling.gd` checks the real mesh for both end-zone wordmarks, the midfield/seating marks, reference colors, and all four lamp banks' inward-facing emitting geometry.

Run `godot --path . --windowed --resolution 1000x750 --script tests/stadium_crowd_render.gd` for the rendered crowd check. It compares frames to verify visible independent motion, a still scene when height is zero, no motion outside crowd regions, and preservation of the mesh/node count and lack of CPU animation callbacks.
