# Road-sign model v0.4 (mild s1)

This is the validated v0.4 mild-s1 INT8 model package used with the v0.4
preprocessing candidate in this branch. The model weights and global reject
margin are unchanged from the existing formal v0.4 package; only the camera
front-end candidate is new.

The default candidate lowers the red/blue brightness threshold from `0x40` to
`0x30` and the minimum region fill from `0x20` to `0x18`; it keeps the original
yellow/black thresholds. Offline training-hash and TSRD checks improved the
number of correctly accepted speed-limit-40 signs without a consistent
increase in false accepts. These checks are not independent road-camera data,
and the user's reported field image has not been identified, so the setting
still requires board validation.

Build the stereo board image from the repository root with:

```sh
make -C bsp/camera_stereo_app npu
```

The NPU build defaults to this `model.npu`. Override `NPU_MODEL` only when
testing a different package. The generated `_flash.bin` contains the CPU
image followed by the checked 62,720-byte model package; program the complete
`camera_stereo_npu_local_flash.bin` or `camera_stereo_npu_remote_flash.bin`
image at Flash address `0x00A00000` using the board's normal programming flow.

Class order: background, unknown, no-entry, no-parking, no-horn, speed-40,
speed-60, speed-80, speed-120, keep-right, pedestrian-crossing.

Offline package validation and NPU golden simulation pass. The new preprocessing
threshold candidate has not yet been synthesized in PDS or validated on the
physical board. Treat this branch as a board-validation candidate, not a
production release.
