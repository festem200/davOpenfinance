#!/usr/bin/env bash
# Recorre el contrato contra un mock generado desde el propio OpenAPI (Prism).
#
# Prism valida cada petición contra el esquema (encabezados requeridos, cuerpo, tipos) y
# responde con los ejemplos del contrato, validados a su vez contra los esquemas de
# respuesta. Si el contrato es incoherente, esto falla aquí — no en la lectura del
# evaluador. No prueba una implementación (no existe): prueba que el contrato se sostiene.
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

# Cuerpo de un ejemplo del contrato (campo `value` del Example Object).
ejemplo() { node -e "process.stdout.write(JSON.stringify(require('$RAIZ/api/examples/$1.json').value))"; }

# Encabezados que exige toda operación que mueve dinero.
AUTH=(-H "Authorization: Bearer token-de-prueba")
FIRMA=(-H 'Signature-Input: sig1=("@method" "@target-uri" "content-digest" "idempotency-key");created=1757548327;keyid="aliado-demo-001-2026"'
       -H 'Signature: sig1=:MEUCIQDx8n...:'
       -H 'Content-Digest: sha-256=:X48E9qOokqqrvdts8nOJRJN3OWDUoyWxBf7kbu9DBPE=:')
JSON=(-H "Content-Type: application/json")
FORM=(-H "Content-Type: application/x-www-form-urlencoded")

# verificar <descripción> <código esperado> <método> <ruta> [args extra de curl…]
verificar() {
  local desc="$1" esperado="$2" metodo="$3" ruta="$4"; shift 4
  local salida cuerpo codigo
  salida="$(curl -s -X "$metodo" -w '\n%{http_code}' "$@" "${BASE}${ruta}")"
  codigo="$(printf '%s' "$salida" | tail -n1)"
  cuerpo="$(printf '%s' "$salida" | sed '$d')"
  if [ "$codigo" = "$esperado" ]; then
    echo "  ✓ ${desc} → ${codigo}"
  else
    echo "  ✗ ${desc} → esperaba ${esperado}, obtuvo ${codigo}"
    printf '%s\n' "$cuerpo" | head -c 600; echo
    FALLAS=$((FALLAS + 1))
  fi
  ULTIMO_CUERPO="$cuerpo"
}

# campo <expresión JS sobre el último cuerpo>
campo() { node -e "const b=JSON.parse(process.argv[1]); process.stdout.write(String($1))" "$ULTIMO_CUERPO"; }

# esperar_campo <descripción> <expresión> <valor esperado>
esperar_campo() {
  local desc="$1" expr="$2" esperado="$3" real
  real="$(campo "$expr")"
  if [ "$real" = "$esperado" ]; then
    echo "    · ${desc}: ${real}"
  else
    echo "    ✗ ${desc}: esperaba '${esperado}', obtuvo '${real}'"
    FALLAS=$((FALLAS + 1))
  fi
}

echo "▶ Plano de confianza"
verificar "descubrimiento del servidor de autorización" 200 GET "/.well-known/openid-configuration"
esperar_campo "PAR obligatorio" "b.require_pushed_authorization_requests" "true"
esperar_campo "tokens vinculados al certificado" "b.tls_client_certificate_bound_access_tokens" "true"
verificar "llaves públicas (JWKS)" 200 GET "/jwks"
verificar "PAR con el consentimiento en authorization_details" 201 POST "/par" "${FORM[@]}" \
  --data-urlencode "client_id=aliado-demo-001" --data-urlencode "response_type=code" \
  --data-urlencode "redirect_uri=https://aliado.example/callback" \
  --data-urlencode "scope=consents:read payments:initiate payments:read" \
  --data-urlencode "code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM" \
  --data-urlencode "code_challenge_method=S256" \
  --data-urlencode 'authorization_details=[{"type":"payment_consent","consentId":"cns_7Kd9mQ2pLx4Rt8Vw","actions":["initiate","read"]}]'
