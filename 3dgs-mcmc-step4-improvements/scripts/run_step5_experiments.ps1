$ErrorActionPreference = "Stop"

$Root = "D:\AI WORK\3dgs-mcmc-step4-improvements"
$Python = "D:\anaconda3\envs\pytorch2.2.2\python.exe"
$Results = Join-Path $Root "results\step5"
$Logs = Join-Path $Root "logs"
$StatusFile = Join-Path $Results "current_status.txt"
$TrainingCsv = Join-Path $Results "training_efficiency.csv"
$RenderCsv = Join-Path $Results "render_efficiency.csv"

New-Item -ItemType Directory -Force -Path $Results, $Logs | Out-Null
"scene,variant,model_path,config,seed,start_time,end_time,duration_seconds,peak_gpu_mem_mb,exit_code" | Set-Content -LiteralPath $TrainingCsv -Encoding UTF8
"scene,variant,model_path,rendered_images,start_time,end_time,duration_seconds,render_fps,exit_code" | Set-Content -LiteralPath $RenderCsv -Encoding UTF8

$Experiments = @(
    @{
        Scene = "mic";
        Variant = "baseline";
        Source = "D:\AI WORK\datasets\nerf_synthetic\mic";
        Model = "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\mic_baseline_seed0";
        Config = "configs\mic_step5_baseline_seed0.json";
    },
    @{
        Scene = "mic";
        Variant = "h1h2_edge_systematic_80cap";
        Source = "D:\AI WORK\datasets\nerf_synthetic\mic";
        Model = "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\mic_h1h2_edge_systematic_80cap";
        Config = "configs\mic_step5_h1h2_edge_systematic_80cap.json";
    },
    @{
        Scene = "train";
        Variant = "baseline";
        Source = "D:\AI WORK\datasets\tandt_db\tandt\train";
        Model = "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_baseline_seed0";
        Config = "configs\train_step5_baseline_seed0.json";
    },
    @{
        Scene = "train";
        Variant = "h1_edge";
        Source = "D:\AI WORK\datasets\tandt_db\tandt\train";
        Model = "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1_edge";
        Config = "configs\train_step5_h1_edge.json";
    },
    @{
        Scene = "train";
        Variant = "h2_systematic_80cap";
        Source = "D:\AI WORK\datasets\tandt_db\tandt\train";
        Model = "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h2_systematic_80cap";
        Config = "configs\train_step5_h2_systematic_80cap.json";
    },
    @{
        Scene = "train";
        Variant = "h1h2_edge_systematic_80cap";
        Source = "D:\AI WORK\datasets\tandt_db\tandt\train";
        Model = "D:\AI WORK\3dgs-mcmc-step4-improvements\output\step5\train_h1h2_edge_systematic_80cap";
        Config = "configs\train_step5_h1h2_edge_systematic_80cap.json";
    }
)

function Get-GpuMemoryMb {
    try {
        $value = & nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>$null
        if ($LASTEXITCODE -eq 0 -and $value) {
            return [int]($value | Select-Object -First 1)
        }
    } catch {
        return -1
    }
    return -1
}

function Quote-CmdArg {
    param([string]$Arg)
    return '"' + ($Arg -replace '"', '\"') + '"'
}

function Start-CmdProcess {
    param(
        [string[]]$Arguments,
        [string]$StdoutPath,
        [string]$StderrPath
    )

    $quotedArgs = @((Quote-CmdArg $Python))
    foreach ($arg in $Arguments) {
        $quotedArgs += Quote-CmdArg $arg
    }
    $cmdLine = ($quotedArgs -join " ") + " > " + (Quote-CmdArg $StdoutPath) + " 2> " + (Quote-CmdArg $StderrPath)
    return Start-Process -FilePath "cmd.exe" -ArgumentList @("/d", "/c", $cmdLine) -WorkingDirectory $Root -WindowStyle Hidden -PassThru
}

