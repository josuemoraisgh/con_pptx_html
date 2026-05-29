param(
    [int]$Port = 8080,
    [string]$DbPath = "local/app.db"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent $scriptDir
Push-Location $projectRoot

try {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        throw "Python nao encontrado no PATH. Instale Python 3 e tente novamente."
    }

    python .\scripts\local_web_sqlite_server.py --port $Port --db-path $DbPath
}
finally {
    Pop-Location
}
