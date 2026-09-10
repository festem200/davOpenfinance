# Mapeo REST ↔ SOAP

Cómo cada operación de la fachada REST ([`api/openapi.yaml`](../../api/openapi.yaml)) se
traduce a operaciones del BUS ([`bus-pagos.wsdl`](./bus-pagos.wsdl), ilustrativo) y de
vuelta. Es el contrato interno del **adaptador SOAP** — la única pieza del sistema que
conoce el BUS. Por norma, el BUS nunca se expone hacia afuera: la SFC prohíbe SOAP en las
APIs del sistema de finanzas abiertas.

---

## 1. Operaciones

| Operación REST | Operación(es) SOAP | Notas |
|---|---|---|
| `POST /payment-consents` | — | No toca el core. El consentimiento vive en el servicio de pagos hasta que el titular lo autoriza |
| Confirmación del titular (AS) | `ValidarTitularidad` | Al autorizar, el titular elige su producto; se valida que le pertenece y está `ACTIVO` antes de marcar el consentimiento `AUTHORISED` |
| `POST /payments` (`SAVINGS_ACCOUNT`) | `ValidarTitularidad` → `DebitarCuenta` | Una fase. `ValidarTitularidad` se repite en cada cobro: el producto pudo bloquearse después del consentimiento |
| `POST /payments` (`CREDIT_CARD`) | `ValidarTitularidad` → `AutorizarTarjeta` [→ `CapturarAutorizacion` si `captureMode: AUTOMATIC`] | Dos fases |
| `POST /payments/{id}/captures` | `CapturarAutorizacion` | Parcial o total |
| `POST /payments/{id}/cancellations` | `AnularAutorizacion` | Solo sin capturas |
| `POST /payments/{id}/refunds` | `ReversarTransaccion` | Contra la transacción original del core |
| `GET /payments/{id}` | `ConsultarTransaccion` solo si el pago está `PENDING` | En cualquier otro estado se responde desde la base local; el core no se consulta en lecturas |
| `GET /payment-methods` | — | Límites cacheados desde parámetros del core (refresco periódico, no en línea) |
| Reconciliación nocturna | `ConsultarTransaccion` por cada `PENDING` mayor a N minutos | Cierra el ciclo de todo timeout |

## 2. Campos — `POST /payments` → `DebitarCuenta`

| REST (`PaymentRequest` + contexto) | SOAP (`DebitarCuentaRequest`) | Transformación |
|---|---|---|
| `Idempotency-Key` (encabezado) | `idTransaccion` | `sha256(clientId + Idempotency-Key)` truncado a 32 → el mismo reintento produce el mismo id en el core |
| `traceparent` | `cabecera.idCorrelacion` | Se propaga tal cual; si no viene, se genera |
| `client_id` (del token) | `cabecera.idAliado` | Del `sub` del JWT, nunca del cuerpo |
| — | `cabecera.canal` | Constante `OPENFINANCE` |
| — | `cabecera.usuario` | Identidad del titular resuelta del consentimiento (para el log de 5 años) |
| `consentId` → `consent.instrument.productReference` | `producto.tokenProducto` | La referencia opaca se resuelve al token del core **dentro del adaptador**; el aliado nunca ve el número |
| `consent.instrumentType` | `producto.tipoProducto` | `SAVINGS_ACCOUNT → CAH`, `CREDIT_CARD → TCR` |
| `amount.amount` (`"150000.00"`) | `monto` (`xsd:decimal` 150000.00) | Cadena → decimal exacto. **Nunca** pasa por `double` |
| `amount.currency` | `moneda` | Debe ser `COP`; cualquier otra falla antes de llamar |
| `consent.creditor.identification` | `beneficiario` | Tipo y número |
| `client_id` → registro del aliado | `cuentaBeneficiario` | La cuenta recaudadora sale del **registro**, no del request: un aliado no puede desviar un cobro a otra cuenta |
| `remittanceInformation` (o el del consentimiento) | `referencia` | Se normaliza a mayúsculas sin tildes, máx. 140; el core suele truncar a 40 en el extracto — se documenta al aliado |
| `consentId` | `idConsentimiento` | Para auditoría cruzada |

## 3. Campos — respuesta `DebitarCuentaResponse` → `Payment`

