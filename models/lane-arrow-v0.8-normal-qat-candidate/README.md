# Lane Arrow v0.8 Normal-QAT Candidate

This is a newly trained 11-class lane-cell classifier candidate. It is a model artifact only; whole-panel splitting and board firmware integration are not included.

## Artifact

- `model.npu`: 62,720-byte INT8 package, 32×32 input.
- `checkpoint.pt`: QAT checkpoint for further training.
- `L1_*.bin`–`L4_*.bin`, `FC_*.bin`, `model.json`: package components and metadata.
- `training_metrics.json`: 15-epoch training and validation record.
- `ctsu_pipeline_validation.json`: CTSU train-partition source-image holdout evaluation.

## Training and evaluation

- Initialized from the v0.7 distilled QAT checkpoint; fine-tuned for 15 epochs with seed 2803 and the existing normal augmentation policy.
- Used 8,831 training crops and 1,359 validation crops from `mapdr_ctsu_caption_cells_v2`; selected by MapDR exact-clip validation score. The dataset test split was not loaded.
- Selected checkpoint: MapDR crop accuracy 82.8%; MapDR complete-clip accuracy 20/27 (74.1%).
- NPU export passed the model build and format checks.
- On the same 86-image CTSU development pipeline, this package scores 53/86 exact sequences and 78/86 lane counts. The v0.7 package scores 53/86 and 77/86 under the same updated geometry path; this is a small candidate improvement, not independent-road validation.
- This candidate remains local research data. Dataset redistribution terms are not established.
