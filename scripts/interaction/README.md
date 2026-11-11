# Shared in-game interaction

Each world inherits an `InteractionController` from `memory_world_base.tscn`. It uses the local Explorer, selects the nearest available target, and drives the bottom-right action circle. The circle is faint gray at rest and becomes opaque when a target is available. Touch, mouse click, and **E** use the same request path. The joystick and action circle support independent fingers.

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

`can_interact` is a side-effect-free availability check; include range, cooldown, consumption, and any target-specific restrictions. `try_activate` rechecks those conditions and returns whether the action succeeded. The controller rechecks on release and rejects a changed target, so moving away while holding the button cannot activate something else.

The controller exposes `target`, `target_changed(target)`, `interaction_requested(target, actor)`, and `interaction_performed(target, actor)`. Signals provide selection/request/success notifications; the controller calls `try_activate` itself. UI or effects can observe the signals without implementing target selection again. `request_interaction()` also allows other input sources to use the same gate.

Targets are scoped to the current world and viewport; hidden, unprocessable, and unavailable nodes are excluded. Arrival/return movement locks block input. Modal presenters can join `interaction_blockers` and implement `blocks_interaction() -> bool`. Fragment notes use that gate, so their Close/Continue controls retain touch priority. Existing direct fragment tapping continues to work.

Validate with `godot --headless --path . --script tests/interact_button.gd`. This exercises the real SummerFragment in the foliage demo, its note queue, touch cancellation, range changes, joystick multitouch, keyboard input, and a separate generic interactable.