| SOAP | REST | Regla |
|---|---|---|
| `respuesta.codigoRetorno = 00` y `estadoTransaccion = APLICADA` | `status: CAPTURED` (o `SETTLED` si `ON_US`) | Éxito |
| `codigoRetorno = 00` y `estadoTransaccion = EN_PROCESO` | `status: PENDING`, `statusReason.code: PROCESSING` | El riel liquidará después; se cierra por evento o reconciliación |
| `codigoRetorno ≠ 00` (o `FallaNegocio`) | `status: REJECTED`, `statusReason.code` según tabla §5 | Nunca se expone `codigoRetorno` crudo |
| `respuesta.idTransaccionCore` | `settlement.reference` | Referencia para conciliar con el extracto |
| `respuesta.fechaHoraCore` | `settlement.settledAt` | Zona horaria del core → UTC |
| `gmfAplicado` | No se expone en `Payment` | Va al log de auditoría; el GMF es entre el titular y la entidad, no un dato del aliado |

## 4. Idempotencia en dos niveles

```
Aliado ──Idempotency-Key──▶ Fachada REST ──idTransaccion──▶ BUS
                                  │
                                  └─ registro de idempotencia (24 h): clave → respuesta
```

1. **Fachada:** misma clave + mismo cuerpo → se devuelve la respuesta guardada, `Idempotency-Replayed: true`, **cero** llamadas al core. Misma clave + cuerpo distinto → `422`.
2. **Core:** `idTransaccion` se deriva de la clave. Si la fachada perdió la respuesta (caída entre el `DebitarCuenta` y el guardado), un reintento llega al core con el mismo `idTransaccion` y este responde la transacción original en vez de aplicarla dos veces — **siempre que el BUS soporte idempotencia por `idTransaccion`**, que es uno de los insumos a confirmar.

## 5. Mapeo de fallas

| Origen | Ejemplo | REST | ¿Reintentar? |
|---|---|---|---|
| **Fault de negocio** (`FallaNegocio`, código conocido) | Fondos insuficientes, producto bloqueado, cupo excedido, límite diario | `201` con `status: REJECTED` y `statusReason.code` ∈ {`INSUFFICIENT_FUNDS`, `PRODUCT_BLOCKED`, `LIMIT_EXCEEDED`, `CARD_DECLINED`} | No — es una decisión del core |
| **Fault de negocio con código desconocido** | Código nuevo que no está en el catálogo | `201` con `REJECTED` y `statusReason.code: DECLINED`; alerta interna para catalogarlo | No |
| **Fault técnico** (SOAP Fault `Receiver`, HTTP 5xx del BUS) **antes de enviar** la orden (circuito abierto, conexión rechazada) | BUS caído | `503` + `Retry-After` | Sí, misma clave |
| **Timeout** después de enviar la orden | El BUS no respondió en el presupuesto | `201` con `status: PENDING`, `statusReason.code: CORE_TIMEOUT`; se programa `ConsultarTransaccion` | **No el POST.** Consultar `GET /payments/{id}` |
| Respuesta **malformada** (XML inválido, esquema distinto) | Cambio no anunciado en el BUS | `201` con `PENDING` + `CORE_TIMEOUT` (se trata como desconocido) y alerta crítica | No el POST |
| **Falla de seguridad** hacia el BUS (WS-Security rechazado, certificado vencido) | Rotación no coordinada | `503` + alerta crítica — la orden no salió | Sí, tras corregir |

**Regla de oro:** la fachada solo reintenta contra el core lo que es idempotente por diseño
(`ConsultarTransaccion`, `ValidarTitularidad`). Una orden que ya pudo ejecutarse **jamás se
reenvía**; se consulta.

## 6. Protocolo del timeout

```
Fachada                                   BUS
  │  DebitarCuenta(idTransaccion=T)        │
  ├───────────────────────────────────────▶│
  │        … presupuesto agotado …         │   (el débito pudo aplicarse)
  │  201 PENDING al aliado                 │
  │                                        │
  │  ConsultarTransaccion(T)  [t+30s]      │
  ├───────────────────────────────────────▶│
  │◀───────────────────────────────────────┤ existe=true, APLICADA
  │  → SETTLED + evento payment.settled    │
  │                                        │
  │  (si existe=false tras N intentos      │
  │   en la ventana del core)              │
  │  → FAILED + evento payment.failed      │
```

Si el BUS **no ofrece** `ConsultarTransaccion` por `idTransaccion` de la fachada, este
protocolo no puede implementarse y el diseño queda con un hueco de doble cobro. Por eso es
el insumo **bloqueante** de la respuesta 4 (`docs/respuestas.md`, *Insumos de integración*).

## 7. Seguridad hacia el BUS

| Capa | Mecanismo |
|---|---|
| Canal | mTLS con certificado interno de la fachada (PKI de la entidad) |
| Mensaje | WS-Security: firma del `Body` con X.509, `Timestamp` con ventana de 5 min |
| Credenciales | Solo en el gestor de secretos; rotación sin reinicio |
| Datos | El adaptador registra en el log los 5 campos exigidos (origen, momento, usuario, información circulada, estado), con `tokenProducto` y `referencia` enmascarados |
