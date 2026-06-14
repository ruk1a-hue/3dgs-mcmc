import csv
import json
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(r"D:\AI WORK\3dgs-mcmc-step4-improvements")
PYTHON = Path(r"D:\anaconda3\envs\pytorch2.2.2\python.exe")
RESULTS = ROOT / "results" / "step5"
LOGS = ROOT / "logs"
STATUS = RESULTS / "current_status.txt"
TRAINING_CSV = RESULTS / "training_efficiency.csv"
RENDER_CSV = RESULTS / "render_efficiency.csv"
METRICS_CSV = RESULTS / "quality_metrics.csv"

EXPERIMENTS = [
    {
        "scene": "mic",
        "variant": "h1_delayed_edge",
        "source": r"D:\AI WORK\datasets\nerf_synthetic\mic",
        "model": r"D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\mic_h1_delayed_edge",
        "config": r"configs\mic_step5_h1_delayed_edge.json",
    },
    {
        "scene": "mic",
        "variant": "h2_systematic_80cap",
        "source": r"D:\AI WORK\datasets\nerf_synthetic\mic",
        "model": r"D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\mic_h2_systematic_80cap",
        "config": r"configs\mic_step5_h2_systematic_80cap.json",
    },
    {
        "scene": "mic",
        "variant": "h1delayed_h2_systematic_80cap",
        "source": r"D:\AI WORK\datasets\nerf_synthetic\mic",
        "model": r"D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\mic_h1delayed_h2_systematic_80cap",
        "config": r"configs\mic_step5_h1delayed_h2_systematic_80cap.json",
    },
]


def now_iso():
    return datetime.now(timezone.utc).astimezone().isoformat()


def write_status(text):
    STATUS.write_text(text + "\n", encoding="utf-8")


def gpu_mem_mb():
    try:
        completed = subprocess.run(
            ["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if completed.returncode == 0 and completed.stdout.strip():
            return int(completed.stdout.strip().splitlines()[0].strip())
    except Exception:
        pass
    return -1


def append_row(path, fieldnames, row):
    exists = path.exists()
    with path.open("a", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if not exists:
            writer.writeheader()
        writer.writerow(row)


def run_monitored(args, stdout_path, stderr_path, gpu_log_path):
    start = time.time()
    start_iso = now_iso()
    peak = 0
    with stdout_path.open("w", encoding="utf-8", errors="replace") as stdout, stderr_path.open(
        "w", encoding="utf-8", errors="replace"
    ) as stderr, gpu_log_path.open("w", encoding="utf-8", newline="") as gpu_file:
        writer = csv.writer(gpu_file)
        writer.writerow(["timestamp", "gpu_mem_mb"])
        proc = subprocess.Popen(args, cwd=ROOT, stdout=stdout, stderr=stderr)
        while proc.poll() is None:
            mem = gpu_mem_mb()
            peak = max(peak, mem)
            writer.writerow([now_iso(), mem])
            gpu_file.flush()
            time.sleep(5)
        code = proc.returncode
    end = time.time()
    return {
        "start_time": start_iso,
        "end_time": now_iso(),
        "duration_seconds": round(end - start, 3),
        "peak_gpu_mem_mb": peak,
        "exit_code": code,
    }


def run_plain(args, stdout_path, stderr_path):
    start = time.time()
    start_iso = now_iso()
    with stdout_path.open("w", encoding="utf-8", errors="replace") as stdout, stderr_path.open(
        "w", encoding="utf-8", errors="replace"
    ) as stderr:
        completed = subprocess.run(args, cwd=ROOT, stdout=stdout, stderr=stderr)
    end = time.time()
    return {
        "start_time": start_iso,
        "end_time": now_iso(),
        "duration_seconds": round(end - start, 3),
        "exit_code": completed.returncode,
    }


def read_metrics(model_path):
    data = json.loads((Path(model_path) / "results.json").read_text(encoding="utf-8"))
    return data["ours_30000"]


def main():
    RESULTS.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)

    for exp in EXPERIMENTS:
        name = f"{exp['scene']}_{exp['variant']}"
        model = Path(exp["model"])

        write_status(f"TRAINING {name}")
        train_result = run_monitored(
            [
                str(PYTHON),
                "train.py",
                "--source_path",
                exp["source"],
                "--model_path",
                exp["model"],
                "--config",
                exp["config"],
                "--eval",
                "--seed",
                "0",
            ],
            LOGS / f"step5_{name}_train.out.log",
            LOGS / f"step5_{name}_train.err.log",
            RESULTS / f"gpu_mem_{name}.csv",
        )
        append_row(
            TRAINING_CSV,
            [
                "scene",
                "variant",
                "model_path",
                "config",
                "seed",
                "start_time",
                "end_time",
                "duration_seconds",
                "peak_gpu_mem_mb",
                "exit_code",
            ],
            {
                "scene": exp["scene"],
                "variant": exp["variant"],
                "model_path": exp["model"],
                "config": exp["config"],
                "seed": 0,
                **train_result,
            },
        )
        if train_result["exit_code"] != 0:
            write_status(f"FAILED TRAINING {name}")
            raise SystemExit(train_result["exit_code"])

        write_status(f"RENDERING {name}")
        render_result = run_plain(
            [str(PYTHON), "render.py", "--model_path", exp["model"], "--iteration", "30000", "--skip_train"],
            LOGS / f"step5_{name}_render.out.log",
            LOGS / f"step5_{name}_render.err.log",
        )
        render_dir = model / "test" / "ours_30000" / "renders"
        rendered_images = len(list(render_dir.glob("*.png"))) if render_dir.exists() else 0
        render_fps = rendered_images / render_result["duration_seconds"] if render_result["duration_seconds"] > 0 else 0
        append_row(
            RENDER_CSV,
            [
                "scene",
                "variant",
                "model_path",
                "rendered_images",
                "start_time",
                "end_time",
                "duration_seconds",
                "render_fps",
                "exit_code",
            ],
            {
                "scene": exp["scene"],
                "variant": exp["variant"],
                "model_path": exp["model"],
                "rendered_images": rendered_images,
                "render_fps": round(render_fps, 4),
                **render_result,
            },
        )
        if render_result["exit_code"] != 0:
            write_status(f"FAILED RENDER {name}")
            raise SystemExit(render_result["exit_code"])

        write_status(f"METRICS {name}")
        metrics_result = run_plain(
            [str(PYTHON), "metrics.py", "--model_paths", exp["model"]],
            LOGS / f"step5_{name}_metrics.out.log",
            LOGS / f"step5_{name}_metrics.err.log",
        )
        if metrics_result["exit_code"] != 0:
            write_status(f"FAILED METRICS {name}")
            raise SystemExit(metrics_result["exit_code"])

        metrics = read_metrics(exp["model"])
        append_row(
            METRICS_CSV,
            ["scene", "variant", "model_path", "psnr", "ssim", "lpips"],
            {
                "scene": exp["scene"],
                "variant": exp["variant"],
                "model_path": exp["model"],
                "psnr": metrics["PSNR"],
                "ssim": metrics["SSIM"],
                "lpips": metrics["LPIPS"],
            },
        )

    write_status("DONE mic_ablation")


if __name__ == "__main__":
    main()
