# run_suite.ps1 — build, elaborate, then run the active (passing) benchmarks
#
# Usage (from project root):
#   .\test\run_suite.ps1              # run all active benchmarks
#   .\test\run_suite.ps1 -Only branch # run one benchmark
#   .\test\run_suite.ps1 -NoRebuild   # skip recompile/elaborate

param(
    [string]$Only      = "",
    [switch]$NoRebuild
)

$ErrorActionPreference = "Stop"

$VivadoBin = "C:\AMDDesignTools\2025.2.1\Vivado\bin"
$XsimDir   = (Resolve-Path "$PSScriptRoot\..\riscv_soc.sim\sim_1\behav\xsim").Path
$TestDir   = $PSScriptRoot
$Make      = "C:\msys64\ucrt64\bin\mingw32-make.exe"

$env:PATH  = "$VivadoBin;$env:PATH"

# ── 1. Build all text.dat files ─────────────────────────────────────────────
$benchmarks = @("median","multiply","memcpy","branch")
if ($Only) { $benchmarks = @($Only) }

Write-Host "`n[build] Generating text.dat for all benchmarks..." -ForegroundColor Cyan
foreach ($bm in $benchmarks) {
    & $Make -C "$TestDir\$bm" all 2>&1 | Where-Object { $_ -match "^python|error|Error" } | Write-Host
}

# ── 2. Recompile + elaborate ────────────────────────────────────────────────
if (-not $NoRebuild) {
    Write-Host "`n[compile] xvlog..." -ForegroundColor Cyan
    Push-Location $XsimDir
    $c = cmd /c "$XsimDir\compile.bat" 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "compile.bat failed:`n$c"; Pop-Location; exit 1 }

    Write-Host "[elaborate] xelab..." -ForegroundColor Cyan
    $e = cmd /c "$XsimDir\elaborate.bat" 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "elaborate.bat failed:`n$e"; Pop-Location; exit 1 }
    Pop-Location
}

# ── 3. Expected a0 values per benchmark ─────────────────────────────────────
$expectedA0 = @{
    "median"   = 0
    "multiply" = 0
    "memcpy"   = 0
    "branch"   = 6765   # fib(20) = 6765, left in a0 at halt
}

# ── 4. Run each benchmark ────────────────────────────────────────────────────
Write-Host ""
$results = @()

foreach ($bm in $benchmarks) {
    $datFile = "$TestDir\$bm\text.dat"
    if (-not (Test-Path $datFile)) { Write-Warning ("{0}: no text.dat, skipping" -f $bm); continue }

    Copy-Item $datFile "$XsimDir\text.dat" -Force

    Push-Location $XsimDir
    try {
        $proc = Start-Process -FilePath xsim -ArgumentList "top_behav","-tclbatch","run.tcl","-log","simulate.log" -Wait -NoNewWindow -PassThru
        $log = Get-Content simulate.log -ErrorAction SilentlyContinue -Raw

        $cyclesLine = $log | Select-String "#cycles = (\d+)"
        $a0Line     = $log | Select-String "a0 \(verify result\)\s*=\s*(\d+)"
        $branchLine = $log | Select-String "Branch accuracy\s*=\s*([\d.]+)%"

        $cycles  = if ($cyclesLine)  { [int]$cyclesLine.Matches[0].Groups[1].Value  } else { -1 }
        $a0      = if ($a0Line)      { [int]$a0Line.Matches[0].Groups[1].Value      } else { -9999 }
        $branchAcc = if ($branchLine) { $branchLine.Matches[0].Groups[1].Value + "%" } else { "N/A" }

        $expect = $expectedA0[$bm]
        $pass   = ($a0 -eq $expect)
        $status = if ($pass) { "PASS" } else { "FAIL (a0=$a0, expected $expect)" }
        $color  = if ($pass) { "Green" } else { "Red" }

        Write-Host ("[{0,-8}]  {1,-35}  {2,5} cycles   branch_acc={3}" -f `
            $bm, $status, $cycles, $branchAcc) -ForegroundColor $color

        $results += [pscustomobject]@{
            Benchmark  = $bm
            Pass       = $pass
            Cycles     = $cycles
            BranchAcc  = $branchAcc
            A0         = $a0
            ExpectedA0 = $expect
        }
    }
    finally {
        Pop-Location
    }
}

# ── 5. Summary ───────────────────────────────────────────────────────────────
$passed = ($results | Where-Object Pass).Count
$total  = $results.Count
Write-Host "`n$passed / $total benchmarks PASSED" -ForegroundColor $(if ($passed -eq $total) {"Green"} else {"Yellow"})

# Leave text.dat as median (safe default)
Copy-Item "$TestDir\median\text.dat" "$XsimDir\text.dat" -Force
