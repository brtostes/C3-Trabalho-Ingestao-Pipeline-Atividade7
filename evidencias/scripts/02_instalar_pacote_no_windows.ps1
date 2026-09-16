param(
    [string]$PacoteZip = "$env:USERPROFILE\Downloads\Atividade6_Evidencias_Pacote.zip",
    [string]$DestinoProjeto = "D:\GitHub\C3-Trabalho-Ingestao-Pipeline-Atividade7"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PacoteZip)) {
    Write-Host "Arquivo não encontrado: $PacoteZip" -ForegroundColor Red
    Write-Host "Informe o caminho correto, por exemplo:" -ForegroundColor Yellow
    Write-Host '.\02_instalar_pacote_no_windows.ps1 -PacoteZip "C:\Users\SEU_USUARIO\Downloads\Atividade6_Evidencias_Pacote.zip"'
    exit 1
}

if (-not (Test-Path $DestinoProjeto)) {
    New-Item -ItemType Directory -Path $DestinoProjeto -Force | Out-Null
}

Expand-Archive -Path $PacoteZip -DestinationPath $DestinoProjeto -Force

$DestinoEvidencias = Join-Path $DestinoProjeto "evidencias"

Write-Host ""
Write-Host "Pacote instalado com sucesso." -ForegroundColor Green
Write-Host "Projeto:    $DestinoProjeto"
Write-Host "Evidências: $DestinoEvidencias"
Write-Host ""

Get-ChildItem $DestinoEvidencias -Recurse -File |
    Select-Object FullName, Length |
    Format-Table -AutoSize
