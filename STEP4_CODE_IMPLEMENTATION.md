# Step 4 Code Implementation Record

## 0. Scope

This document records Step 4: source-code implementation of the improvement hypotheses from Step 3. This step modifies the training code, loss code, sampling code, and experiment configs. It does not contain full 30,000-iteration evaluation results.

Modified code directory:

```text
D:\AI WORK\3dgs-mcmc-step4-improvements
```

Original code directory retained separately:

```text
D:\AI WORK\3dgs-mcmc-main
```

Local branch in the modified directory:

```text
step4-improvements
```

The original behavior is preserved by default:

- `edge_loss_weight = 0.0`
- `resampling_strategy = "multinomial"`
- `seed = 0`

Therefore, the original baseline command remains reproducible. The original source files in `D:\AI WORK\3dgs-mcmc-main` are not used to store Step 4 source modifications.

## 1. Implemented Method-Level Changes

### H1: Edge-Aware Image-Gradient Consistency

Linked defect:

- Photometric training alone is not enough for reliable local structure in difficult real views.

Implemented files:

- `utils/loss_utils.py`
- `arguments/__init__.py`
- `train.py`

Implementation:

```text
L_total = L_rgb + edge_loss_weight * L_edge + L_regularization
L_edge = L1(Sobel(render), Sobel(gt))
```

The new Sobel-gradient loss is implemented in `gradient_l1_loss`. It uses grouped 2D convolution so each RGB channel is processed independently. This is a source-code change to the training objective, not a hyperparameter-only adjustment.

New argument:

```text
--edge_loss_weight
```

Default:

```text
0.0
```

H1 experiment value:

```text
0.05
```

### H2: Systematic Opacity Resampling

Linked defect:

- Scene-specific Gaussian budget remains a manual capacity/resource bottleneck.

Implemented files:

- `scene/gaussian_model.py`
- `arguments/__init__.py`

Implementation:

The original code sampled alive Gaussians by:

```text
torch.multinomial(opacity_probs, num, replacement=True)
```

The new option adds systematic resampling:

```text
1. normalize opacity probabilities
2. construct cumulative distribution
3. sample evenly spaced positions with one random offset
4. map positions to Gaussian indices using torch.searchsorted
```

This reduces the variance of opacity-proportional resampling and is designed to test whether a 20% lower Gaussian cap can preserve quality.

New argument:

```text
--resampling_strategy
```

Supported values:

```text
multinomial
systematic
```

Default:

```text
multinomial
```

H2 experiment value:

```text
systematic
```

### Candidate H1 Replacement: Delayed Hard-View Adaptive Sampling

Linked defect:

- Difficult-view instability on real scenes.

Implemented files:

- `train.py`
- `arguments/__init__.py`

Method change:

The original code samples training cameras uniformly through a shuffled stack. The new option delays intervention until a warm-up iteration, then keeps an exponential moving average of each camera's reconstruction loss and samples higher-loss views more often:

```text
p(view_i) proportional to EMA(reconstruction_loss_i) ^ hard_view_power
```

This is a source-code change to the training sampling strategy, not a pure hyperparameter adjustment. The warm-up keeps early coarse geometry formation close to the original method.

New arguments:

```text
--hard_view_sampling
--hard_view_start_iter
--hard_view_ema_decay
--hard_view_power
```

Default:

```text
hard_view_sampling = False
```

Therefore, baseline behavior is preserved unless the new config explicitly enables hard-view sampling.

### Candidate H1 Variant: Delayed MSE Reconstruction Loss

Linked defect:

- The real `train` scene has residual image reconstruction error after the main geometry has formed.

Implemented files:

- `train.py`
- `arguments/__init__.py`

Method change:

The new option adds a small MSE reconstruction term after a configurable warm-up iteration:

```text
L_total = L_rgb + mse_loss_weight * mean((render - gt)^2) + L_regularization
```

Because PSNR is directly determined by MSE, this variant tests whether late-stage pixel-error refinement can improve PSNR more directly than the Sobel-gradient loss.

New arguments:

```text
--mse_loss_weight
--mse_loss_start_iter
```

Default:

```text
mse_loss_weight = 0.0
```

Therefore, baseline behavior is preserved unless the new config explicitly enables delayed MSE loss.

