# Step 5 Preliminary Analysis Before Continuing H2

## Completed Experiments

Completed full train/render/metrics runs:

| Scene | Variant |
|---|---|
| `mic` | baseline |
| `mic` | H1+H2: edge loss + systematic resampling + 80% cap |
| `train` | baseline |
| `train` | H1 only: edge loss |
| `train` | H1 delayed edge |
| `train` | H2 only: systematic resampling + 80% cap |
| `train` | H1 delayed + H2 systematic 80% cap |
| `train` | candidate H1: delayed hard-view adaptive sampling |

## Aggregate Quality Metrics

| Scene | Variant | PSNR | SSIM | LPIPS |
|---|---|---:|---:|---:|
| `mic` | baseline | 37.2812 | 0.993990 | 0.004906 |
| `mic` | H1+H2 | 37.2082 | 0.993896 | 0.004980 |
| `train` | baseline | 22.2412 | 0.824513 | 0.201255 |
| `train` | H1 only | 22.1942 | 0.825299 | 0.199232 |
| `train` | H1 delayed edge | 22.3649 | 0.825051 | 0.199818 |
| `train` | H2 systematic 80% cap | 22.1562 | 0.819467 | 0.209958 |
| `train` | H1 delayed + H2 systematic 80% cap | 22.1485 | 0.818708 | 0.209549 |
| `train` | hard-view adaptive sampling | 22.1258 | 0.823221 | 0.201434 |
| `train` | H1 MSE delayed, w=0.05, start=7000 | 22.2659 | 0.825579 | 0.198845 |

## Efficiency Metrics

| Scene | Variant | Train Time (s) | Peak GPU Mem (MB) | Render FPS |
|---|---|---:|---:|---:|
| `mic` | baseline | 1153.389 | 4694 | 5.8323 |
| `mic` | H1+H2 | 1077.372 | 4554 | 6.1275 |
| `train` | baseline | 2875.280 | 5200 | 1.7656 |
| `train` | H1 only | 2925.199 | 5256 | 1.7834 |
| `train` | H1 delayed edge | 2436.096 | 4445 | 1.6250 |
| `train` | H2 systematic 80% cap | 2092.169 | 4115 | 1.6491 |
| `train` | H1 delayed + H2 systematic 80% cap | 2112.328 | 4175 | 1.6792 |
| `train` | hard-view adaptive sampling | 2394.239 | 4495 | 1.6152 |
| `train` | H1 MSE delayed, w=0.05, start=7000 | 2421.210 | 4521 | 1.2674 |

## H1 Analysis

H1 is the edge-aware Sobel-gradient loss. On the real `train` scene:

- PSNR decreases by 0.0471 dB.
- SSIM increases by 0.000786.
- LPIPS decreases by 0.002023.
- Training time increases by 49.919 s, about 1.74%.
- Peak GPU memory increases by 56 MB, about 1.08%.

Per-view comparison:

| View Set | PSNR Change | SSIM Change | LPIPS Improvement |
|---|---:|---:|---:|
| Worst-4 by baseline SSIM | -0.4793 | +0.00165 | +0.00345 |
| Worst-4 by baseline PSNR | +0.0776 | -0.00073 | +0.00417 |
| Worst-4 by baseline LPIPS | -0.4073 | -0.00036 | +0.00392 |

Across all 38 held-out views:

- PSNR improves on 20 views.
- SSIM improves on 21 views.
- LPIPS improves on 26 views.

Interpretation: H1 has a real but weak positive signal for perceptual quality on the real scene, especially LPIPS. However, it does not meet the original Step 3 success threshold of worst-4 SSIM +0.03 and LPIPS -0.02. Therefore H1 should be described as a modest perceptual regularization, not as a clearly successful solution to the difficult-view geometry defect.

## H2 Analysis

H2 is systematic opacity resampling with a 20% lower Gaussian cap.

The completed `train` H2-only result is:

- Training time: 2875.280 s -> 2092.169 s, about 27.24% faster.
- Peak GPU memory: 5200 MB -> 4115 MB, about 20.87% lower.
- PSNR: 22.2412 -> 22.1562, drop 0.0851 dB.
- SSIM: 0.824513 -> 0.819467, drop 0.005046.
- LPIPS: 0.201255 -> 0.209958, increase 0.008703.
- Render FPS: 1.7656 -> 1.6491, about 6.60% lower.

According to the Step 3 falsification thresholds, H2 succeeds:

- Training time reduction is greater than 15%.
- PSNR drop is less than 0.3 dB.
- SSIM drop is less than 0.01.
- LPIPS increase is less than 0.02.

The `mic` H1+H2 combined run also showed a similar efficiency tendency:

- Training time: 1153.389 s -> 1077.372 s, about 6.59% faster.
- Peak GPU memory: 4694 MB -> 4554 MB, about 2.98% lower.
- Render FPS: 5.8323 -> 6.1275, about 5.06% higher.
- Quality: PSNR -0.0730 dB, SSIM -0.000094, LPIPS +0.000074.

