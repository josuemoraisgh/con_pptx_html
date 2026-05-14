#!/usr/bin/env bash
# prepare_pptx.sh - Copia um .pptx para assets/presentation.pptx e compila
#
# Uso:
#   chmod +x scripts/prepare_pptx.sh
#   ./scripts/prepare_pptx.sh <arquivo.pptx> [--build] [--base-href /repo/]
#
# Exemplos:
#   ./scripts/prepare_pptx.sh ~/Documentos/aula.pptx
#   ./scripts/prepare_pptx.sh aula.pptx --build --base-href /minha-aula/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$PROJECT_ROOT/assets"
DESTINATION="$ASSETS_DIR/presentation.pptx"

PPTX_PATH=""
BASE_HREF="/"
DO_BUILD=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --build)
      DO_BUILD=true
      shift
      ;;
    --base-href=*)
      BASE_HREF="${1#*=}"
      shift
      ;;
    --base-href)
      if [ "$#" -lt 2 ]; then
        echo "Erro: --base-href requer um valor" >&2
        exit 1
      fi
      BASE_HREF="$2"
      shift 2
      ;;
    -*)
      echo "Erro: opcao desconhecida: $1" >&2
      exit 1
      ;;
    *)
      if [ -n "$PPTX_PATH" ]; then
        echo "Erro: informe apenas um arquivo .pptx" >&2
        exit 1
      fi
      PPTX_PATH="$1"
      shift
      ;;
  esac
done

if [ -z "$PPTX_PATH" ]; then
  echo "Uso: $0 <arquivo.pptx> [--build] [--base-href /repo/]" >&2
  exit 1
fi

if [ ! -f "$PPTX_PATH" ]; then
  echo "Erro: arquivo nao encontrado: $PPTX_PATH" >&2
  exit 1
fi

case "${PPTX_PATH##*.}" in
  pptx|PPTX) ;;
  *)
    echo "Erro: o arquivo deve ter extensao .pptx: $PPTX_PATH" >&2
    exit 1
    ;;
esac

mkdir -p "$ASSETS_DIR"
echo "-> Copiando: $(basename "$PPTX_PATH")"
echo "   $DESTINATION"
cp "$PPTX_PATH" "$DESTINATION"
echo "  OK: $(du -k "$DESTINATION" | cut -f1) KB copiados"

if $DO_BUILD; then
  echo ""
  echo "-> Compilando: flutter build web --wasm --base-href $BASE_HREF --release"
  cd "$PROJECT_ROOT"
  flutter build web --wasm --base-href "$BASE_HREF" --release
  echo ""
  echo "OK: Build concluido! Pasta pronta para publicar: build/web/"
  echo ""
  echo "  Para testar localmente:"
  echo "    cd build/web && python3 -m http.server 8080"
else
  echo ""
  echo "OK: Asset atualizado. Para compilar:"
  echo "    flutter build web --wasm --base-href $BASE_HREF --release"
  echo "  Ou: $0 $PPTX_PATH --build"
fi
