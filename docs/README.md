# Design documentation

Start with the [memory design guide](MEMORY_DESIGN_GUIDE.md) when planning or building a new memory. It covers the shared scene framework, composition, style, navigation, fragments, sound, animation, and review workflow using First Meeting and Football as references.

```text
docs/
├── MEMORY_DESIGN_GUIDE.md      reusable design and implementation standard
├── previews/                  rendered stills and animated previews
└── concept-art/               concept images and their source prompts
```

For implementation details, see [zone authoring](../scenes/memories/README.md), [First Meeting](../scenes/memories/FIRST_MEETING.md), [Football in the snow](../scenes/memories/snowy_stadium/README.md), [Minneapolis Institute of Art](../scenes/memories/art_museum/README.md), and [audio](../audio/README.md).

Preview filenames group related studies: `first-meeting-*`, `snowy-stadium-*`, and component families such as `snow-*` or `crowd-*`. Some images document earlier iterations; inspect the current scenes before copying a layout. New capture scripts should write to `res://docs/previews/` so the documentation root stays clear.
