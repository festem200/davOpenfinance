#!/usr/bin/env bash
# Recorre el contrato contra un mock generado desde el propio OpenAPI (Prism).
#
# Prism valida cada petición contra el esquema y responde según el contrato: si el
# contrato es incoherente, esto falla aquí — no en la lectura del evaluador.
# No prueba la implementación (no existe): prueba que el contrato se sostiene.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUERTO="${PUERTO_MOCK:-4010}"
BASE="http://127.0.0.1:${PUERTO}"
LOG="$(mktemp)"
FALLAS=0

limpiar() {
  if [ -n "${PRISM_PID:-}" ]; then
    kill "$PRISM_PID" 2>/dev/null
    wait "$PRISM_PID" 2>/dev/null
  fi
  rm -f "$LOG"
}
trap limpiar EXIT

echo "▶ Levantando mock desde api/openapi.yaml…"
npx prism mock "$RAIZ/api/openapi.yaml" --errors --port "$PUERTO" >"$LOG" 2>&1 &
PRISM_PID=$!

# El mock exige autenticación, así que "listo" es cualquier respuesta HTTP, no solo 2xx.
listo=""
for _ in $(seq 1 40); do
  if [ "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/connection-test")" != "000" ]; then
    listo="si"; break
  fi
  sleep 0.5
done
if [ -z "$listo" ]; then
  echo "✗ El mock no respondió. Salida de Prism:"; cat "$LOG"; exit 1
fi

# verificar <descripción> <código esperado> <ruta> [args extra de curl…]
verificar() {
  local desc="$1" esperado="$2" ruta="$3"; shift 3
  local cuerpo codigo
  cuerpo="$(curl -s -w '\n%{http_code}' "$@" "${BASE}${ruta}")"
  codigo="$(printf '%s' "$cuerpo" | tail -n1)"
  if [ "$codigo" = "$esperado" ]; then
    echo "  ✓ ${desc} → ${codigo}"
  else
    echo "  ✗ ${desc} → esperaba ${esperado}, obtuvo ${codigo}"
    printf '%s\n' "$cuerpo" | head -n -1 | head -c 400
    FALLAS=$((FALLAS + 1))
  fi
}

echo "▶ Plano de confianza"
verificar "prueba de conexión válida" 200 "/connection-test" \
  -H "Authorization: Bearer token-de-prueba"
verificar "token no vinculado al certificado" 401 "/connection-test" \
  -H "Prefer: code=401"
verificar "ruta inexistente" 404 "/no-existe"

echo
if [ "$FALLAS" -eq 0 ]; then
  echo "✓ El contrato se recorre completo sin incoherencias"
else
  echo "✗ ${FALLAS} verificación(es) fallida(s)"
fi
exit "$FALLAS"
