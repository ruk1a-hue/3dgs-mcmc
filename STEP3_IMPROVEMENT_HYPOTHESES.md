# Step 3 Improvement Hypotheses

## 0. Scope

This document records Step 3 only: constructing falsifiable improvement hypotheses from the two defects identified in Step 2. No code modification or new experiment has been performed in this step.

The goal is to make each proposed improvement testable before implementation. Each hypothesis therefore specifies:

- the linked defect,
- the exact intervention,
- the expected metric change,
- the baseline value,
- the failure condition,
- and the guardrail metrics that prevent an apparent improvement from hiding regressions.

## 1. Baseline Values Used for Hypothesis Design

| Item | Baseline |
|---|---:|
| `train` average PSNR | 22.2575 |
| `train` average SSIM | 0.8251 |
| `train` average LPIPS | 0.2010 |
| `train` worst-4 held-out view mean PSNR | 19.2380 |
| `train` worst-4 held-out view mean SSIM | 0.6917 |
| `train` worst-4 held-out view mean LPIPS | 0.2971 |
| `train` `cap_max` | 1,100,000 |
| `train` baseline training time | about 40 min 10 sec |

Worst-4 held-out views by SSIM:

- `00033.png`
- `00018.png`
- `00017.png`
- `00016.png`

These baseline values come from:

- `D:\AI WORK\3dgs-mcmc-main\results\step2_evidence\train_per_view_metrics_sorted.csv`
- `D:\AI WORK\3dgs-mcmc-main\results\step2_evidence\per_view_summary.csv`
- `D:\AI WORK\3dgs-mcmc-main\logs\repro_train_train.log`

## 2. Hypothesis H1: Edge-Aware Consistency for Difficult Real Views

### Linked Defect

Defect 1: **Photometric training is not enough for reliable geometry in difficult real views.**

### Mechanism Connection

The observed low-score `train` views contain edge misalignment, blur, and high-frequency errors near train wheels, ladders, tracks, vegetation, and bright outdoor boundaries. The current training objective is mainly RGB L1 + DSSIM, plus opacity/scale regularization. This can match average color appearance while still leaving local structures underconstrained.

An image-gradient consistency term directly increases the penalty for mismatched edges and local structures. It does not require external depth labels or a pretrained model, so it is a low-risk way to add a geometry-related image constraint.

### Proposed Intervention

Add a Sobel-gradient loss during training:

```text
L_total = L_rgb + lambda_edge * L_edge
L_rgb   = (1 - lambda_dssim) * L1(render, gt) + lambda_dssim * (1 - SSIM(render, gt))
L_edge  = L1(Sobel(render), Sobel(gt))
```

Initial test setting:

- `lambda_edge = 0.05`
- train on `train`
- keep official `configs\train.json`
- keep 30,000 iterations
- compare against Step 1 baseline output

### Falsifiable Hypothesis

If an edge-aware image-gradient consistency term is added to the baseline training loss, then on the `train` scene the worst-4 held-out views should improve by:

- mean SSIM: **0.6917 -> at least 0.7217**,
- mean LPIPS: **0.2971 -> at most 0.2771**.

### Failure Condition

H1 is rejected if either condition is not met:

- worst-4 mean SSIM improves by less than +0.03,
- worst-4 mean LPIPS decreases by less than 0.02.

Guardrails:

- average PSNR must not drop by more than 0.2 dB from 22.2575,
- average SSIM must not drop by more than 0.005 from 0.8251,
- training time overhead should stay within 10%.

### Expected Report Statement

If H1 succeeds, the report can claim that adding a lightweight edge-aware consistency term reduces the local structural instability observed in difficult real views. If it fails, the result suggests that the artifacts are not sufficiently addressed by image-space edge supervision alone and may require stronger geometric priors such as sparse-depth, normal, or multi-view consistency.

## 3. Hypothesis H2: Lower-Variance Resampling Under a Reduced Gaussian Budget

### Linked Defect

Defect 2: **Scene-specific Gaussian budget remains a manual capacity/resource bottleneck.**

### Mechanism Connection

The official implementation grows Gaussians up to a manually selected `cap_max`. New and relocated Gaussians are sampled from existing alive Gaussians according to opacity. This is controllable, but the user still needs a large scene-specific cap, and training cost grows with that budget.

For `train`, the official cap is 1,100,000 Gaussians. The method is therefore not only a quality method but also a capacity allocation method. A lower-variance resampling strategy should reduce redundant random duplicates and make a smaller cap less damaging.

### Proposed Intervention

Replace the current multinomial opacity resampling with systematic opacity resampling:

```text
Current:
sample indices randomly with torch.multinomial(opacity_probs, num, replacement=True)

Proposed:
construct cumulative opacity distribution
sample evenly spaced positions with one random offset
map positions to Gaussian indices with searchsorted
```

Then run the `train` scene with:

- `cap_max = 880,000` instead of 1,100,000,
- same 30,000 iterations,
- same official training settings otherwise.

### Falsifiable Hypothesis

If multinomial opacity resampling is replaced by lower-variance systematic opacity resampling and `cap_max` is reduced by 20%, then on `train` the training wall-clock time should decrease by at least 15% while maintaining near-baseline rendering quality:

- training time: **about 40m10s -> at most about 34m08s**,
- PSNR: no lower than **21.9575**,
- SSIM: no lower than **0.8151**,
- LPIPS: no higher than **0.2210**.

### Failure Condition

H2 is rejected if any condition occurs:

- wall-clock training time decreases by less than 15%,
- average PSNR drops by more than 0.3 dB,
- average SSIM drops by more than 0.01,
- average LPIPS increases by more than 0.02.

Guardrail:

- the reproduced result should still remain within the assignment's acceptable reproduction tolerance relative to the original paper target.

### Expected Report Statement

If H2 succeeds, the report can claim that better sample allocation reduces the manual Gaussian budget burden while preserving quality. If it fails, the result indicates that the `train` scene genuinely needs the original capacity, or that opacity-only resampling is not the main source of budget inefficiency.

## 4. Independence of the Two Hypotheses

| Hypothesis | Targets | Primary Metric |
|---|---|---|
| H1 | Local structural artifacts in difficult real views | Worst-4 SSIM/LPIPS |
| H2 | Resource and Gaussian budget bottleneck | Training time with quality guardrails |

H1 changes the supervision signal and asks whether local visual/geometric consistency improves. H2 changes the sample allocation and budget behavior and asks whether similar quality can be obtained with fewer Gaussians and less time. Therefore, the two hypotheses correspond to independent defects.

## 5. Step 3 Conclusion

Two falsifiable improvement hypotheses have been constructed:

1. **H1: Add edge-aware consistency to improve difficult real-view local structure.**
2. **H2: Use lower-variance resampling with a 20% lower Gaussian cap to reduce training time while preserving quality.**

The next step should implement and test one or both hypotheses, then compare against the Step 1 baseline using the exact metrics and thresholds defined here.
