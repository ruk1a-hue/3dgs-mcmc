# Step 2 Defect Analysis Record

## 0. Scope

This document records Step 2 only: defect analysis of the reproduced baseline method, **3D Gaussian Splatting as Markov Chain Monte Carlo**. No improvement experiment has been started in this step.

The analysis is based on:

- Our Step 1 reproduction on `mic` and `train`.
- Per-view metrics and visual comparisons generated from the reproduced outputs.
- The official paper, especially the ablation, appendix, and limitation sections.
- The official implementation used for reproduction.

## 1. Process Log

1. Rechecked the Step 1 reproduction outputs for both scenes.
2. Parsed `per_view.json` for `mic` and `train`.
3. Generated per-view metric summaries and sorted per-view CSV files.
4. Generated a visual comparison panel for the worst `train` test views.
5. Inspected the training objective and Gaussian relocation/growth implementation.
6. Compared the observed reproduction behavior with the paper's ablation and limitation statements.

Generated evidence files:

| File | Purpose |
|---|---|
| `<ORIGINAL_REPO_ROOT>\results\step2_evidence\per_view_summary.csv` | Mean/std/min/max per-view metric summary. |
| `<ORIGINAL_REPO_ROOT>\results\step2_evidence\mic_per_view_metrics_sorted.csv` | `mic` per-view metrics sorted by quality. |
| `<ORIGINAL_REPO_ROOT>\results\step2_evidence\train_per_view_metrics_sorted.csv` | `train` per-view metrics sorted by quality. |
| `<ORIGINAL_REPO_ROOT>\results\step2_evidence\train_worst_views_panel.png` | GT/render/error visualization for the worst `train` views. |
| `<ORIGINAL_REPO_ROOT>\results\step2_evidence\config_capmax_summary.csv` | Scene-specific `cap_max` values from official configs. |

## 2. Evidence Summary

Per-view statistics from our reproduction:

| Scene | Metric | Mean | Std | Worst View | Worst Value |
|---|---|---:|---:|---|---:|
| `mic` | PSNR | 37.2699 | 1.7497 | `00097.png` | 33.1585 |
| `mic` | SSIM | 0.9940 | 0.0023 | `00097.png` | 0.9856 |
| `mic` | LPIPS | 0.0049 | 0.0018 | `00096.png` | 0.0111 |
| `train` | PSNR | 22.2575 | 2.6606 | `00035.png` | 16.3160 |
| `train` | SSIM | 0.8251 | 0.0694 | `00033.png` | 0.6433 |
| `train` | LPIPS | 0.2010 | 0.0502 | `00033.png` | 0.3491 |

The synthetic scene is very stable across views, while the real `train` scene has much larger view-level variance. The worst `train` views show local blur, edge misalignment, and high-frequency errors around the train body, wheels, tracks, background vegetation, and bright outdoor regions.

## 3. Defect 1: Photometric Training Is Not Enough for Reliable Geometry in Difficult Real Views

### Phenomenon

On the real `train` scene, the average metrics meet the paper reproduction target, but several individual test views are much weaker. The worst SSIM view is:

- `00033.png`: PSNR = 16.6490, SSIM = 0.6433, LPIPS = 0.3491.

The visual panel `train_worst_views_panel.png` shows that these low-score views are not random metric noise. They contain visible local artifacts: blurred train structures, edge misalignment near ladders/wheels/tracks, and strong absolute error in thin or high-frequency regions.

By contrast, `mic` is stable: its worst SSIM is still 0.9856. This suggests the issue is strongly tied to real-scene ambiguity, wide-baseline appearance variation, high-frequency details, and imperfectly constrained geometry.

### Mechanism Analysis

The implementation optimizes a rendering loss rather than an explicit geometric or SLAM consistency objective:

- `train.py:81-86`: each iteration samples one random camera.
- `train.py:97-103`: the loss is L1 + DSSIM, plus opacity and scale regularization.
- `train.py:124-142`: dead Gaussians are relocated, new Gaussians are added, and SGLD-style noise is added to Gaussian positions.

This design is effective for novel-view rendering, but it does not explicitly constrain depth, surface normals, reprojection consistency, camera-pose correction, or temporal/SLAM consistency. Therefore, when photometric supervision is ambiguous, multiple 3D Gaussian configurations may produce similar training-view images while still yielding weaker geometry and local artifacts in held-out views.

The paper's ablation section also supports this mechanism. It states that opacity/scale regularizers are essential to prevent stray Gaussians in spaces not well updated by the reconstruction loss, and that the noise term is needed for Gaussians to explore the full scene extent. This indicates that the photometric reconstruction loss alone leaves underconstrained regions.

### Evidence Sources