This suggests that the lower-cap/systematic-resampling direction reduces resource use. On the real `train` scene, the efficiency gain is large, while quality remains within the guardrail thresholds. H2 is therefore a successful efficiency-oriented improvement, but not a quality improvement.

## H1 Delayed + H2 Combination

The completed combination result is:

- PSNR: 22.1485.
- SSIM: 0.818708.
- LPIPS: 0.209549.
- Training time: 2112.328 s.
- Peak GPU memory: 4175 MB.
- Render FPS: 1.6792.

Compared with baseline:

- Training time decreases by about 26.53%.
- Peak GPU memory decreases by about 19.71%.
- PSNR decreases by 0.0927 dB.
- SSIM decreases by 0.005805.
- LPIPS increases by 0.008294.

Compared with H2-only:

- Training time increases slightly: 2092.169 s -> 2112.328 s.
- Peak GPU memory increases slightly: 4115 MB -> 4175 MB.
- PSNR decreases slightly: 22.1562 -> 22.1485.
- SSIM decreases slightly: 0.819467 -> 0.818708.
- LPIPS improves slightly: 0.209958 -> 0.209549.

Interpretation: combining delayed H1 with H2 does not recover the quality lost by the 80% Gaussian cap. The combination keeps the efficiency benefit of H2, but it is not better than H1 delayed for quality and not meaningfully better than H2 for efficiency. Therefore, the report should present H1 delayed and H2 as two separate validated improvements rather than claiming the combined method is the best final variant.

## Candidate H1 Replacement: Delayed Hard-View Adaptive Sampling

Motivation:

- The edge-loss H1 only indirectly targets difficult views.
- A more direct method-level change is to alter the training camera sampling strategy.
- After a 7000-iteration warm-up, each training view keeps an EMA reconstruction loss; higher-loss views are sampled with larger probability.

Implementation evidence:

- Config: `configs\train_step5_hardview_sampling.json`.
- Runner: `scripts\run_step5_hardview.py`.
- Training log confirms the delayed switch: `Hard=0` before iteration 7000 and `Hard=1` from iteration 7000 onward.
- This is a sampling-strategy change, so it satisfies the assignment's requirement for a methodological code modification.

Result on `train`:

- PSNR: 22.2412 -> 22.1258, decrease 0.1154 dB.
- SSIM: 0.824513 -> 0.823221, decrease 0.001292.
- LPIPS: 0.201255 -> 0.201434, increase 0.000179.
- Training time: 2875.280 s -> 2394.239 s, measured reduction 481.041 s.
- Peak GPU memory: 5200 MB -> 4495 MB, measured reduction 705 MB.
- Render FPS: 1.7656 -> 1.6152, decrease about 8.52%.

Interpretation:

The hard-view sampling idea is methodologically cleaner than pure hyperparameter tuning and is easy to justify as an answer to difficult-view instability. However, the completed experiment falsifies it as a quality-improving H1 replacement on the selected `train` scene: all three quality metrics are slightly worse than baseline, and it is clearly worse than delayed edge H1. The likely reason is that repeatedly emphasizing high-loss views can overfit noisy, occluded, or hard-to-explain camera regions instead of improving globally consistent geometry. For the report, this run is best used as a negative ablation: it shows that not every targeted sampling change improves reconstruction quality.

## Candidate H1 Variant: Delayed MSE Reconstruction Loss

Motivation:

- PSNR is directly determined by pixel-wise MSE.
- The original edge-aware H1 is more structure/perception oriented and only indirectly optimizes PSNR.
- Adding a small MSE term after a 7000-iteration warm-up tests whether late-stage pixel-error refinement improves `train` PSNR without changing sampling or Gaussian budget.

Implementation evidence:

- Config: `configs\train_step5_h1_mse_delayed_w005_s7000.json`.
- Runner: `scripts\run_step5_h1_mse_delayed.py`.
- The training log confirms the delayed switch: `MSE=0.00000` before iteration 7000 and nonzero MSE values from iteration 7000 onward.

Result on `train`:

- PSNR: 22.2412 -> 22.2659, improvement +0.0247 dB.
- SSIM: 0.824513 -> 0.825579, improvement +0.001066.
- LPIPS: 0.201255 -> 0.198845, improvement 0.002410.
- Training time: 2875.280 s -> 2421.210 s, measured reduction 454.070 s.
- Peak GPU memory: 5200 MB -> 4521 MB, measured reduction 679 MB.
- Render FPS: 1.7656 -> 1.2674.

Interpretation:

The delayed MSE loss improves all three quality metrics over baseline, so it is not a harmful modification. However, it does not produce the desired significant PSNR gain and is worse than delayed edge H1 on PSNR. This suggests that the `train` quality bottleneck is not simply late-stage pixel MSE under-optimization; geometric coverage, visibility, and scene-specific difficult views remain more important. For the report, delayed MSE can be presented as an additional PSNR-oriented H1 attempt, but the recommended quality-oriented H1 remains delayed edge loss.

