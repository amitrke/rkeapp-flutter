param(
    [Parameter(Position = 0)]
    [string]$DeviceId = "default",

    [Parameter(Position = 1)]
    [string]$TestFile = "rke_screenshots_test.yaml"
)

$deviceConfigs = @{
    "android-phone" = @{ platform = "Android"; width = 393; height = 851 }
    "android-tablet-7" = @{ platform = "Android"; width = 600; height = 960 }
    "android-tablet-10" = @{ platform = "Android"; width = 800; height = 1280 }
    "iphone-65" = @{ platform = "iOS"; width = 428; height = 926 }
    "ipad-13" = @{ platform = "iOS"; width = 1024; height = 1366 }
    "default" = @{ platform = ""; width = 0; height = 0 }
}

if (-not $deviceConfigs.ContainsKey($DeviceId)) {
    Write-Host "Error: Unknown device ID '$DeviceId'" -ForegroundColor Red
    Write-Host "Available IDs: $($deviceConfigs.Keys -join ', ')" -ForegroundColor Yellow
    exit 1
}

if (Test-Path .\.env) {
    Get-Content .\.env | ForEach-Object {
        if ($_ -match "=" -and -not $_.StartsWith("#")) {
            $key, $value = $_.Split("=", 2)
            [System.Environment]::SetEnvironmentVariable($key.Trim(), $value.Trim(), "Process")
        }
    }
    Write-Host "Loaded .env" -ForegroundColor Green
}

$maestroCmd = Get-Command maestro -ErrorAction SilentlyContinue
if (-not $maestroCmd) {
    Write-Host "Error: Maestro CLI not found in PATH." -ForegroundColor Red
    Write-Host "Install from: https://maestro.mobile.dev/getting-started/installing-maestro" -ForegroundColor Yellow
    exit 1
}

$testPath = ".\.maestro\$TestFile"
if (-not (Test-Path $testPath)) {
    Write-Host "Error: Test file not found: $testPath" -ForegroundColor Red
    exit 1
}

$screenshotDir = "screenshots/$DeviceId"
[System.Environment]::SetEnvironmentVariable("MAESTRO_SCREENSHOT_DIR", $screenshotDir, "Process")
if (-not (Test-Path $screenshotDir)) {
    New-Item -ItemType Directory -Path $screenshotDir -Force | Out-Null
}

Write-Host "Running Maestro test" -ForegroundColor Cyan
Write-Host "  Device: $DeviceId"
Write-Host "  Test:   $TestFile"
Write-Host "  Output: $screenshotDir"

& maestro test $testPath
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "Screenshots captured successfully." -ForegroundColor Green
} else {
    Write-Host "Maestro failed with exit code $exitCode" -ForegroundColor Red
}

exit $exitCode
