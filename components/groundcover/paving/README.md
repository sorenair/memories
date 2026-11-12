# Painterly paving

Instance `painterly_paving.tscn` for a soft, remembered sidewalk or house approach. Local Z follows the path. First Meeting uses a rotated strip for the sidewalk and a short strip leading to the stairs.

The mesh has gently varied slab widths, rounded worn corners, slight misalignment, broad pigment washes, and quiet joints. A shared shader dissolves the sides and ends through large brush cells. A faint underpainting softens the seams. All visuals share one small mesh/material per strip, with no runtime frame callbacks or shadow passes.

Inspector controls: **Footprint**, **Slab Length**, **Paving Seed**, **Irregularity**, **Paving Color**, **End Fade** (negative/positive Z, in meters), **Edge Softness**, and **Breakup Size**. Set either fade length to zero for a solid connection to stairs or another strip.

Collision is a continuous shallow box, keeping arrival height and walking smooth while the visual pigment breaks apart. The shared groundcover exclusion API keeps the center clear and lets foliage overlap the eroded margins.
