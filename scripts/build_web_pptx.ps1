param(
    [string]$PptxPath = ""
)

$ErrorActionPreference = "Stop"

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent $scriptDir

# ── Resolve o caminho do PPTX ──────────────────────────────────────────────────
if ([string]::IsNullOrWhiteSpace($PptxPath)) {
    # 1) Lê .pptx_source (salvo por prepare_pptx.ps1 na última preparação)
    $sourceFile = Join-Path $projectRoot ".pptx_source"
    if (Test-Path $sourceFile) {
        $saved = (Get-Content $sourceFile -Raw -Encoding UTF8).Trim()
        if (-not [string]::IsNullOrWhiteSpace($saved)) {
            $PptxPath = $saved
            if (-not [System.IO.Path]::IsPathRooted($PptxPath)) {
                $PptxPath = Join-Path $projectRoot $PptxPath
            }
            Write-Host "Usando PPTX de .pptx_source: $PptxPath" -ForegroundColor Cyan
        }
    }
    # 2) Fallback: assets\presentation.pptx
    if ([string]::IsNullOrWhiteSpace($PptxPath)) {
        $PptxPath = Join-Path $projectRoot "assets\presentation.pptx"
    }
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

    # Passa o caminho via --dart-define (compile-time) E env var (runtime).
    # O --dart-define garante que String.fromEnvironment funcione mesmo quando
    # o flutter test nao herda variaveis de ambiente corretamente no Windows.
    $env:PPTX_INPUT = $PptxPath
    flutter test tool/compile_pptx.dart "--dart-define=PPTX_INPUT=$PptxPath"
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
    Write-Host "    Fonte: $PptxPath"
} finally {
    Remove-Item Env:\PPTX_INPUT -ErrorAction SilentlyContinue
    Pop-Location
}
