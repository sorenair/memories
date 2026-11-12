# Persistent LAN pairing

`LanSession` is an autoload, separate from the current scene. The first main-menu opening starts hosting automatically; subsequent openings respect the current role, connection, or explicit disconnect. Host/Join remain main-menu actions, and pairing never changes a player's chosen memory or blocks navigation. One host and one guest use ENet on UDP port 24680. The host keeps listening when a guest leaves; the guest falls back to solo if the host disconnects. Either can disconnect explicitly from the active Host/Join button on the main menu.

Each world calls `enter_memory(memory.memory_id)` and retains the returned visit token. `_exit_tree` calls `exit_memory(id, token)`. Every memory needs a unique, stable `memory_id`; catalog order is not transmitted. A token check prevents an older world's teardown from clearing a newer world's presence. Changing character on the main menu also advertises the current avatar.

Reliable presence messages announce memory ID, visit revision, and avatar. Empty memory means a menu. `shares_memory()` is true only with an accepted partner and a nonempty matching memory ID. Worlds listen even when entered offline or while a join is pending. They create a replica only after a valid pose in the same memory arrives, and immediately disable its collision and detach it from active presence when the partner leaves that memory or disconnects. Its visual finishes dissolving at the last received pose before being freed. No LAN labels are added over gameplay in separate memories or solo play.

Pose updates remain 20 Hz with buffered 100 ms playback in `remote_motion.gd`. Unreliable ordered packets carry memory ID, sender visit, and recipient visit. The receiver validates all three plus peer identity and finite pose values. Old packets cannot resurrect a departed partner or seed a later visit with stale positions. Each new partner visit starts a fresh playback buffer. Shared presence synchronizes characters and their motion/contact only; local scenery, interactions, notes, and recollection keep their existing behavior.

## Remote arrival and departure

`remote_presence.gd` uses the same `solid_recall.gdshaderinc` height scan and cream-white edge as recalled solid scenery. After the first valid pose, a remote avatar resolves upward over 1.25 seconds, with its contact shadow fading in. On memory exit or connection loss, the scan reverses over 0.95 seconds and the shadow fades out. Disconnecting mid-arrival reverses from the current progress.

The same effect wraps remote and local explorers. Skinned surfaces on both character variants receive private temporary paint materials; finishing arrival restores their authored materials. Normal movement continues through the existing snapshot buffer while arriving. Departure clears that buffer and collision immediately, stops walking, renames the replica away from `Partner`, and lets its own effect free it. A rapid new visit can spawn a fresh `Partner` while an older visual is dissolving. Neither old snapshots nor the old effect's cleanup can affect the new replica. Freeing the whole world also frees its pending effects. Local Recall uses the same scan instead of a drop-in; `memory_arrival.gd` owns the input lock and paper veil. Local departure retains the player until navigation completes, while the reverse scan is also triggered on observers by announcing memory exit at its start.

Animation times live at the top of `remote_presence.gd`; they do not use proximity, since remote presence itself triggers the effect.

Protocol version 4 is incompatible with the earlier host-selected-memory flow. Both devices must use this build. Tested locally with two game processes; physical-device networking and performance still need device verification.

The connection row uses one field in both modes with identical metrics and fixed left/right icon slots. Host shows a plain read-only address with no underline or arrow; Join makes that same field editable and fades in a connect arrow. Its hidden slot stays reserved in Host, keeping the row dimensions fixed. Mode labels have no hover effects or underline; active/pressed text is dark and inactive text is muted. A pair of rings gently gathers into an interlocking symbol when a partner is connected. Routine waiting/connected strings are kept out of the menu; connection failures remain visible.

## Checks

```sh
godot --headless --path . --script tests/main_menu.gd
godot --headless --path . --script tests/lan_menu.gd
godot --headless --path . --script tests/local_presence.gd
godot --headless --path . --script tests/remote_presence.gd
godot --path . --script tests/remote_presence.gd -- --capture
# Start these in separate terminals, host first:
godot --headless --path . --script tests/lan_multiplayer.gd -- host
godot --headless --path . --script tests/lan_multiplayer.gd -- guest
```

The two-process test covers independent demo/First Meeting choices, matching First Meeting, guest exit to menus, stale pose injection, matching Snowy Stadium and the art museum, character changes, explicit guest disconnect/reconnect, live partner walking, host loss without leaving the memory, and delayed/lost-packet interpolation. Solo Recall and return behavior are also covered by `tests/memory_lane_smoke.gd` and `tests/timeline_return_smoke.gd`.

The remote-presence check covers material isolation/restoration, first-pose visibility, avatar changes, reverse playback, an interrupted arrival, and overlapping visits. Render captures are saved to `/tmp/remote-presence-{hidden,arriving,present,departing}.png`. The LAN test resolves timeline entries by scene path so new catalog entries do not change its intended destinations.
