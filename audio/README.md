# Memory audio

Each memory inherits an **Audio** node from `scenes/memories/memory_base.tscn`. It owns shared music, optional global ambience, and a bounded effect pool. Each **MemoryZone** owns its local ambience, blended around the local explorer rather than the elevated camera. See [zone authoring](../scenes/memories/README.md).

## Mixer

The project's bus layout is `audio/default_bus_layout.tres`. Open Godot's **Audio** bottom panel and load this layout to adjust or solo channels while designing the mix.

| Bus | Content | Sends to |
| --- | --- | --- |
| Master | Overall output, initially −3 dB, with a −1 dB peak limiter | Device |
| Memory | Shared fade during entry/return; leave this fader to the transition code | Master |
| Music | Background soundtrack | Memory |
| Ambience | Continuous environmental bed | Memory |
| SFX | Band notes, fragment chimes, other gameplay effects | Memory |
| UI | Interface sounds, independent of the memory fade | Master |

Category buses start at 0 dB. Balance a particular track with its player-level dB setting; use a bus to change the whole category. The limiter is a backstop for overlapping peaks, rather than a substitute for balancing clips. This uses [Godot's native audio buses](https://docs.godotengine.org/en/4.4/tutorials/audio/audio_buses.html), so existing AudioStreamPlayer nodes can participate just by choosing their **Bus**.

## Choose a memory's tracks

1. Open the memory scene and select **Audio** to assign **Music → Music Stream**, its volume, and loop setting.
2. Open a zone scene, such as `scenes/memories/first_meeting/house_zone.tscn`, and select its root. Assign **Ambience Stream** and tune **Ambience Volume dB**, **Ambience Size**, and **Ambience Blend Distance**.
3. The shared **Audio → Memory Cues → Fragment Sound** and **Fragment Volume dB** control the optional cue for all of the memory's fragments.
4. Blank clips are silent. For an additional non-local layer such as weather, **Audio → Global Ambience (Optional)** retains the whole-memory bed.

Zone ambience blends by position and stops outside its bounds after fading out. Overlapping zone weights are normalized, so approaching the arcade doesn't simply double the ambient gain. **Ambience Response Seconds** smooths changes. The world connects the local explorer to this mixer automatically; the partner's position doesn't affect what your device hears.

First Meeting's House zone assigns an original synthesized 20-second autumn wind loop, and Arcade assigns a quiet cabinet/room hum. A fragment chime is shared by the memory. Music remains empty for your chosen soundtrack. Regenerate these replaceable placeholder assets with `python3 tools/generate_memory_audio.py`. The four mechanical-band instrument clips use **SFX**.

Pinball adds launch/bumper/result cues, and the punching bag adds a timed impact and result cue. Each machine's **Sound → Sound Volume dB** balances it within SFX. Their small component-owned cue banks also work in standalone previews and are freed on regeneration. Regenerate these original clips with `python3 tools/generate_arcade_audio.py`.

Playback auto-starts with a 1.2-second fade. Set **Autoplay** off to start it from code. The continuous beds support imported WAV, Ogg Vorbis, and MP3 streams. Playback clones their loop settings so shared imported clips aren't mutated; WAVs without loop points loop over the whole clip, while authored loop points are preserved. Supply seamlessly edited source audio for a seamless bed; enabling Loop cannot remove a discontinuity in the recording. For long tracks, Ogg Vorbis avoids large uncompressed WAVs; see [Godot's audio import guide](https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_audio_samples.html).

## Trigger effects and change layers

From a script within a memory:

```gdscript
var audio: MemoryAudio = memory.get_audio() # Or get_node("Memory/Audio") from the world.
audio.play_sfx(preload("res://path/to/effect.wav"), -10.0)
audio.play_ui(preload("res://path/to/click.wav"), -16.0)
audio.play_music(preload("res://path/to/track.ogg"), -14.0, true)
audio.play_ambience(preload("res://path/to/room.ogg"), -18.0, true)
```

Calls to `play_sfx` / `play_ui` can overlap and never replace the music/ambience players. **Max One Shots** defaults to eight simultaneous voices shared by those calls. Idle voices are reused; if all are busy, the oldest is replaced. For these calls, standard WAV/Ogg/MP3 streams are forced to one-shot playback even if the imported clip loops. The band's separate four players still allow two voices per instrument.

`play_music` / `play_ambience` replace only their own shared layer immediately; passing `null` stops that layer. The latter is an optional global bed added alongside zone ambience. `start()` starts the authored shared beds, enables zone mixing, and begins the entry fade. `stop()` stops shared beds, all zone ambience, and pooled cues; independently owned component players, such as the band, remain under their components' control.

Future settings controls can call the global mixer:

```gdscript
AudioMixer.set_level(&"Music", 0.5) # Linear 0–1 amplitude, not decibels.
AudioMixer.set_muted(&"SFX", true)
var current_level := AudioMixer.get_level(&"Music")
```

These category settings persist across scene changes within the running app. They are not saved across app restarts. Set authored defaults in the bus layout. The Memory fade leaves category levels and mute choices intact.

## Lifetime and LAN

Audio players belong to their memory. Return-to-timeline fades Music, Ambience, and SFX together over the existing 0.45-second visual transition, then freeing the scene stops all of its playback, including looping beds and band notes. Re-entering starts fresh; the global mixer cancels any stale transition tween. The UI bus does not participate in that fade, though UI cues owned by a memory are still freed with it.

Playback is local on each device. Each LAN player gets the shared music and blends zone beds around their own explorer, and hears locally triggered interactions; the movement protocol does not broadcast band presses or audio events. The framework neither streams audio over the network nor doubles events on the other device.

## Verify

```sh
godot --headless --path . --script tests/memory_zones.gd
godot --headless --path . --script tests/memory_audio.gd
godot --headless --path . --script tests/band_interaction.gd
```

The audio integration check runs the real First Meeting scene: simultaneous looping beds, all four band notes, fragment cues, bounded overlapping effects, actual mixed Master samples, independent volume/mute controls, and cleanup/re-entry through the timeline. Physical speaker/headphone balance still needs listening on target devices.
