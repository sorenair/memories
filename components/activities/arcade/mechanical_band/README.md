# Mechanical band

One reusable component with four separate targets: **Guitar, Kick, Snare, Piano**. Walk along the console and tap or click an individual cap while in range. Only the selected cap receives the white outline. Presses depress that cap and animate the corresponding pick, beater, stick, or piano keys/hammers. Different instruments can overlap; each mechanism has a short retrigger gate.

The inspector exposes **Interaction Range** (world meters from each front approach), **Volume dB**, **Animation Strength**, and **Preview band**, in addition to the shared size and paint controls. `get_button(index)` exposes each target, `play_instrument(index)` allows a custom interaction, and `instrument_played(instrument)` reports accepted presses. Existing placement anchors remain available.

The static body stays in one opaque batch. Small moving assemblies and caps reuse its painted material; frame callbacks stop at rest. Sounds are original synthesized mono WAVs with bounded polyphony. They use the local audio mix so the elevated orthographic camera doesn't attenuate them into silence. Regenerate them with `python3 tools/generate_band_audio.py`.

All four instrument players route to the shared **SFX** bus; **Volume dB** still sets this component's own level. SFX mixes alongside memory music and ambience and follows the memory's exit fade. See [memory audio](../../../../audio/README.md).

Validate with `godot --headless --path . --script tests/band_interaction.gd`; GPU previews use `tests/band_outline_render.gd`.
