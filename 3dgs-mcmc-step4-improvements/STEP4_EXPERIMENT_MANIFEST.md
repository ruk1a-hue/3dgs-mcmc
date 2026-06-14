# Step 4 Experiment Manifest

## Directory Separation

Original reproduced code and outputs:

```text
D:\AI WORK\3dgs-mcmc-main
```

Modified Step 4 code:

```text
D:\AI WORK\3dgs-mcmc-step4-improvements
```

All Step 4 source-code changes, training commands, configs, and random seed settings are stored in the modified directory above. The original `3dgs-mcmc-main` source files were restored from `D:\AI WORK\3dgs-mcmc-main.zip` after the modified copy was created.

## Git Branch

The modified directory is initialized as a local Git repository on:

```text
step4-improvements
```

## Modified Source Files

```text
arguments\__init__.py
scene\gaussian_model.py
train.py
utils\general_utils.py
utils\loss_utils.py
```

## Added Config Files

```text
configs\train_step4_baseline_seed0.json
configs\train_step4_h1_edge.json
configs\train_step4_h2_systematic_80cap.json
configs\train_step4_h1h2_edge_systematic_80cap.json
configs\train_step5_h1_delayed_edge.json
configs\mic_step5_h1_delayed_edge.json
configs\train_step5_hardview_sampling.json
configs\train_step5_h1_mse_delayed_w005_s7000.json
```

All configs set or preserve:

```text
seed = 0
```

## Training Commands

Baseline with explicit seed:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step4\train_baseline_seed0" --config configs\train_step4_baseline_seed0.json --eval --seed 0
```

H1 edge-aware loss:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step4\train_h1_edge" --config configs\train_step4_h1_edge.json --eval --seed 0
```

H2 systematic resampling with 80% cap:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step4\train_h2_systematic_80cap" --config configs\train_step4_h2_systematic_80cap.json --eval --seed 0
```

H1+H2 combined:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step4\train_h1h2_edge_systematic_80cap" --config configs\train_step4_h1h2_edge_systematic_80cap.json --eval --seed 0
```

Candidate H1 replacement, delayed hard-view adaptive sampling:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_hardview_sampling" --config configs\train_step5_hardview_sampling.json --eval --seed 0
```

Candidate H1 variant, delayed MSE loss:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1_mse_delayed_w005_s7000" --config configs\train_step5_h1_mse_delayed_w005_s7000.json --eval --seed 0
```

## Random Seed

All Step 4 training commands use:

```text
--seed 0
```

The code exposes `--seed` while preserving the original default seed value of `0`.

## Safer H1 Variant

After preliminary Step 5 results, the selected safer quality-improvement variant is:

```text
edge_loss_weight = 0.02
edge_loss_start_iter = 7000
resampling_strategy = multinomial
```

This variant keeps H2 disabled and delays the edge loss until after the coarse geometry has been established.