esperar_campo "request_uri de un solo uso" "b.request_uri.startsWith('urn:ietf:params:oauth:request_uri:')" "true"
verificar "intercambio de code por token (PKCE)" 200 POST "/token" "${FORM[@]}" \
  --data-urlencode "grant_type=authorization_code" --data-urlencode "code=abc" \
  --data-urlencode "code_verifier=dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk" \
  --data-urlencode "redirect_uri=https://aliado.example/callback"
esperar_campo "token atado al consentimiento" "b.authorization_details[0].consentId" "cns_7Kd9mQ2pLx4Rt8Vw"
verificar "prueba de conexión válida" 200 GET "/connection-test" "${AUTH[@]}"
esperar_campo "token vinculado al certificado" "b.tokenBoundToCertificate" "true"
verificar "token no vinculado al certificado" 401 GET "/connection-test" "${AUTH[@]}" -H "Prefer: code=401"

echo "▶ Consentimientos"
verificar "crear consentimiento (ahorros, único)" 201 POST "/payment-consents" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: 11111111-1111-4111-8111-111111111111" --data "$(ejemplo consent-request-savings-single)"
esperar_campo "estado inicial" "b.status" "AWAITING_AUTHORISATION"
esperar_campo "identificación del tercero la pone la entidad" "typeof b.thirdParty.domicile" "string"
verificar "crear consentimiento (tarjeta, recurrente)" 201 POST "/payment-consents" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: 22222222-2222-4222-8222-222222222222" --data "$(ejemplo consent-request-card-recurring)"
verificar "consentimiento sin finalidad específica se rechaza" 422 POST "/payment-consents" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: 33333333-3333-4333-8333-333333333333" \
  --data '{"type":"SINGLE","instrumentType":"SAVINGS_ACCOUNT","amount":{"amount":"1000.00","currency":"COP"},"creditor":{"name":"X","identification":{"type":"NIT","number":"900123456-7"}},"expiresAt":"2026-09-11T00:00:00Z","remittanceInformation":"X"}'
verificar "consultar consentimiento autorizado" 200 GET "/payment-consents/cns_7Kd9mQ2pLx4Rt8Vw" "${AUTH[@]}"
esperar_campo "producto elegido por el titular, enmascarado" "b.instrument.maskedNumber" "****4821"
verificar "revocar consentimiento" 204 DELETE "/payment-consents/cns_7Kd9mQ2pLx4Rt8Vw" "${AUTH[@]}"

echo "▶ Pagos — riel cuenta de ahorros (una fase)"
verificar "cobro contra ahorros" 201 POST "/payments" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: 44444444-4444-4444-8444-444444444444" --data "$(ejemplo payment-request-savings)"
esperar_campo "liquidado de inmediato" "b.status" "SETTLED"
esperar_campo "riel" "b.settlement.rail" "ON_US"
verificar "cobro sin Idempotency-Key se rechaza" 422 POST "/payments" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  --data "$(ejemplo payment-request-savings)"
verificar "cobro con monto en punto flotante se rechaza" 422 POST "/payments" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: 55555555-5555-4555-8555-555555555555" \
  --data '{"consentId":"cns_7Kd9mQ2pLx4Rt8Vw","amount":{"amount":150000,"currency":"COP"}}'
verificar "monto distinto al consentido" 403 POST "/payments" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: 66666666-6666-4666-8666-666666666666" -H "Prefer: code=403" --data "$(ejemplo payment-request-savings)"
verificar "timeout del core → el pago existe en PENDING" 201 POST "/payments" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: 77777777-7777-4777-8777-777777777777" -H "Prefer: example=pendienteDelCore" --data "$(ejemplo payment-request-savings)"
esperar_campo "estado" "b.status" "PENDING"
esperar_campo "razón" "b.statusReason.code" "CORE_TIMEOUT"
verificar "core caído antes de enviar la orden" 503 POST "/payments" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: 88888888-8888-4888-8888-888888888888" -H "Prefer: code=503" --data "$(ejemplo payment-request-savings)"
verificar "consultar pago (fuente de verdad)" 200 GET "/payments/pay_3Hn8Zc1Qw7Lp5Ky2" "${AUTH[@]}"
verificar "listar pagos para conciliación" 200 GET "/payments?status=SETTLED&limit=50" "${AUTH[@]}"

