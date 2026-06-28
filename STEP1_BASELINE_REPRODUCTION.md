# Step 1 Baseline Reproduction Record

## 1. Paper and Validity

- Paper: **3D Gaussian Splatting as Markov Chain Monte Carlo**
- Venue/year: **NeurIPS 2024 Spotlight**
- Method type: 3D Gaussian Splatting / novel view synthesis
- Official code: https://github.com/ubc-vision/3dgs-mcmc
- Local code path: `<ORIGINAL_REPO_ROOT>`
- Local paper PDF: `<LOCAL_PAPER_PDF>`

This paper satisfies the assignment requirement of reproducing a recent NeRF/3DGS-related paper published in 2024 or later. The experiments below use the official code and official configuration style.

## 2. Scene Selection

The assignment requires running at least two scenes and recommends either one synthetic plus one real scene, or two real scenes with clear differences. To match this requirement strictly, the selected scenes are:

| Scene | Dataset | Type | Reason |
|---|---|---|---|
| `mic` | NeRF Synthetic | Synthetic | Standard synthetic scene reported in the paper. |
| `train` | Tanks and Temples | Real | Real captured scene reported in the paper; visually and statistically different from `mic`. |

Final reproduction uses **one synthetic scene + one real scene**, so the scene choice meets the assignment requirement. The extracted `chair` scene is not used as a final reported reproduction scene.

## 3. Environment

| Item | Value |
|---|---|
| OS | Windows |
| GPU | NVIDIA GeForce RTX 4060 Laptop GPU, 8 GB VRAM |
| Python env | `<CONDA_ENV>` |
| Python | 3.9.25 |
| PyTorch | 2.2.2 + CUDA 11.8 |
| CUDA compiler | CUDA 11.8 nvcc from conda |
| C++ compiler | MSVC 14.44 from Visual Studio |

Build notes: the official project is mainly documented for Linux/conda. On this Windows setup, only build compatibility changes were needed for CUDA/MSVC and the missing Git submodules. These changes did not alter the model algorithm, training procedure, evaluation protocol, or hyperparameters.

## 4. Commands Used

### `mic` synthetic scene

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\nerf_synthetic\mic" --model_path "<ORIGINAL_REPO_ROOT>\output\reproduction\mic" --config configs\mic.json --eval
<PYTHON> render.py --model_path "<ORIGINAL_REPO_ROOT>\output\reproduction\mic" --iteration 30000 --skip_train
<PYTHON> metrics.py --model_paths "<ORIGINAL_REPO_ROOT>\output\reproduction\mic"
```

### `train` real scene

```powershell
<PYTHON> train.py --source_path "<DATA_ROOT>\tandt_db\tandt\train" --model_path "<ORIGINAL_REPO_ROOT>\output\reproduction\train" --config configs\train.json --eval
<PYTHON> render.py --model_path "<ORIGINAL_REPO_ROOT>\output\reproduction\train" --iteration 30000 --skip_train
<PYTHON> metrics.py --model_paths "<ORIGINAL_REPO_ROOT>\output\reproduction\train"
```

## 5. Results

Paper targets are taken from the paper table for the official `Ours(Random)` setting.

| Scene | Type | Paper PSNR | Repro PSNR | PSNR diff | Paper SSIM | Repro SSIM | SSIM diff | Paper LPIPS | Repro LPIPS | Status |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `mic` | Synthetic | 37.29 | 37.2699 | -0.0540% | 0.99 | 0.9940 | +0.4023% | 0.01 | 0.0049 | Pass |
| `train` | Real | 22.40 | 22.2575 | -0.6364% | 0.83 | 0.8251 | -0.5892% | 0.24 | 0.2010 | Pass |

The PSNR and SSIM deviations are far below the assignment threshold of 5%. LPIPS is lower than the paper value on both scenes, which is better because lower LPIPS indicates better perceptual similarity. For `mic`, the paper reports LPIPS rounded to `0.01`; the reproduced value `0.0049` is therefore treated as better than the rounded target rather than as a negative deviation.

## 6. Output Artifacts

| Artifact | Path |
|---|---|
| Metrics CSV | `<ORIGINAL_REPO_ROOT>\results\step1_metrics.csv` |
| `mic` model output | `<ORIGINAL_REPO_ROOT>\output\reproduction\mic` |
| `mic` rendered test images | `<ORIGINAL_REPO_ROOT>\output\reproduction\mic\test\ours_30000\renders` |
| `mic` training log | `<ORIGINAL_REPO_ROOT>\logs\repro_mic_train.log` |
| `train` model output | `<ORIGINAL_REPO_ROOT>\output\reproduction\train` |
| `train` rendered test images | `<ORIGINAL_REPO_ROOT>\output\reproduction\train\test\ours_30000\renders` |
| `train` training log | `<ORIGINAL_REPO_ROOT>\logs\repro_train_train.log` |

Rendered test set sizes:

- `mic`: 200 rendered test images.
- `train`: 38 rendered test images.

## 7. Conclusion

Step 1 baseline reproduction is complete. The chosen scenes satisfy the required scene diversity, and the reproduced rendering metrics meet the assignment tolerance requirement. No next-step modification or improvement experiment has been started yet.
