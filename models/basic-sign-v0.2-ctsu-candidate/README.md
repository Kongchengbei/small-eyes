# Basic sign v0.2 CTSU candidate

Status: local 20-output crop-classification candidate. It is not a field-validated release.

## Training and validation

- Extends the previous grouped dataset with 2,101 CTSU captioned lane-cell crops from 629 source images. The official CTSU `train.txt` partition only is used; image-group holdout is preserved, and CTSU test data is not loaded.
- Three 32x32 seeds were trained for 40 epochs. Validation accuracy / macro accuracy over present classes: seed 2601, 97.63% / 96.30%; seed 2602, 97.19% / 95.53%; seed 2603, 97.36% / 96.13%.
- All three seeds were quantized and exported; INT8 accuracy / present-class macro accuracy: seed 2601, 97.68% / 96.35%; seed 2602, 97.12% / 95.33%; seed 2603, 97.12% / 95.62%. Each package matches its software integer implementation on 100/100 sampled validation inputs.
- Seed 2601 is selected for the NPU package. On the same extended validation manifest, the previous seed-2401 model scores 96.61% / 93.24%; the new model scores 97.63% / 96.30%. This is a grouped crop-level validation comparison, not a sealed field test.
- A 48x48 comparison scores 95.58% accuracy / 97.56% macro accuracy. The current NPU path is fixed to 32x32, and the 48x48 variant is not deployed.

## NPU package

- `model.npu` contains 20 outputs and is 63,328 bytes, below the current 65,536-byte limit.
- INT8 validation accuracy is 97.68%; float/integer argmax agreement is 99.88%. The packed NPU reference matches the integer implementation on 100/100 sampled validation inputs.
- One class, `uturn_right`, has no real training examples. `straight_left_right` has only two training examples and no validation examples. Rare classes remain unverified and the model must not be trusted for them.
- The package passes the NPU CNN engine RTL reference test on 16 deterministic inputs in both 32x32 and 96x96 modes, with 144 layer checks per mode. `bsp/camera_stereo_app/Makefile` selects this package by default. Clean `npu-local` and `npu-remote` source builds produce 16,384-byte CPU images and 96,096-byte Flash images; each Flash model segment matches this 63,328-byte package byte-for-byte. Physical-board operation remains unverified.
- The package is a pre-cropped classifier only. Full-scene localization, temporal confirmation, independent real-scene metrics, physical-board testing, and release gates remain outstanding.

## Data and redistribution

The set combines sources with different restrictions, including CTSU academic research under its dataset agreement and MapDR CC-BY-NC-SA-4.0. TPD redistribution terms are not established. Keep this package local; do not push or redistribute derived weights until every applicable term is reviewed.

Detailed results: `export_metrics.json`, `export_metrics_seed2602.json`, `export_metrics_seed2603.json`, `training_metrics_seed2601.json`, `training_metrics_seed2602.json`, `training_metrics_seed2603.json`, and `training_metrics_48_seed2601.json`.
