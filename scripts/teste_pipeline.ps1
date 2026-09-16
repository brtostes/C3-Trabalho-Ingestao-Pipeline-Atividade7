$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Infra = Join-Path $Root "infra"

$InputBucket = terraform -chdir="$Infra" output -raw input_bucket_name
$OutputBucket = terraform -chdir="$Infra" output -raw output_bucket_name
$QueueUrl = terraform -chdir="$Infra" output -raw queue_url
$DlqUrl = terraform -chdir="$Infra" output -raw dlq_url

$Antes = @(aws s3 ls "s3://$OutputBucket/processed/" --recursive 2>$null).Count
$TesteId = Get-Date -Format "yyyyMMdd-HHmmss"
$Destino = "s3://$InputBucket/eventos/eventos-$TesteId.csv"

Write-Host "Bucket entrada : $InputBucket"
Write-Host "Bucket saida   : $OutputBucket"
Write-Host "Objetos antes  : $Antes"
Write-Host "Arquivo teste  : $Destino"

Write-Host "`n=== 1. Upload do CSV ==="
aws s3 cp (Join-Path $Root "sample\eventos\eventos.csv") $Destino

Write-Host "`n=== 2. Verificacao da fila principal ==="
Start-Sleep -Seconds 5
aws sqs get-queue-attributes `
  --queue-url $QueueUrl `
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible

Write-Host "`n=== 3. Verificacao da DLQ ==="
aws sqs get-queue-attributes `
  --queue-url $DlqUrl `
  --attribute-names ApproximateNumberOfMessages

Write-Host "`n=== 4. Objetos produzidos ==="
$Depois = @(aws s3 ls "s3://$OutputBucket/processed/" --recursive).Count
aws s3 ls "s3://$OutputBucket/processed/" --recursive

Write-Host "`nResumo:"
Write-Host "Antes : $Antes"
Write-Host "Depois: $Depois"
Write-Host "Novos : $($Depois - $Antes)"
