#!/usr/bin/env bash
# prepare_pptx.sh — Copia um .pptx para assets/presentation.pptx e compila
#
# Uso:
#   chmod +x scripts/prepare_pptx.sh
#   ./scripts/prepare_pptx.sh <arquivo.pptx> [--build] [--base-href /repo/]
#
# Exemplos:
#   ./scripts/prepare_pptx.sh ~/Documentos/aula.pptx
#   ./scripts/prepare_pptx.sh aula.pptx --build --base-href /minha-aula/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$PROJECT_ROOT/assets"
DESTINATION="$ASSETS_DIR/presentation.pptx"

PPTX_PATH=""
BASE_HREF="/"
DO_BUILD=false

for arg in "$@"; do
  case "$arg" in
    --build)      DO_BUILD=true ;;
    --base-href=*)BASE_HREF="${arg#*=}" ;;
    --base-href)  ;;
    *)
      if [ -z "$PPTX_PATH" ]; then PPTX_PATH="$arg"; fi
      ;;
  esac
done

# Captura --base-href valor
prev=""
for arg in "$@"; do
  if [ "$prev" = "--base-href" ]; then BASE_HREF="$arg"; fi
  prev="$arg"
done

if [ -z "$PPTX_PATH" ]; then
  echo "Uso: $0 <arquivo.pptx> [--build] [--base-href /repo/]" >&2
  exit 1
fi

if [ ! -f "$PPTX_PATH" ]; then
  echo "Erro: arquivo nao encontrado: $PPTX_PATH" >&2
  exit 1
fi

mkdir -p "$ASSETS_DIR"
echo "? Copiando: $(basename "$PPTX_PATH")"
echo "  ? $DESTINATION"
cp "$PPTX_PATH" "$DESTINATION"
echo "  OK: $(du -k "$DESTINATION" | cut -f1) KB copiados"

if $DO_BUILD; then
  echo ""
  echo "? Compilando: flutter build web --wasm --base-href $BASE_HREF --release"
  cd "$PROJECT_ROOT"
  flutter build web --wasm --base-href "$BASE_HREF" --release
  echo ""
  echo "? Build concluido! Pasta pronta para publicar: build/web/"
  echo ""
  echo "  Para testar localmente:"
  echo "    cd build/web && python3 -m http.server 8080"
else
  echo ""
  echo "? Asset atualizado. Para compilar:"
  echo "    flutter build web --wasm --base-href $BASE_HREF --release"
  echo "  Ou: $0 $PPTX_PATH --build"
fi