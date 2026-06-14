# README_IMPROVEMENT

## Project

This repository is the modified implementation used for the SLAM final project report:

```text
SLAM Final Report: Reproducing and Improving 3D Gaussian Splatting as Markov Chain Monte Carlo
```

The code is based on the official 3DGS-MCMC repository. The original reproduced copy is kept separately at:

```text
D:\AI WORK\3dgs-mcmc-main
```

The modified copy is kept at:

```text
D:\AI WORK\3dgs-mcmc-step4-improvements
```

Local branch:

```text
step4-improvements
```

## Improvement Summary

The report studies two method-level changes.

H1 adds an image-gradient reconstruction term:

```text
L_total = L_rgb + lambda_edge * L_edge + L_reg
L_edge = L1(Sobel(render), Sobel(gt))
```

The selected quality variant is H1 delayed:

```text
edge_loss_weight = 0.02
edge_loss_start_iter = 7000
resampling_strategy = multinomial
seed = 0
```

H2 changes opacity-based Gaussian relocation from multinomial sampling to systematic resampling and reduces the Gaussian cap by 20%.

Selected H2 train configuration:

```text
cap_max = 880000
resampling_strategy = systematic
edge_loss_weight = 0.0
seed = 0
```

The combined ablation uses H1 delayed and H2 together.

## Modified Source Files

```text
arguments\__init__.py
scene\gaussian_model.py
train.py
utils\general_utils.py
utils\loss_utils.py
```

## Environment

The experiments were run on Windows with:

```text
Python 3.9
PyTorch 2.2.2
CUDA 11.8
MSVC build tools
NVIDIA RTX 4060 Laptop GPU, 8 GB VRAM
```

The original `environment.yml` is preserved in the repository. Local Windows build helper scripts are:

```text
run_vs_cuda118.bat
run_vs_cuda118_build.bat
```

## Reproduction and Training Commands

All reported runs use `--seed 0`.

Baseline train scene:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_baseline_seed0" --config configs\train_step5_baseline_seed0.json --eval --seed 0
```

H1 edge:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1_edge" --config configs\train_step5_h1_edge.json --eval --seed 0
```

H1 delayed:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1_delayed_edge" --config configs\train_step5_h1_delayed_edge.json --eval --seed 0
```

H2 systematic resampling with 80% cap:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h2_systematic_80cap" --config configs\train_step5_h2_systematic_80cap.json --eval --seed 0
```

H1 delayed + H2:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1delayed_h2_systematic_80cap" --config configs\train_step5_h1delayed_h2_systematic_80cap.json --eval --seed 0
```

Supplemental mic H1 delayed:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\nerf_synthetic\mic" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\mic_h1_delayed_edge" --config configs\mic_step5_h1_delayed_edge.json --eval --seed 0
```

Supplemental mic H2:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\nerf_synthetic\mic" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\mic_h2_systematic_80cap" --config configs\mic_step5_h2_systematic_80cap.json --eval --seed 0
```

## Results and Logs

Raw experiment metrics are stored under:

```text
results\step5
```

Important files:

```text
results\step5\quality_metrics.csv
results\step5\training_efficiency.csv
results\step5\render_efficiency.csv
results\step5\train_h1_per_view_delta.csv
results\step5\train_h1_delayed_per_view_delta.csv
```

GPU memory traces are stored as:

```text
results\step5\gpu_mem_*.csv
```

Step records:

```text
STEP1_BASELINE_REPRODUCTION.md
STEP2_DEFECT_ANALYSIS.md
STEP3_IMPROVEMENT_HYPOTHESES.md
STEP4_CODE_IMPLEMENTATION.md
STEP4_EXPERIMENT_MANIFEST.md
STEP5_PRELIMINARY_ANALYSIS.md
```

## Notes

The report keeps negative and weak results when they belong to the tested hypothesis set. H1 edge and H1 delayed + H2 are included as ablations rather than removed.