### Reproducible Seed

Implemented files:

- `utils/general_utils.py`
- `train.py`

The original code always used seed `0` internally. Step 4 exposes this as a command-line argument:

```text
--seed 0
```

Default remains `0`, preserving baseline behavior while making the random seed explicit in experiment commands.

## 2. Config Files Added

| Config | Purpose |
|---|---|
| `configs/train_step4_baseline_seed0.json` | Baseline reproduction command with explicit seed/default method settings. |
| `configs/train_step4_h1_edge.json` | H1 only: edge-aware loss enabled, original Gaussian cap and multinomial resampling. |
| `configs/train_step4_h2_systematic_80cap.json` | H2 only: systematic resampling and 20% lower `cap_max`. |
| `configs/train_step4_h1h2_edge_systematic_80cap.json` | Combined H1+H2 test setting. |
| `configs/train_step5_hardview_sampling.json` | Candidate H1 replacement: delayed hard-view adaptive sampling, with edge loss disabled and original Gaussian cap. |
| `configs/train_step5_h1_mse_delayed_w005_s7000.json` | Candidate H1 variant: delayed MSE loss, `mse_loss_weight = 0.05`, `mse_loss_start_iter = 7000`. |

## 3. Commands Preserved for Step 5 Experiments

### Baseline, explicit seed

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step4\train_baseline_seed0" --config configs\train_step4_baseline_seed0.json --eval --seed 0
```

### H1: edge-aware loss

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step4\train_h1_edge" --config configs\train_step4_h1_edge.json --eval --seed 0
```

### H2: systematic resampling with 80% cap

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step4\train_h2_systematic_80cap" --config configs\train_step4_h2_systematic_80cap.json --eval --seed 0
```

### H1+H2 combined

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step4\train_h1h2_edge_systematic_80cap" --config configs\train_step4_h1h2_edge_systematic_80cap.json --eval --seed 0
```

### Candidate H1 replacement: delayed hard-view adaptive sampling

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_hardview_sampling" --config configs\train_step5_hardview_sampling.json --eval --seed 0
```

### Candidate H1 variant: delayed MSE loss

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1_mse_delayed_w005_s7000" --config configs\train_step5_h1_mse_delayed_w005_s7000.json --eval --seed 0
```

### Render and metrics template

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe render.py --model_path "<MODEL_PATH>" --iteration 30000 --skip_train
D:\anaconda3\envs\pytorch2.2.2\python.exe metrics.py --model_paths "<MODEL_PATH>"
```

## 4. Smoke Tests Performed

Static checks:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe -m py_compile train.py arguments\__init__.py utils\loss_utils.py utils\general_utils.py scene\gaussian_model.py
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --help
```

Functional checks:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe -c "import torch; from utils.loss_utils import gradient_l1_loss; from scene.gaussian_model import GaussianModel; a=torch.rand(3,8,8); b=torch.rand(3,8,8); print(float(gradient_l1_loss(a,b))); m=GaussianModel(3, resampling_strategy='systematic'); m._opacity=torch.zeros(10,1); idx, ratio=m._sample_alives(torch.arange(1,11,dtype=torch.float32), 5); print(idx.tolist(), int(ratio.sum()))"
```

One-iteration training smoke test:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\nerf_synthetic\mic" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step4_smoke_h1" --config configs\train_step4_h1_edge.json --eval --iterations 1 --test_iterations 1 --save_iterations 1 --seed 0
```

Result:

- Python compilation passed.
- New CLI arguments are visible in `train.py --help`.
- `gradient_l1_loss` returns a finite value.
- systematic resampling returns the requested number of samples.
- one-iteration training with edge loss completed and saved output.

## 5. Step 4 Conclusion

Step 4 source-code implementation is complete. The code now supports:

1. an edge-aware Sobel-gradient consistency loss for H1,
2. systematic opacity resampling for H2,
3. delayed hard-view adaptive camera sampling as a candidate H1 replacement,
4. delayed MSE reconstruction loss as a PSNR-oriented candidate H1 variant,
5. explicit seed control,
6. separate baseline and improved config files,
7. reproducible commands for the next full experiment step.

The next step should run full 30,000-iteration experiments and compare the outputs against the Step 1 baseline using the thresholds defined in Step 3.
