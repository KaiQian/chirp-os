param([ValidateSet('win-arm64','win-x64')][string]$Runtime='win-arm64')
$ErrorActionPreference='Stop'
$Root=Split-Path $PSScriptRoot -Parent
Push-Location $Root
try {
    dotnet run --project platforms/windows/ChirpOS.Tests -c Release
    if ($LASTEXITCODE -ne 0) { throw 'Core verification failed' }
    $Output=Join-Path $Root "dist/windows/$Runtime"
    dotnet publish platforms/windows/ChirpOS/ChirpOS.csproj -c Release -r $Runtime --self-contained true -o $Output
    if ($LASTEXITCODE -ne 0) { throw 'Windows build failed' }
    Copy-Item LICENSE "$Output/LICENSE.txt"
    Copy-Item platforms/windows/Verify-Windows.cmd "$Output/Verify-Windows.cmd"
    Copy-Item platforms/windows/README.md "$Output/README.md"
    New-Item -ItemType Directory -Force dist/releases | Out-Null
    Copy-Item "$Output/ChirpOS.exe" "dist/releases/ChirpOS-0.3.1-$Runtime.exe" -Force
} finally { Pop-Location }