- Our reproduction observation: `train` has much larger per-view variance than `mic`.
- Quantitative evidence: `results\step2_evidence\per_view_summary.csv`.
- Visual evidence: `results\step2_evidence\train_worst_views_panel.png`.
- Code evidence: `train.py:81-103` and `train.py:124-142`.
- Paper evidence: Table 3 ablation and the discussion around stray Gaussians/noise exploration.

### Report-Ready Wording

Although 3DGS-MCMC improves average rendering quality and robustness to initialization, its supervision remains fundamentally photometric. In real scenes with thin structures, high-frequency texture, outdoor illumination changes, and partially ambiguous visibility, the method can satisfy the average rendering objective while producing unstable local geometry in certain novel views. This is visible in the `train` scene, where the mean metrics pass the reproduction target but the worst held-out view drops to SSIM 0.6433 and LPIPS 0.3491.

## 4. Defect 2: Scene-Specific Gaussian Budget Remains a Manual Capacity/Resource Bottleneck

### Phenomenon

The official configs require very different Gaussian caps across scenes:

| Config | `cap_max` |
|---|---:|
| `mic.json` | 320,000 |
| `chair.json` | 270,000 |
| `train.json` | 1,100,000 |
| `truck.json` | 2,600,000 |
| `stump.json` | 4,750,000 |
| `bicycle.json` | 5,900,000 |

In our reproduction, `train` uses more than three times the Gaussian cap of `mic`, takes substantially longer to train, and still has lower average and worst-view metrics. This does not invalidate the method; it shows that the method's quality/resource balance is still controlled by a scene-specific capacity hyperparameter.

### Mechanism Analysis

The method provides easier control over the number of Gaussians than original 3DGS, but it does not automatically infer the required capacity for a scene. In the implementation:

- `gaussian_model.py:503-506`: the number of Gaussians grows by a fixed factor up to `cap_max`.
- `gaussian_model.py:511-526`: new Gaussians are sampled from existing ones according to opacity.
- `gaussian_model.py:463-469`: sampling uses normalized probabilities and `torch.multinomial`.

This means `cap_max` directly limits the number of samples available to approximate the scene distribution. If the cap is too low, complex geometry and high-frequency appearance may be underrepresented. If the cap is too high, training cost and memory usage increase. The paper appendix also notes that training with 1M Gaussians costs about 90 ms per iteration on an RTX 3090 and that the current resampling implementation is naive PyTorch `torch.multinomial`, leaving room for acceleration.

This is independent from Defect 1. Defect 1 is about missing explicit geometry/SLAM constraints in the objective. Defect 2 is about representation capacity and resource allocation under a fixed Gaussian budget.

### Evidence Sources

- Our reproduction observation: `train` requires `cap_max = 1,100,000`, while `mic` uses `cap_max = 320,000`.
- Config evidence: `results\step2_evidence\config_capmax_summary.csv`.
- Code evidence: `gaussian_model.py:463-469` and `gaussian_model.py:503-526`.
- Paper evidence: Appendix C computational time; Appendix D limitations; Table 4 per-scene results.

### Report-Ready Wording

3DGS-MCMC makes Gaussian count controllable, but it does not remove the need to choose an adequate scene-specific budget. The official configs use 320k Gaussians for `mic`, 1.1M for `train`, 2.6M for `truck`, and several million for more complex scenes such as `bicycle`. Because the MCMC samples are still a finite representation of scene content, this budget becomes a direct tradeoff between reconstruction quality and computational cost.

## 5. Why These Are Two Independent Defects

| Defect | Main Cause | Observable Symptom | Possible Fix Direction |
|---|---|---|---|
| Photometric/geometric underconstraint | Loss lacks explicit geometry, depth, pose, or multi-view consistency terms. | Certain real test views show local artifacts despite acceptable average metrics. | Add geometry-aware constraints, depth priors, normal consistency, pose refinement, or multi-view consistency. |
| Manual Gaussian budget bottleneck | Fixed `cap_max` controls finite representation capacity and resource cost. | Complex scenes require much larger caps and longer training. | Adaptive budget allocation, per-region complexity estimation, or faster resampling. |

The first defect can occur even with a large Gaussian budget, because the problem is ambiguity in the supervision signal. The second defect can occur even with a better geometric objective, because finite sample capacity and training cost still constrain the representation.

## 6. Step 2 Conclusion

Two independent methodological defects have been identified and documented:

1. **Photometric training is not enough for reliable geometry in difficult real views.**
2. **Scene-specific Gaussian budget remains a manual capacity/resource bottleneck.**

Both defects include phenomenon descriptions, mechanism analysis, and evidence sources. The next step should choose one of these defects as the target for improvement, depending on the allowed time and risk level.
