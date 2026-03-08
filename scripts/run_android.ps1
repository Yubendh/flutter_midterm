$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..")

function Get-SdkRoot {
  $candidates = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "$env:ANDROID_SDK_ROOT",
    "$env:ANDROID_HOME"
  )

  foreach ($c in $candidates) {
    if (-not [string]::IsNullOrWhiteSpace($c) -and (Test-Path $c)) {
      return $c
    }
  }

  throw "Android SDK not found. Set ANDROID_SDK_ROOT or install Android Studio SDK."
}

$sdk = Get-SdkRoot
$adb = Join-Path $sdk "platform-tools\adb.exe"
$emu = Join-Path $sdk "emulator\emulator.exe"

if (-not (Test-Path $adb)) { throw "adb.exe not found at: $adb" }
if (-not (Test-Path $emu)) { throw "emulator.exe not found at: $emu" }

$env:PATH = (Join-Path $sdk "platform-tools") + ";" + $env:PATH

$gradleFile = if (Test-Path "android\app\build.gradle.kts") {
  "android\app\build.gradle.kts"
} elseif (Test-Path "android\app\build.gradle") {
  "android\app\build.gradle"
} else {
  $null
}

$appId = "com.example.flutter_midterm"
if ($gradleFile) {
  $content = Get-Content $gradleFile -Raw
  $match = [regex]::Match($content, 'applicationId\s*=?\s*"([^"]+)"')
  if ($match.Success) {
    $appId = $match.Groups[1].Value
  }
}

Write-Host "Using SDK: $sdk"
Write-Host "Using appId: $appId"

& $adb start-server | Out-Null

# Quick cleanup first.
& $adb uninstall $appId 2>$null | Out-Null
& $adb shell pm clear $appId 2>$null | Out-Null
& $adb shell pm trim-caches 4G | Out-Null

$deviceLine = & $adb devices | Select-String "emulator-\d+\s+device" | Select-Object -First 1
if ($deviceLine) {
  $deviceId = ($deviceLine.ToString() -split "\s+")[0]
  Write-Host "Stopping running emulator: $deviceId"
  & $adb -s $deviceId emu kill | Out-Null
  Start-Sleep -Seconds 2
}

$avd = (& $emu -list-avds | Select-Object -First 1).Trim()
if ([string]::IsNullOrWhiteSpace($avd)) {
  throw "No AVD found. Create an emulator in Android Studio Device Manager."
}

Write-Host "Starting emulator with wipe-data: $avd"
Start-Process -FilePath $emu -ArgumentList "-avd `"$avd`" -wipe-data -no-snapshot-load" | Out-Null

Write-Host "Waiting for emulator..."
& $adb wait-for-device
Start-Sleep -Seconds 10

flutter clean
flutter pub get
flutter run
