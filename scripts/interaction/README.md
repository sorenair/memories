# Shared in-game interaction

Each world inherits an `InteractionController` from `memory_world_base.tscn`. It uses the local Explorer and activates components by tapping or clicking their visible geometry while in range. The nearest available target still drives outline emphasis, but a tap activates the component under the finger even when another is closer. The joystick and note controls receive input first; a second finger can tap a component while movement is held. The bottom-right HUD circle and **E** request **Find next fragment** through the separate `GuidanceController`.

To add an interactable, use a `Node3D` and register it at runtime:

```gdscript
func _ready() -> void:
    add_to_group(&"memory_interactables")

func can_interact(actor: Node3D) -> bool:
    return global_position.distance_to(actor.global_position) <= 2.5

func try_activate(actor: Node3D) -> bool:
    if not can_interact(actor):
        return false
    # Perform the interaction and update its availability here.
    return true
```

`can_interact` is a side-effect-free availability check; include range, cooldown, consumption, and any target-specific restrictions. `try_activate` rechecks those conditions and returns whether the action succeeded. The controller rechecks on release and rejects a changed target, so moving away while holding a tap cannot activate something else.

The controller exposes `target`, `target_changed(target)`, `interaction_requested(target, actor)`, and `interaction_performed(target, actor)`. Signals provide selection/request/success notifications; the controller calls `try_activate` itself. UI or effects can observe the signals without implementing target selection again. `request_interaction(component)` allows scripted requests through the same gate; omitting the argument uses the nearest available target. `pick_interactable(viewport_point)` returns a visible, in-range target for screen input.

Targets are scoped to the current world and viewport; hidden, unprocessable, and unavailable nodes are excluded. Arrival/return movement locks block input. Modal presenters can join `interaction_blockers` and implement `blocks_interaction() -> bool`. Fragment notes use that gate, so their Close/Continue controls retain touch priority. Fragment taps use this shared path in inherited worlds. Standalone fragment hosts without a controller retain the original orb picker.

Available targets receive a fading, depth-tested white silhouette. The nearest target gets a slightly brighter, gently breathing edge. Feedback uses cached mesh passes with constant pixel width and no screen-texture/extra-viewport effect. It stops drawing after fading out. `get_interaction_outline_meshes() -> Array[MeshInstance3D]` can restrict feedback to specific solid meshes; otherwise solid mesh descendants are discovered. Optionally, `get_interaction_outline_mesh(source: MeshInstance3D) -> Mesh` substitutes a simpler silhouette mesh, which lets arcade cabinets exclude small painted decorations. Transparent effect cards should implement `set_interaction_outline(amount: float, selected: bool)` to draw their own contour (as fragments do). `interaction_outline_selected_only() -> bool` restricts highlighting to the selected target, as used by the band's closely spaced buttons.

Screen picking tests the actual mesh triangles and rejects opaque physics occluders. Geometry is cached, and ray/triangle checks run only on press/release. Picking uses `get_interaction_tap_meshes()` if supplied, then `get_interaction_outline_meshes()`, otherwise solid mesh descendants. Transparent effect cards and small controls can instead implement both `get_interaction_tap_position() -> Vector3` and `get_interaction_tap_radius() -> float` (viewport pixels). Fragments expose their orb center and projected radius; the band's individual caps use generous touch targets. `get_interaction_occlusion_root() -> Node3D` can identify the enclosing component whose own collision shell should not block its child controls.

`Controls/InteractButton` exposes `available` (default false) and an independent `action_requested` signal connected to `GuidanceController`. Touch, click, or **E** sends one finite brushstroke from a snapshot of the player position to the first unfinished fragment in `MemoryScene.guidance_fragments`, an `Array[NodePath]` relative to the memory root. An empty array uses Zones child order, with scene-order discovery for legacy memories. The circle stays faint and disabled until the active stroke finishes at its destination; touch, mouse, E, and direct guidance requests cannot restart it. Hints never start automatically at scene entry or note completion. The circle is faint and disabled when no unfinished fragment remains. Its `input_gate` respects movement locks and modal notes. See [the brushstroke guide](../../components/guidance/brushstroke/README.md) for route authoring.

Validate with `tests/component_tapping.gd` (geometry, range, occlusion, cancellation, notes, and viewport-level multitouch), `tests/interact_button.gd` (guidance circle), `tests/first_meeting_guidance.gd` (memory guidance), and the pinball/punching-bag/band integration checks for actual memory components.
