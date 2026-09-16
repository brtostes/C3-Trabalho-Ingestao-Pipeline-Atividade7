$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Infra = Join-Path $Root "infra"

$InputBucket = terraform -chdir="$Infra" output -raw input_bucket_name
$OutputBucket = terraform -chdir="$Infra" output -raw output_bucket_name

Write-Host "Bucket entrada: $InputBucket"
Write-Host "Bucket saida:   $OutputBucket"

Write-Host "`n=== 1. Enviando referencia ==="
aws s3 cp (Join-Path $Root "sample\referencia\referencia.csv") "s3://$InputBucket/referencia/referencia.csv"

Write-Host "Aguardando processamento da referencia..."
Start-Sleep -Seconds 15

Write-Host "`n=== 2. Enviando eventos ==="
aws s3 cp (Join-Path $Root "sample\eventos\eventos.csv") "s3://$InputBucket/eventos/eventos.csv"

Write-Host "Aguardando processamento dos eventos..."
Start-Sleep -Seconds 20

Write-Host "`n=== 3. Objetos produzidos ==="
aws s3 ls "s3://$OutputBucket/processed/" --recursive
