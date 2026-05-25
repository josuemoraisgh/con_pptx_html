param(
    [string]$PptxPath = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent $scriptDir

if ([string]::IsNullOrWhiteSpace($PptxPath)) {
    $PptxPath = Join-Path $projectRoot "assets\presentation.pptx"
} elseif (-not [System.IO.Path]::IsPathRooted($PptxPath)) {
    $PptxPath = Join-Path (Get-Location) $PptxPath
}

if (-not (Test-Path $PptxPath)) {
    Write-Error "Arquivo PPTX nao encontrado: $PptxPath"
    exit 1
}

if ((Get-Item $PptxPath).Extension.ToLower() -ne ".pptx") {
    Write-Error "O arquivo deve ter extensao .pptx: $PptxPath"
    exit 1
}

Push-Location $projectRoot
try {
    Write-Host ""
    Write-Host "1/2 Gerando lib/generated/presentation_data.g.dart"
    Write-Host "    PPTX: $PptxPath"
    $env:PPTX_INPUT = $PptxPath
    flutter test tool/compile_pptx.dart
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao gerar presentation_data.g.dart"
    }

    Write-Host ""
    Write-Host "2/2 Compilando web"
    Write-Host "    flutter build web --wasm"
    flutter build web --wasm
    if ($LASTEXITCODE -ne 0) {
        throw "Falha no flutter build web --wasm"
    }

    Write-Host ""
    Write-Host "OK: build\web atualizado."
} finally {
    Remove-Item Env:\PPTX_INPUT -ErrorAction SilentlyContinue
    Pop-Location
}