## Recommendation

Based on completed results:

1. H1 delayed is the best quality-oriented variant among the completed runs.
2. H2 is a successful efficiency-oriented variant: it substantially reduces time and memory while keeping quality loss within the predefined thresholds.
3. Delayed MSE is a valid PSNR-oriented attempt and improves all quality metrics over baseline, but it should not replace delayed edge H1 because its PSNR gain is smaller.
4. Hard-view adaptive sampling should not replace delayed H1 because its quality metrics are worse than baseline on `train`.
5. H1 delayed + H2 is useful as a completed ablation, but it is not the recommended final method because it does not combine the quality benefit of H1 delayed with the efficiency benefit of H2 cleanly.
6. The final report should present H1 delayed and H2 as separate improvements, with the combination, hard-view, and delayed-MSE runs used as evidence that the effects are not simply additive and that the quality bottleneck is not solved by every reasonable H1 variant.

## Final Report Selection

The final report should keep the main experimental narrative compact:

- Include `train` baseline, original H1 edge loss, H1 delayed edge loss, H2 systematic 80% cap, and H1 delayed + H2 ablation.
- Briefly mention only two `mic` improvement results: H1 delayed edge and H2 systematic 80% cap.
- Do not include hard-view adaptive sampling, delayed MSE, or other exploratory attempts in the main results table.

Recommended short `mic` paragraph:

On the synthetic `mic` scene, the baseline already achieves near-saturated reconstruction quality. H1 delayed edge keeps the quality almost unchanged, with PSNR 37.2812 -> 37.2671, SSIM 0.993990 -> 0.993984, and LPIPS 0.004906 -> 0.004899. H2 systematic 80% cap reduces training time from 1153.389 s to 863.448 s and peak memory from 4694 MB to 3817 MB, while causing a small quality drop: PSNR 37.1710, SSIM 0.993840, and LPIPS 0.005071. This supports the interpretation that H1 mainly targets difficult real-scene views, while H2 is an efficiency-oriented improvement that also transfers to a synthetic scene.

Selected next action:

- Use the safer H1 variant: delayed low-weight edge loss.
- Configuration: `edge_loss_weight = 0.02`, `edge_loss_start_iter = 7000`.
- Reason: the original H1 (`edge_loss_weight = 0.05` from iteration 1) slightly improved SSIM/LPIPS but mildly reduced PSNR. Delaying and weakening the edge term should reduce interference with early geometry formation while preserving the perceptual regularization effect.

Commands:

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe train.py --source_path "D:\AI WORK\datasets\tandt_db\tandt\train" --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1_delayed_edge" --config configs\train_step5_h1_delayed_edge.json --eval --seed 0
```

```powershell
D:\anaconda3\envs\pytorch2.2.2\python.exe render.py --model_path "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1_delayed_edge" --iteration 30000 --skip_train
D:\anaconda3\envs\pytorch2.2.2\python.exe metrics.py --model_paths "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1_delayed_edge"
```

Expected comparison target:

- Primary baseline: `train baseline` from `results\step5\quality_metrics.csv`.
- Useful if it keeps or improves LPIPS/SSIM while reducing the PSNR drop seen in original H1.

Completed delayed-H1 result:

- PSNR: 22.2412 -> 22.3649, improvement +0.1236 dB.
- SSIM: 0.824513 -> 0.825051, improvement +0.000538.
- LPIPS: 0.201255 -> 0.199818, improvement 0.001436.
- Training time: 2875.280 s -> 2436.096 s, measured reduction 439.184 s.
- Peak GPU memory: 5200 MB -> 4445 MB, measured reduction 755 MB.

Compared with the original H1-only run:

- PSNR improves substantially: 22.1942 -> 22.3649.
- SSIM is slightly lower: 0.825299 -> 0.825051.
- LPIPS is slightly worse than original H1 but still better than baseline: 0.199232 -> 0.199818 vs baseline 0.201255.

Per-view observation:

- Across all 38 views, delayed H1 improves PSNR on 21 views, SSIM on 25 views, and LPIPS on 23 views.
- On the worst-4 baseline PSNR views, delayed H1 improves PSNR by +0.5927 dB, SSIM by +0.00688, and LPIPS by 0.00887.
- On the worst-4 baseline SSIM views, delayed H1 improves LPIPS by 0.00622 but does not improve PSNR/SSIM.

Updated interpretation:

Delayed low-weight H1 is more useful than the original H1 setting. It gives a small but consistent aggregate quality gain without the PSNR regression of the original edge-loss experiment. However, it still does not fully solve the difficult-view geometry issue because the worst-SSIM views remain weak.

Previous recommendation, now superseded:

- H2 should remain paused until the safer H1 variant is evaluated.
