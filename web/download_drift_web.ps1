$webDir = "$PSScriptRoot"
$ProgressPreference = 'SilentlyContinue'

Write-Host "Downloading sqlite3.wasm (sqlite3 2.4.5)..."
Invoke-WebRequest -Uri "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.4.5/sqlite3.wasm" -OutFile "$webDir\sqlite3.wasm"

Write-Host "Downloading drift_worker.js (drift 2.19.1)..."
Invoke-WebRequest -Uri "https://github.com/simolus3/drift/releases/download/drift-2.19.1/drift_worker.js" -OutFile "$webDir\drift_worker.js"

Write-Host "Done! Files downloaded to: $webDir"
Get-ChildItem "$webDir\sqlite3.wasm", "$webDir\drift_worker.js" | Select-Object Name, Length