echo "▶ Pagos — riel tarjeta de crédito (dos fases)"
verificar "autorización con captura manual y cuotas" 201 POST "/payments" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: 99999999-9999-4999-8999-999999999999" -H "Prefer: example=tarjetaAutorizada" --data "$(ejemplo payment-request-card)"
esperar_campo "estado" "b.status" "AUTHORIZED"
esperar_campo "cupo retenido, nada capturado" "b.capturedAmount.amount" "0.00"
esperar_campo "cuotas" "b.installments" "3"
verificar "captura parcial" 201 POST "/payments/pay_8Wq2Nv5Tb9Xk4Jm7/captures" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa" --data "$(ejemplo capture-request-partial)"
esperar_campo "captura procesada" "b.status" "PROCESSED"
verificar "listar capturas" 200 GET "/payments/pay_8Wq2Nv5Tb9Xk4Jm7/captures" "${AUTH[@]}"
verificar "capturar un pago cancelado → conflicto" 409 POST "/payments/pay_8Wq2Nv5Tb9Xk4Jm7/captures" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb" -H "Prefer: code=409" --data "$(ejemplo capture-request-partial)"
verificar "anular autorización" 201 POST "/payments/pay_8Wq2Nv5Tb9Xk4Jm7/cancellations" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: cccccccc-cccc-4ccc-8ccc-cccccccccccc" --data '{"reason":"ORDER_CANCELLED"}'

echo "▶ Devoluciones"
verificar "devolución parcial" 201 POST "/payments/pay_3Hn8Zc1Qw7Lp5Ky2/refunds" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: dddddddd-dddd-4ddd-8ddd-dddddddddddd" --data "$(ejemplo refund-request)"
esperar_campo "vuelve al mismo producto" "b.links.payment" "/payments/pay_3Hn8Zc1Qw7Lp5Ky2"
verificar "consultar devolución" 200 GET "/payments/pay_3Hn8Zc1Qw7Lp5Ky2/refunds/rfd_6Ym3Kd8Qp2Wx5Zn1" "${AUTH[@]}"
verificar "misma Idempotency-Key con otro cuerpo" 422 POST "/payments/pay_3Hn8Zc1Qw7Lp5Ky2/refunds" "${AUTH[@]}" "${JSON[@]}" "${FIRMA[@]}" \
  -H "Idempotency-Key: dddddddd-dddd-4ddd-8ddd-dddddddddddd" -H "Prefer: code=422" --data '{"reason":"DUPLICATE"}'

echo "▶ Métodos de pago y eventos"
verificar "métodos de pago y límites vigentes" 200 GET "/payment-methods" "${AUTH[@]}"
esperar_campo "instrumentos" "b.items.length" "2"
verificar "suscribir webhook" 201 POST "/webhooks" "${AUTH[@]}" "${JSON[@]}" \
  --data '{"url":"https://aliado.example/webhooks/pagos","events":["payment.settled","payment.rejected","consent.revoked"]}'
verificar "webhook sin https se rechaza" 400 POST "/webhooks" "${AUTH[@]}" "${JSON[@]}" \
  --data '{"url":"http://aliado.example/webhooks/pagos","events":["payment.settled"]}'
verificar "feed de eventos (recuperación)" 200 GET "/events?type=payment.settled" "${AUTH[@]}"
esperar_campo "último evento" "b.items[b.items.length-1].type" "payment.settled"
verificar "ruta inexistente" 404 GET "/no-existe"

echo
if [ "$FALLAS" -eq 0 ]; then
  echo "✓ El contrato se recorre completo sin incoherencias"
else
  echo "✗ ${FALLAS} verificación(es) fallida(s)"
fi
exit "$FALLAS"
