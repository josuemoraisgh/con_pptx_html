param(
    [int]$Port = 8080,
    [string]$WebDir = "build/web",
    [string]$DbPath = "local/app.db",
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent $scriptDir
Push-Location $projectRoot

try {
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        throw "Python nao encontrado no PATH. Instale Python 3 e tente novamente."
    }

    $webDirFull = Join-Path $projectRoot $WebDir
    if (-not (Test-Path $webDirFull)) {
        throw "Diretorio web nao encontrado: $webDirFull`nExecute 'flutter build web' antes de iniciar o servidor."
    }

    $url = "http://127.0.0.1:$Port"
    Write-Host "Iniciando servidor em $url ..." -ForegroundColor Cyan
    Write-Host "  Web:    $webDirFull" -ForegroundColor Gray
    Write-Host "  SQLite: $(Join-Path $projectRoot $DbPath)" -ForegroundColor Gray
    Write-Host "  Pressione Ctrl+C para encerrar." -ForegroundColor Gray

    if (-not $NoBrowser) {
        # Abre o browser apos 1 segundo (tempo para o servidor subir).
        $openJob = Start-Job {
            param($u)
            Start-Sleep -Seconds 1
            Start-Process $u
        } -ArgumentList $url
    }

    python -u .\scripts\local_web_sqlite_server.py --port $Port --web-dir $WebDir --db-path $DbPath
}
finally {
    if ($openJob) { Remove-Job -Job $openJob -Force -ErrorAction SilentlyContinue }
    Pop-Location
}
