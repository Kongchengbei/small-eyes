# Road-sign model v0.4 left-turn candidate

This board-validation candidate adds TT100K `i2` (turn-left) as output class 11.
It keeps the v0.4 32x32 CNN pipeline and current preprocessing candidate. The
candidate was trained with three random seeds using training crops and a
photo-held-out validation split; the official test split was not read.

At the validation-derived 97%-keep margin, left-turn accepted recall was
89.7% (seed 0), 86.2% (seeds 1 and 2) on 29 held-out crops. Seed 0 was packaged:
the quantized package reached 99.52% accuracy on its real validation set and
the integer reference matched the written package with zero mismatches. On the
48-code unseen validation set, 52 of 2,325 crops were accepted as target signs
(2.24%); the v0.4 11-class baseline had 57 (2.45%). The candidate rejects more
of the remaining blue-sign validation crops as uncertain, so it still needs
road-scene validation and careful review before production use.

The package contains 12 classes and is 62,784 bytes, within the 65,536-byte NPU
model limit. Class order is `background, unknown, pne, pn, p11, pl40, pl60,
pl80, pl120, i5, w57, i2`. The package's global reject margin is 1,279.

Build the stereo board image from the repository root with:

```sh
make -C bsp/camera_stereo_app npu
```

The resulting `_flash.bin` is a board-validation image, not a claim of physical
board validation. Check the startup `MODEL` line for `classes=12`,
`bytes=62784`, and `crc=0x28F4B306` before testing.
