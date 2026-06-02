@echo off
REM ── Configuracoes ───────────────────────────────────────────────────────────
REM Altere as variaveis abaixo antes de usar

set REPO_URL=https://github.com/inindi-ufu/II1E05_CondSinais.git
set BASE_HREF=/II1E05_CondSinais/

REM ── Build ───────────────────────────────────────────────────────────────────
echo [1/3] Compilando PPTX...
dart run tool/build_web.dart

echo [2/3] Build Flutter WASM com base-href...
flutter build web --wasm --base-href %BASE_HREF%

REM ── Deploy ──────────────────────────────────────────────────────────────────
echo [3/3] Publicando no GitHub Pages...
cd build\web

if not exist ".git" (
    git init
    git remote add origin %REPO_URL%
)

git checkout -B gh-pages
git add -A
git commit -m "deploy: %date% %time%"
git push -f origin gh-pages

cd ..\..
echo.
echo ✓ Publicado em: https://inindi-ufu.github.io/II1E05_CondSinais/
pause