function Run-MonitoredProcess {
    param(
        [string]$Name,
        [string[]]$Arguments,
        [string]$StdoutPath,
        [string]$StderrPath,
        [string]$GpuMemPath
    )

    "timestamp,gpu_mem_mb" | Set-Content -LiteralPath $GpuMemPath -Encoding UTF8
    $start = Get-Date
    $proc = Start-CmdProcess -Arguments $Arguments -StdoutPath $StdoutPath -StderrPath $StderrPath
    $peakMem = 0

    while (-not $proc.HasExited) {
        $mem = Get-GpuMemoryMb
        if ($mem -gt $peakMem) {
            $peakMem = $mem
        }
        "$(Get-Date -Format o),$mem" | Add-Content -LiteralPath $GpuMemPath -Encoding UTF8
        Start-Sleep -Seconds 5
    }

    $proc.WaitForExit()
    $end = Get-Date
    return [PSCustomObject]@{
        Start = $start
        End = $end
        DurationSeconds = [Math]::Round(($end - $start).TotalSeconds, 3)
        PeakGpuMemMb = $peakMem
        ExitCode = $proc.ExitCode
    }
}

foreach ($exp in $Experiments) {
    $name = "$($exp.Scene)_$($exp.Variant)"
    "TRAINING $name" | Set-Content -LiteralPath $StatusFile -Encoding UTF8
    $trainStdout = Join-Path $Logs "step5_${name}_train.out.log"
    $trainStderr = Join-Path $Logs "step5_${name}_train.err.log"
    $gpuLog = Join-Path $Results "gpu_mem_${name}.csv"

    $trainArgs = @(
        "train.py",
        "--source_path", $exp.Source,
        "--model_path", $exp.Model,
        "--config", $exp.Config,
        "--eval",
        "--seed", "0"
    )
    $trainResult = Run-MonitoredProcess -Name $name -Arguments $trainArgs -StdoutPath $trainStdout -StderrPath $trainStderr -GpuMemPath $gpuLog
    "$($exp.Scene),$($exp.Variant),`"$($exp.Model)`",$($exp.Config),0,$($trainResult.Start.ToString("o")),$($trainResult.End.ToString("o")),$($trainResult.DurationSeconds),$($trainResult.PeakGpuMemMb),$($trainResult.ExitCode)" | Add-Content -LiteralPath $TrainingCsv -Encoding UTF8
    if ($trainResult.ExitCode -ne 0) {
        "FAILED TRAINING $name" | Set-Content -LiteralPath $StatusFile -Encoding UTF8
        exit $trainResult.ExitCode
    }

    "RENDERING $name" | Set-Content -LiteralPath $StatusFile -Encoding UTF8
    $renderStdout = Join-Path $Logs "step5_${name}_render.out.log"
    $renderStderr = Join-Path $Logs "step5_${name}_render.err.log"
    $renderStart = Get-Date
    $renderProc = Start-CmdProcess -Arguments @("render.py", "--model_path", $exp.Model, "--iteration", "30000", "--skip_train") -StdoutPath $renderStdout -StderrPath $renderStderr
    $renderProc.WaitForExit()
    $renderEnd = Get-Date
    $renderDuration = [Math]::Round(($renderEnd - $renderStart).TotalSeconds, 3)
    $renderDir = Join-Path $exp.Model "test\ours_30000\renders"
    $renderCount = 0
    if (Test-Path -LiteralPath $renderDir) {
        $renderCount = (Get-ChildItem -LiteralPath $renderDir -File | Measure-Object).Count
    }
    $renderFps = 0.0
    if ($renderDuration -gt 0) {
        $renderFps = [Math]::Round($renderCount / $renderDuration, 4)
    }
    "$($exp.Scene),$($exp.Variant),`"$($exp.Model)`",$renderCount,$($renderStart.ToString("o")),$($renderEnd.ToString("o")),$renderDuration,$renderFps,$($renderProc.ExitCode)" | Add-Content -LiteralPath $RenderCsv -Encoding UTF8
    if ($renderProc.ExitCode -ne 0) {
        "FAILED RENDER $name" | Set-Content -LiteralPath $StatusFile -Encoding UTF8
        exit $renderProc.ExitCode
    }

    "METRICS $name" | Set-Content -LiteralPath $StatusFile -Encoding UTF8
    $metricsStdout = Join-Path $Logs "step5_${name}_metrics.out.log"
    $metricsStderr = Join-Path $Logs "step5_${name}_metrics.err.log"
    $metricsProc = Start-CmdProcess -Arguments @("metrics.py", "--model_paths", $exp.Model) -StdoutPath $metricsStdout -StderrPath $metricsStderr
    $metricsProc.WaitForExit()
    if ($metricsProc.ExitCode -ne 0) {
        "FAILED METRICS $name" | Set-Content -LiteralPath $StatusFile -Encoding UTF8
        exit $metricsProc.ExitCode
    }
}

"DONE" | Set-Content -LiteralPath $StatusFile -Encoding UTF8
