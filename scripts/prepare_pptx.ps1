<#
.SYNOPSIS
    Prepara um arquivo .pptx para ser compilado diretamente no app Flutter.

.DESCRIPTION
    1. Copia o .pptx para assets/presentation.pptx
    2. Regenera lib/generated/presentation_data.g.dart
    3. Opcionalmente executa: flutter build web --wasm --release

.PARAMETER PptxPath
    Caminho para o arquivo .pptx de origem (relativo ou absoluto).

.PARAMETER BasePath
    Base URL para o app (padrao: "/"). Use "/" para o root do GitHub Pages
    ou "/nome-do-repositorio/" para repositorios de projeto.

.PARAMETER Build
    Se especificado, executa flutter build web --wasm apos regenerar o Dart.

.EXAMPLE
    .\scripts\prepare_pptx.ps1 -PptxPath "aula01.pptx" -Build
    .\scripts\prepare_pptx.ps1 -PptxPath "C:\Aulas\fisica.pptx" -BasePath "/fisica/" -Build
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PptxPath,

    [string]$BasePath = "/",

    [switch]$Build
)

$ErrorActionPreference = "Stop"

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent $scriptDir
$assetsDir   = Join-Path $projectRoot "assets"
$destination = Join-Path $assetsDir "presentation.pptx"

if (-not [System.IO.Path]::IsPathRooted($PptxPath)) {
    $PptxPath = Join-Path (Get-Location) $PptxPath
}

if (-not (Test-Path $PptxPath)) {
    Write-Error "Arquivo nao encontrado: $PptxPath"
    exit 1
}

if ((Get-Item $PptxPath).Extension.ToLower() -ne ".pptx") {
    Write-Error "O arquivo deve ter extensao .pptx: $PptxPath"
    exit 1
}

if (-not (Test-Path $assetsDir)) {
    New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null
}

Write-Host "→ Copiando: $(Split-Path -Leaf $PptxPath)"
Write-Host "  → $destination"
Copy-Item -Path $PptxPath -Destination $destination -Force

$sizeKB = [int]((Get-Item $destination).Length / 1024)
Write-Host "  OK: $sizeKB KB copiados"

# Salva o caminho original em .pptx_source para que build_web_pptx.ps1
# saiba qual PPTX é o ativo sem precisar de -PptxPath.
$sourceFile = Join-Path $projectRoot ".pptx_source"
Set-Content -Path $sourceFile -Value $PptxPath -Encoding UTF8
Write-Host "  .pptx_source atualizado: $PptxPath"

Write-Host ""
Write-Host "→ Gerando lib/generated/presentation_data.g.dart"
Push-Location $projectRoot
try {
    $env:PPTX_INPUT = $PptxPath
    flutter test tool/compile_pptx.dart "--dart-define=PPTX_INPUT=$PptxPath"
    if ($LASTEXITCODE -ne 0) { throw "compilacao do PPTX falhou (exit $LASTEXITCODE)" }
} finally {
    Remove-Item Env:\PPTX_INPUT -ErrorAction SilentlyContinue
    Pop-Location
}

if ($Build) {
    Write-Host ""
    Write-Host "→ Compilando: flutter build web --wasm --base-href $BasePath --release"
    Push-Location $projectRoot
    try {
        flutter build web --wasm --base-href $BasePath --release
        if ($LASTEXITCODE -ne 0) { throw "flutter build falhou (exit $LASTEXITCODE)" }
        Write-Host ""
        Write-Host "✓ Build concluido! Pasta pronta para publicar: build\web\"
        Write-Host ""
        Write-Host "  Para testar localmente:"
        Write-Host "    cd build\web"
        Write-Host "    python -m http.server 8080"
        Write-Host "    # Abra: http://localhost:8080"
    } finally {
        Pop-Location
    }
} else {
    Write-Host ""
    Write-Host "✓ PPTX compilado para Dart. Para gerar build/web:"
    Write-Host "    flutter build web --wasm --base-href $BasePath --release"
    Write-Host "  Ou execute este script com a flag -Build."
}
