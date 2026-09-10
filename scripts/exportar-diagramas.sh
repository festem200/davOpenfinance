#!/usr/bin/env bash
# Exporta cada diagrama de draw.io a PNG. Un XML mal formado falla aquí, no en la
# vista del evaluador. Requiere la app de draw.io instalada (CLI en /opt/homebrew/bin/drawio).
set -euo pipefail

DRAWIO="${DRAWIO_BIN:-drawio}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docs/diagrams"

if ! command -v "$DRAWIO" >/dev/null 2>&1; then
  echo "✗ No se encontró el CLI de draw.io. Instala la app o exporta DRAWIO_BIN." >&2
  exit 1
fi

shopt -s nullglob
for f in "$DIR"/*.drawio; do
  out="${f%.drawio}.png"
  echo "→ $(basename "$f")"
  "$DRAWIO" --export --format png --scale 2 --border 10 --output "$out" "$f"
done
echo "✓ Diagramas exportados"
