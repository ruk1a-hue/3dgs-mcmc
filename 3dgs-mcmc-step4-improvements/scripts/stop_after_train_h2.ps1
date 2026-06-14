$ErrorActionPreference = "SilentlyContinue"

$Root = "D:\AI WORK\3dgs-mcmc-step4-improvements"
$Step5 = Join-Path $Root "results\step5"
$StatusPath = Join-Path $Step5 "current_status.txt"
$QualityPath = Join-Path $Step5 "quality_metrics.csv"
$RunnerPidPath = Join-Path $Step5 "runner.pid"
$WatchLog = Join-Path $Step5 "stop_after_train_h2.log"

if (-not (Test-Path -LiteralPath $RunnerPidPath)) {
    "$(Get-Date -Format o) no runner pid file" | Add-Content -LiteralPath $WatchLog
    exit 0
}

$RunnerPid = [int](Get-Content -LiteralPath $RunnerPidPath)
$Runner = Get-Process -Id $RunnerPid
$RunnerStart = $Runner.StartTime
"$(Get-Date -Format o) watching runner $RunnerPid" | Add-Content -LiteralPath $WatchLog

while ($true) {
    $status = ""
    if (Test-Path -LiteralPath $StatusPath) {
        $status = Get-Content -LiteralPath $StatusPath -Raw
    }

    $quality = ""
    if (Test-Path -LiteralPath $QualityPath) {
        $quality = Get-Content -LiteralPath $QualityPath -Raw
    }

    if ($quality -match "train,h2_systematic_80cap" -or $status -match "train_h1h2_edge_systematic_80cap") {
        "$(Get-Date -Format o) stopping after H2; status=$status" | Add-Content -LiteralPath $WatchLog
        Get-Process python | Where-Object { $_.StartTime -ge $RunnerStart.AddSeconds(-2) } | Stop-Process -Force
        exit 0
    }

    $Runner = Get-Process -Id $RunnerPid
    if (-not $Runner) {
        "$(Get-Date -Format o) runner already stopped" | Add-Content -LiteralPath $WatchLog
        exit 0
    }

    Start-Sleep -Seconds 3
}
