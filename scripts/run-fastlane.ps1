param(
    [Parameter(Position = 0)]
    [string]$Action,

    [Parameter(Position = 1)]
    [string]$KeyPath,

    [Parameter(Position = 2)]
    [string]$Track = "internal"
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

$AndroidPackageNameDefault = "org.roorkee"
$IosAppIdentifierDefault = "org.roorkee"

function Show-Usage {
    @"
Usage:
  .\scripts\run-fastlane.ps1 android-screenshots <play_store_key_json_path>
  .\scripts\run-fastlane.ps1 android-metadata <play_store_key_json_path> [track]
    .\scripts\run-fastlane.ps1 android-diagnose <play_store_key_json_path>
  .\scripts\run-fastlane.ps1 ios-metadata
  .\scripts\run-fastlane.ps1 ios-submit

Actions:
  android-screenshots  Upload Android screenshots (Fastlane lane: android upload_screenshots)
  android-metadata     Upload Android store listing metadata (lane: android upload_metadata)
    android-diagnose     Diagnose Android Play app state (lane: android diagnose_play_state)
  ios-metadata         Upload iOS metadata (lane: ios upload_metadata)
  ios-submit           Submit iOS app for review (lane: ios submit_for_review)

Required env vars for iOS actions:
  APP_STORE_CONNECT_KEY_ID
  APP_STORE_CONNECT_ISSUER_ID
  APP_STORE_CONNECT_API_KEY   (base64-encoded p8 content)

Optional env vars:
  ANDROID_PACKAGE_NAME (default: org.roorkee)
    PLAY_STORE_VERSION_CODE (required only to upload Android changelogs)
  IOS_APP_IDENTIFIER   (default: org.roorkee)
"@
}

function Require-File {
    param([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        throw "Error: File not found: $FilePath"
    }
}

function Require-Env {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace((Get-Item -Path "Env:$Name" -ErrorAction SilentlyContinue).Value)) {
        throw "Error: Required environment variable is missing: $Name"
    }
}

function Add-GemUserBinToPath {
    $rubyCommand = Get-Command ruby -ErrorAction SilentlyContinue
    if (-not $rubyCommand) {
        return
    }

    $gemUserDir = & ruby -e "print Gem.user_dir"
    if ([string]::IsNullOrWhiteSpace($gemUserDir)) {
        return
    }

    $gemUserBin = Join-Path $gemUserDir "bin"
    if ((Test-Path -LiteralPath $gemUserBin -PathType Container) -and -not (($env:PATH -split ';') -contains $gemUserBin)) {
        $env:PATH = "$gemUserBin;$env:PATH"
    }
}

function Ensure-Bundle {
    Add-GemUserBinToPath

    $bundleCommand = Get-Command bundle -ErrorAction SilentlyContinue
    if (-not $bundleCommand) {
        $gemCommand = Get-Command gem -ErrorAction SilentlyContinue
        if (-not $gemCommand) {
            throw "Error: RubyGems (gem) is not installed or not in PATH."
        }

        Write-Host "Bundler not found. Installing bundler..."
        & gem install bundler --no-document
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }

        Add-GemUserBinToPath
        $bundleCommand = Get-Command bundle -ErrorAction SilentlyContinue
    }

    if (-not $bundleCommand) {
        throw "Error: bundler installed but still not in PATH. Try restarting the shell, then re-run this script."
    }

    & bundle install
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

function Run-AndroidScreenshots {
    param([string]$JsonKeyPath)

    Require-File $JsonKeyPath

    $env:SUPPLY_JSON_KEY = (Resolve-Path -LiteralPath $JsonKeyPath).ProviderPath
    $env:ANDROID_PACKAGE_NAME = if ($env:ANDROID_PACKAGE_NAME) { $env:ANDROID_PACKAGE_NAME } else { $AndroidPackageNameDefault }

    Ensure-Bundle
    & bundle exec fastlane android upload_screenshots
    exit $LASTEXITCODE
}

function Run-AndroidMetadata {
    param(
        [string]$JsonKeyPath,
        [string]$ReleaseTrack
    )

    Require-File $JsonKeyPath

    $env:SUPPLY_JSON_KEY = (Resolve-Path -LiteralPath $JsonKeyPath).ProviderPath
    $env:ANDROID_PACKAGE_NAME = if ($env:ANDROID_PACKAGE_NAME) { $env:ANDROID_PACKAGE_NAME } else { $AndroidPackageNameDefault }
    $env:PLAY_STORE_TRACK = $ReleaseTrack

    Ensure-Bundle
    & bundle exec fastlane android upload_metadata
    exit $LASTEXITCODE
}

function Run-AndroidDiagnose {
    param([string]$JsonKeyPath)

    Require-File $JsonKeyPath

    $env:SUPPLY_JSON_KEY = (Resolve-Path -LiteralPath $JsonKeyPath).ProviderPath
    $env:ANDROID_PACKAGE_NAME = if ($env:ANDROID_PACKAGE_NAME) { $env:ANDROID_PACKAGE_NAME } else { $AndroidPackageNameDefault }

    Ensure-Bundle
    & bundle exec fastlane android diagnose_play_state
    exit $LASTEXITCODE
}

function Run-IosMetadata {
    Require-Env "APP_STORE_CONNECT_KEY_ID"
    Require-Env "APP_STORE_CONNECT_ISSUER_ID"
    Require-Env "APP_STORE_CONNECT_API_KEY"

    $env:IOS_APP_IDENTIFIER = if ($env:IOS_APP_IDENTIFIER) { $env:IOS_APP_IDENTIFIER } else { $IosAppIdentifierDefault }

    Ensure-Bundle
    & bundle exec fastlane ios upload_metadata
    exit $LASTEXITCODE
}

function Run-IosSubmit {
    Require-Env "APP_STORE_CONNECT_KEY_ID"
    Require-Env "APP_STORE_CONNECT_ISSUER_ID"
    Require-Env "APP_STORE_CONNECT_API_KEY"

    $env:IOS_APP_IDENTIFIER = if ($env:IOS_APP_IDENTIFIER) { $env:IOS_APP_IDENTIFIER } else { $IosAppIdentifierDefault }

    Ensure-Bundle
    & bundle exec fastlane ios submit_for_review
    exit $LASTEXITCODE
}

switch ($Action) {
    "android-screenshots" {
        if ([string]::IsNullOrWhiteSpace($KeyPath)) {
            Show-Usage
            exit 1
        }
        Run-AndroidScreenshots $KeyPath
    }
    "android-metadata" {
        if ([string]::IsNullOrWhiteSpace($KeyPath)) {
            Show-Usage
            exit 1
        }
        Run-AndroidMetadata $KeyPath $Track
    }
    "android-diagnose" {
        if ([string]::IsNullOrWhiteSpace($KeyPath)) {
            Show-Usage
            exit 1
        }
        Run-AndroidDiagnose $KeyPath
    }
    "ios-metadata" {
        Run-IosMetadata
    }
    "ios-submit" {
        Run-IosSubmit
    }
    { $_ -in @("-h", "--help", "help", $null, "") } {
        Show-Usage
    }
    default {
        Write-Host "Error: Unknown action '$Action'"
        Show-Usage
        exit 1
    }
}