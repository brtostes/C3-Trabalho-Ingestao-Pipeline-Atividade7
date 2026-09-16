$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
terraform -chdir="$Root\infra" destroy
