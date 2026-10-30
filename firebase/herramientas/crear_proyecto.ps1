# Crea el proyecto de Firebase de TiGuard (se ejecuta una sola vez).
$ErrorActionPreference = 'Continue'
$fb = 'C:\Users\santi\AppData\Roaming\npm\firebase.cmd'
Set-Location (Split-Path $PSScriptRoot)
Start-Transcript -Path "$PSScriptRoot\registro.txt" -Force | Out-Null

$id = 'acceso-remoto-' + (Get-Random -Minimum 1000 -Maximum 9999)
Write-Host "=== 1. Proyecto $id"
& $fb projects:create $id --display-name 'TiGuard' --non-interactive
if ($LASTEXITCODE -ne 0) { Write-Host 'FALLO_PROYECTO'; Stop-Transcript; exit 1 }
Set-Content -Path 'proyecto.txt' -Value $id

Write-Host '=== 2. App Android'
& $fb apps:create ANDROID 'TiGuard' --package-name co.edu.umanizales.acceso_remoto --project $id --non-interactive
$apps = & $fb apps:list ANDROID --project $id --json | ConvertFrom-Json
$appId = $apps.result[0].appId
Write-Host "appId: $appId"
& $fb apps:sdkconfig ANDROID $appId --project $id --out '..\app\android\app\google-services.json' --non-interactive

Write-Host '=== 3. Realtime Database'
& $fb database:instances:create "$id-default-rtdb" --location us-central1 --project $id --non-interactive

Write-Host '=== 4. Reglas e inicio de sesion con correo'
& $fb deploy --only database --project $id --non-interactive
& $fb deploy --only auth --project $id --non-interactive

Write-Host '=== LISTO'
Stop-Transcript | Out-Null
