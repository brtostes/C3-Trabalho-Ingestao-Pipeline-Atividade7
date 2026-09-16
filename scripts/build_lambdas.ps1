$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Dist = Join-Path $Root "dist"
$Build = Join-Path $Root ".build"

if (Test-Path $Build) { Remove-Item $Build -Recurse -Force }
if (Test-Path $Dist) { Remove-Item $Dist -Recurse -Force }

New-Item -ItemType Directory -Force -Path $Build | Out-Null
New-Item -ItemType Directory -Force -Path $Dist | Out-Null

Write-Host "=== Producer ==="
$ProducerBuild = Join-Path $Build "producer"
New-Item -ItemType Directory -Force -Path $ProducerBuild | Out-Null
Copy-Item (Join-Path $Root "lambdas\producer\lambda_function.py") $ProducerBuild
Compress-Archive -Path "$ProducerBuild\*" -DestinationPath (Join-Path $Dist "producer.zip") -Force

Write-Host "=== Consumer ==="
$ConsumerBuild = Join-Path $Build "consumer"
New-Item -ItemType Directory -Force -Path $ConsumerBuild | Out-Null
Copy-Item (Join-Path $Root "lambdas\consumer\lambda_function.py") $ConsumerBuild
python -m pip install `
    -r (Join-Path $Root "lambdas\consumer\requirements.txt") `
    --target $ConsumerBuild `
    --upgrade

Compress-Archive -Path "$ConsumerBuild\*" -DestinationPath (Join-Path $Dist "consumer.zip") -Force

Write-Host ""
Write-Host "Pacotes gerados:"
Get-ChildItem $Dist
