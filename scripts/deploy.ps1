$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

& (Join-Path $PSScriptRoot "build_lambdas.ps1")

terraform -chdir="$Root\infra" init
terraform -chdir="$Root\infra" fmt
terraform -chdir="$Root\infra" validate
terraform -chdir="$Root\infra" plan -out tfplan
terraform -chdir="$Root\infra" apply tfplan

Write-Host ""
Write-Host "=== OUTPUTS ==="
terraform -chdir="$Root\infra" output
