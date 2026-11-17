# Design documentation

Start with the [memory design guide](MEMORY_DESIGN_GUIDE.md) when planning or building a new memory. It covers the shared scene framework, composition, style, navigation, fragments, sound, animation, and review workflow using First Meeting and Football as references.

For the refinement pass over existing memories, use the [memory polish guide](MEMORY_POLISH_GUIDE.md). It covers lush natural scenes, selective interior vignettes, composition and void balance, shared-system ownership, and copyable agent assignments while preserving each memory's core content.

```text
docs/
├── MEMORY_DESIGN_GUIDE.md      reusable design and implementation standard
├── MEMORY_POLISH_GUIDE.md      all-memory refinement and agent delegation
├── previews/                  rendered stills and animated previews
└── concept-art/               concept images and their source prompts
```

For implementation details, see [zone authoring](../scenes/memories/README.md), [First Meeting](../scenes/memories/FIRST_MEETING.md), [Football in the snow](../scenes/memories/snowy_stadium/README.md), [Minneapolis Institute of Art](../scenes/memories/art_museum/README.md), [Christmas market](../scenes/memories/christmas_market/README.md), [New Year's Eve](../scenes/memories/new_years_eve/README.md), [Como Conservatory](../scenes/memories/como_conservatory/README.md), [Postcard Cabin](../scenes/memories/postcard_cabin/README.md), [Mifflin Block Party](../scenes/memories/mifflin/README.md), [Graduation](../scenes/memories/graduation/README.md), [Tokyo](../scenes/memories/tokyo/README.md), [Northern Vietnam](../scenes/memories/northern_vietnam/README.md), [Central Vietnam](../scenes/memories/central_vietnam/README.md), [Southern Vietnam](../scenes/memories/southern_vietnam/README.md), [Bean and Bear Lakes](../scenes/memories/bean_bear/README.md), [Vineyard](../scenes/memories/vineyard/README.md), [First Sail](../scenes/memories/first_sail/README.md), [Labor Day in Colorado](../scenes/memories/colorado/README.md), [Duluth in the Fall](../scenes/memories/duluth_autumn/README.md), and [audio](../audio/README.md).

Preview filenames group related studies: `first-meeting-*`, `snowy-stadium-*`, and component families such as `snow-*` or `crowd-*`. Some images document earlier iterations; inspect the current scenes before copying a layout. New capture scripts should write to `res://docs/previews/` so the documentation root stays clear.
