# README_IMPROVEMENT

## Project

This repository is the modified implementation used for the SLAM final project report:

```text
Reproducing and Improving 3D Gaussian Splatting as Markov Chain Monte Carlo for SLAM-Oriented Reconstruction
```

Original paper and code:

```text
Paper: 3D Gaussian Splatting as Markov Chain Monte Carlo
Venue: NeurIPS 2024, Spotlight Presentation
arXiv: https://arxiv.org/abs/2404.09591
Project page: https://ubc-vision.github.io/3dgs-mcmc/
Official code: https://github.com/ubc-vision/3dgs-mcmc
```

This satisfies the project topic requirement: the selected paper was published after January 2024, belongs to the 3DGS/NeRF reconstruction family, and has an official open-source repository.

The original reproduced copy is kept separately outside this code package:

```text
../3dgs-mcmc-main
```

This code package corresponds to the modified repository root:

```text
.
```

Required project branch name:

```text
improvement
```

If this package is uploaded to GitHub, the submitted branch should be named `improvement`.

## Improvement Summary

The report studies two method-level changes. See Section V of the report for the method design and Section VII for the experiments.

H1 adds an image-gradient reconstruction term to address local structural errors in difficult real-scene views:

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

H2 changes opacity-based Gaussian relocation from multinomial sampling to systematic resampling and reduces the Gaussian cap by 20%:

```text
cap_max = 880000
resampling_strategy = systematic
edge_loss_weight = 0.0
seed = 0
```

The combined ablation uses H1 delayed and H2 together. Negative and weak runs are kept because the assignment requires honest analysis when a hypothesis is not fully supported.

## Ablation Study Design

The commands below are grouped by hypothesis and ablation role.

For H1, `train_h1_edge` tests the original Sobel edge loss from the start of training. `train_h1_delayed_edge` is the timing ablation: it delays the Sobel term until iteration 7000 and lowers the weight. This checks whether early edge supervision is the reason the first H1 run loses PSNR.

For H2, `train_h2_systematic_80cap` tests systematic opacity resampling under an 80% Gaussian cap. It is compared against the baseline with the same seed and scene.

For interaction analysis, `train_h1delayed_h2_systematic_80cap` combines H1 delayed and H2. This ablation tests whether the quality and efficiency changes are additive. In the report they are not additive, and that negative result is kept.

Additional screening runs are also preserved:

```text
train_step5_hardview_sampling.json
train_step5_h1_mse_delayed_w005_s7000.json
```

These runs are not used as the main method, but they support the report discussion about failed or weaker alternatives.

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

Run commands from the repository root. Replace `<PYTHON>` with your local Python executable and `<DATA_ROOT>` with the local dataset root. The commands below use repository-relative output and config paths, so only the dataset root and Python executable need to be changed on another machine.

All reported runs use `--seed 0`.

Baseline train scene:

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\tandt_db\tandt\train" --model_path "output\step5\train_baseline_seed0" --config "configs\train_step5_baseline_seed0.json" --eval --seed 0
```

H1 edge:

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\tandt_db\tandt\train" --model_path "output\step5\train_h1_edge" --config "configs\train_step5_h1_edge.json" --eval --seed 0
```

H1 delayed:

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\tandt_db\tandt\train" --model_path "output\step5\train_h1_delayed_edge" --config "configs\train_step5_h1_delayed_edge.json" --eval --seed 0
```

H2 systematic resampling with 80% cap:

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\tandt_db\tandt\train" --model_path "output\step5\train_h2_systematic_80cap" --config "configs\train_step5_h2_systematic_80cap.json" --eval --seed 0
```

H1 delayed + H2:

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\tandt_db\tandt\train" --model_path "output\step5\train_h1delayed_h2_systematic_80cap" --config "configs\train_step5_h1delayed_h2_systematic_80cap.json" --eval --seed 0
```

Hard-view sampling screening run:

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\tandt_db\tandt\train" --model_path "output\step5\train_hardview_sampling" --config "configs\train_step5_hardview_sampling.json" --eval --seed 0
```

Delayed MSE edge screening run:

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\tandt_db\tandt\train" --model_path "output\step5\train_h1_mse_delayed_w005_s7000" --config "configs\train_step5_h1_mse_delayed_w005_s7000.json" --eval --seed 0
```

Supplemental mic H1 delayed:

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\nerf_synthetic\mic" --model_path "output\step5\mic_h1_delayed_edge" --config "configs\mic_step5_h1_delayed_edge.json" --eval --seed 0
```

Supplemental mic H2:

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\nerf_synthetic\mic" --model_path "output\step5\mic_h2_systematic_80cap" --config "configs\mic_step5_h2_systematic_80cap.json" --eval --seed 0
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

These local CSV files directly correspond to Deliverable 3, the experiment data package. Together they cover the three required metric groups:

```text
Rendering quality: PSNR, SSIM, LPIPS
Time efficiency: training duration and rendering FPS
Memory usage: peak GPU memory and GPU memory traces
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

## AI Usage & Code Acknowledgement

- AI tools were used for Markdown/report formatting, deliverable requirement cross-checking, and debugging support.
- The defect analysis, method choices, implementation, and reported experiment data are based on the local project work described in the report.
- The modified code is based on the official 3DGS-MCMC repository listed above. No external completed improvement implementation was copied.
- The original repository itself builds on the official 3D Gaussian Splatting code base and references StopThePop in its own README; those upstream acknowledgements are preserved in the repository history and source package.

## Notes

The report keeps negative and weak results when they belong to the tested hypothesis set. H1 edge, H1 delayed + H2, hard-view sampling, and delayed MSE edge are included as ablations or screening runs rather than removed.
