# Auditoría de seguridad — diseño de la API de Pagos Open Finance

> Auditoría **del diseño**, no de una implementación: aquí no hay código que ejecute nada.
> Se auditó el contrato [`api/openapi.yaml`](../api/openapi.yaml), el mapeo hacia el BUS
> ([`contracts/soap/mapeo-rest-soap.md`](../contracts/soap/mapeo-rest-soap.md)) y las
> decisiones de [`respuestas.md`](./respuestas.md). Cada hallazgo se ancla a un endpoint o
> esquema concreto y describe qué debe quedar escrito en el contrato o exigido a la
> implementación para cerrarlo. Lo que no pudo confirmarse contra algo ejecutable se marca así.

**Estándares:** OWASP API Security Top 10 **2023** (revalidado el 10-sep-2026 contra
`owasp.org/www-project-api-security`: sigue siendo la edición vigente, publicada el
5-jun-2023) · CWE (MITRE) · FAPI 2.0 Security Profile (Final).
**Revisado:** los 23 endpoints del contrato (7 del plano de confianza, 16 del plano de
negocio), el webhook saliente, los esquemas de entrada, los esquemas de seguridad, el mapeo
REST↔SOAP y el protocolo del timeout.
**No revisado:** implementación (no existe), configuración de despliegue real, dependencias
de una implementación, el Authorization Server (se asume producto certificado FAPI 2.0),
pruebas dinámicas contra un entorno (solo existe el mock de Prism, que no aplica autorización
real). Todo hallazgo es **análisis estático del diseño**.
**Severidad máxima encontrada:** medium

---

### [MEDIUM] La URL de webhook permite SSRF hacia la red interna si la implementación no la restringe

- **Dónde:** [`api/openapi.yaml`](../api/openapi.yaml) — `POST /webhooks`, esquema `WebhookRequest.url` (`format: uri`, `pattern: ^https://`)
- **Clasificación:** API7:2023 Server Side Request Forgery · CWE-918
- **Ataque:** un aliado registra `https://bus.interno.entidad-financiera.example/pagos/v1` (o cualquier host de la zona de datos) como URL de webhook. El servicio de eventos, que vive **dentro** de la red lógicamente separada, hace un `POST` firmado a esa dirección con cada evento. Aunque el cuerpo no lo controle el atacante, obtiene un sondeo de la red interna (qué hosts responden, con qué código, en cuánto tiempo) y, si algún servicio interno acepta `POST` sin autenticación, una escritura. Variante: la URL resuelve a una IP pública al registrar y a una privada al entregar (*DNS rebinding*).
- **Confirmado:** No — análisis del contrato. La restricción `^https://` bloquea `http`/`file`, no destinos.
- **Corrección:** dejar escrito en el contrato y exigir en la implementación: (1) resolver el nombre y **rechazar** rangos privados, *loopback*, *link-local* y metadatos de nube, tanto al registrar como **en cada entrega** (re-resolver); (2) no seguir redirecciones; (3) salir a Internet por un egreso dedicado sin ruta a la zona de aplicación ni de datos; (4) limitar el tamaño y tiempo de la respuesta leída (ya hay 5 s); (5) opcionalmente, exigir que el host de la URL pertenezca a un dominio declarado en el *Software Statement* del aliado.
- **Estado:** ✅ **corregido en el contrato** — la descripción de `POST /webhooks` fija los destinos permitidos, la re-resolución en cada entrega, sin redirecciones y egreso aislado. Queda como requisito verificable para la implementación.

### [MEDIUM] El registro dinámico no ata el *Software Statement* al certificado del solicitante

- **Dónde:** [`api/openapi.yaml`](../api/openapi.yaml) — `POST /register`, esquema `RegistroClienteRequest.software_statement`
- **Clasificación:** API2:2023 Broken Authentication · CWE-287
- **Ataque:** el contrato exige mTLS y un `software_statement` firmado, pero no dice que el JWT deba **identificar el certificado** con el que se presenta. Un *Software Statement* filtrado (un correo reenviado, un repositorio del aliado) más cualquier certificado válido de una CA reconocida por la Ley 527 permitiría registrar un `client_id` con los scopes del aliado legítimo. El certificado prueba "soy alguien acreditado"; no prueba "soy el aliado al que se le emitió este SSA".
- **Confirmado:** No — análisis del contrato.
- **Corrección:** el SSA debe llevar la huella del certificado de transporte autorizado (`x5t#S256`) o el `jwks_uri` cuyo dueño se verificó en el alta, un `exp` corto, un `jti` de un solo uso, y el AS debe comparar la huella del SSA con la del certificado de la conexión antes de emitir el `client_id`. Documentarlo en la descripción de `/register`.
- **Estado:** ✅ **corregido en el contrato** — `/register` y `software_statement` exigen `x5t#S256`, `exp` corto, `jti` de un solo uso y comparación con el certificado de la conexión.

### [MEDIUM] `customerHint.identification` puede convertirse en un oráculo de enumeración de clientes

- **Dónde:** [`api/openapi.yaml`](../api/openapi.yaml) — `POST /payment-consents`, `PaymentConsentRequest.customerHint.identification` (flujo `DECOUPLED`)
- **Clasificación:** API3:2023 Broken Object Property Level Authorization (exposición por propiedad) · CWE-200
- **Ataque:** el aliado envía un número de identificación para que la entidad notifique al titular por CIBA. Si la respuesta difiere cuando la identificación **no** corresponde a un cliente (un `422`, un `404`, un `statusReason` distinto, o incluso una latencia distinta), el endpoint permite verificar masivamente qué cédulas son clientes de la entidad — un dato personal financiero en sí mismo. El contrato hoy no define qué responde en ese caso, así que la implementación decidirá por omisión.
- **Confirmado:** No — el mock de Prism responde siempre el mismo ejemplo, lo que oculta el problema en vez de demostrarlo.
- **Corrección:** fijar en el contrato que la respuesta a `POST /payment-consents` es **idéntica** exista o no el cliente (`201 AWAITING_AUTHORISATION`); si el titular no existe, el consentimiento simplemente vence (`EXPIRED`) sin evento distinto. Añadir cuota específica para consentimientos `DECOUPLED` por aliado y alerta sobre tasa de vencimientos sin respuesta. Considerar aceptar solo un `login_hint` opaco emitido por la entidad al titular en un enrolamiento previo, en vez del número de identificación en claro.
- **Estado:** ✅ **corregido en el contrato** — `customerHint` declara respuesta idéntica exista o no el cliente, vencimiento silencioso y cuota propia. El `login_hint` opaco queda como mejora futura.

### [LOW] El feed de eventos expone eventos de devoluciones y consentimientos con un scope de pagos

- **Dónde:** [`api/openapi.yaml`](../api/openapi.yaml) — `GET /events` exige `payments:read`; los `EventType` incluyen `refund.*`, `consent.*` y `webhook.*`
- **Clasificación:** API5:2023 Broken Function Level Authorization · CWE-285
- **Ataque:** un sistema del aliado al que solo se le concedió `payments:read` (p. ej. su conciliación) lee por el feed el estado y monto de devoluciones y consentimientos, para los que el contrato exige `refunds:read` y `consents:read` en sus recursos propios. El dato expuesto es mínimo (estado, monto, id) y siempre del mismo aliado, por eso es *low*: es una inconsistencia del modelo de permisos, no una fuga entre aliados.
- **Confirmado:** No — lectura del contrato.
- **Corrección:** o bien un scope propio `events:read` (y sumarlo al catálogo y al ruleset de Spectral), o bien filtrar el feed por los scopes efectivos del token (`consent.*` solo con `consents:read`, etc.). La segunda opción no cambia el catálogo.
- **Estado:** ✅ **corregido en el contrato** — `GET /events` declara el filtrado por scopes efectivos del token.

### [LOW] El registro de idempotencia no declara su ámbito por aliado

- **Dónde:** [`api/openapi.yaml`](../api/openapi.yaml) — parámetro `Idempotency-Key`; [`mapeo-rest-soap.md`](../contracts/soap/mapeo-rest-soap.md) §4
- **Clasificación:** API1:2023 Broken Object Level Authorization · CWE-639
- **Ataque:** si la implementación indexa el registro de idempotencia solo por la clave, un aliado que adivine (o repita por accidente) un UUID usado por otro recibiría **la respuesta del otro** con `Idempotency-Replayed: true` — un `Payment` ajeno completo. El mapeo hacia el BUS sí deriva `idTransaccion` de `client_id + clave`, pero el registro de la fachada no lo dice.
- **Confirmado:** No — lectura del contrato. Con UUID v4 la colisión accidental es despreciable; el riesgo es una implementación que no incluya el `client_id` en la llave del registro.
- **Corrección:** declarar en la descripción de `Idempotency-Key` que la clave se interpreta **dentro del ámbito del `client_id`** y exigir en las pruebas unitarias el caso "misma clave, dos aliados → dos ejecuciones independientes" (añadir a [`respuestas.md` §5](./respuestas.md#5-estrategia-de-calidad-testing)).
- **Estado:** ✅ **corregido en el contrato** — la descripción de `Idempotency-Key` fija el ámbito por `client_id`; el caso de prueba se añadió a la respuesta 5.

### [INFO] `redirect_uris` del registro dinámico sin restricciones más allá de `format: uri`

- **Dónde:** `RegistroClienteRequest.redirect_uris`
- **Clasificación:** API8:2023 Security Misconfiguration
- **Por qué importa:** FAPI 2.0 exige coincidencia exacta de `redirect_uri` y PAR mueve el registro al canal posterior, así que el riesgo de redirección abierta ya está mitigado por el perfil. Conviene igualmente fijar en el esquema: solo `https`, sin comodines, sin fragmentos, y sin `localhost` fuera de sandbox.
- **Estado:** ✅ **corregido** — `redirect_uris` lleva patrón `^https://[^#*]+$` y descripción de coincidencia exacta.

---

## Hardening recomendado (no son vulnerabilidades, suben el piso)

- **Tamaño máximo del cuerpo.** Los campos tienen `maxLength` (`purpose` 200, `metadata` ≤ 10×200, `remittanceInformation` 140) pero el contrato no fija un límite total de cuerpo. Declarar 64 KB en el gateway evita que un cuerpo enorme con campos desconocidos (rechazados por `additionalProperties: false`, pero solo después de parsearlo) consuma CPU (API4:2023).
- **`429` también en `/par`, `/token` y `/bc-authorize`** — ✅ añadido. El AS es donde más barato resulta un ataque de volumen (cada `/token` cuesta una verificación de firma).
- **Rotación de `refresh_token`** para consentimientos `RECURRING`: emitir uno nuevo en cada uso e invalidar el anterior, vinculado también al certificado. Un `refresh_token` de larga vida sin rotación es el activo más valioso que un aliado puede perder. ✅ Declarado en `/token`.
- **Ventana de `created` en la firma de peticiones (RFC 9421).** `Idempotency-Key` ya impide repetir un `POST`; declarar además que `created` debe estar a ≤ 5 min del reloj del servidor cierra la repetición de peticiones `GET` firmadas y de `POST` con claves nuevas pero cuerpo capturado. ✅ Declarado en `Signature-Input`.
- **Consumo de la respuesta del aliado en webhooks (API10:2023):** no seguir redirecciones, leer como máximo unos KB, ignorar el cuerpo. La entidad solo necesita el código de estado.
- **Rate limit específico para `POST /payment-consents` en modo `DECOUPLED`** (ver hallazgo de enumeración).
- **Publicar en el catálogo de errores qué `type` son reintentables.** Ya están definidos `503` (reintentar) y `PENDING` (no reintentar); hacerlo explícito por `type` evita que un SDK de terceros reintente un `422`.

## Verificado y sin hallazgos

- **Client Credentials no alcanza dinero ni datos del titular (API2/API5):** el flujo `clientCredentials` del esquema `oauth2` solo declara `connection:test`, `payment-methods:read` y `webhooks:manage`; todo `payments:*`, `consents:*` y `refunds:*` vive únicamente en `authorizationCode`. El ruleset de Spectral impide que una operación use un scope fuera del catálogo.
- **Toda operación declara `security` explícitamente**, incluidas las públicas (`security: []` en Discovery, JWKS y el webhook saliente): verificado por la regla `operacion-declara-seguridad`, probada en negativo (una operación sin `security` falla el lint).
- **Mass assignment (API3):** todos los esquemas de entrada (`PaymentConsentRequest`, `PaymentRequest`, `CaptureRequest`, `CancellationRequest`, `RefundRequest`, `WebhookRequest`, `RegistroClienteRequest`) llevan `additionalProperties: false`. El smoke confirma que un cuerpo con `amount` numérico (en vez de cadena) se rechaza con `422`.
- **Lo que decide el dinero no viene del cuerpo:** la cuenta recaudadora y la razón social del aliado salen del registro; el monto y beneficiario autorizados, del token (`authorization_details`); el producto, del consentimiento confirmado por el titular. `PaymentRequest` solo puede referenciar un `consentId`.
- **Datos mínimos (API3):** ningún esquema de respuesta expone números de cuenta o tarjeta completos (`Instrument.maskedNumber` con patrón `^\*+[0-9]{4}$`, `productReference` opaco); los eventos solo llevan estado, monto e id; `ProblemDetail.detail` se define libre de datos internos y los ejemplos lo cumplen.
- **Token nunca en la URL (FAPI 2.0):** el único esquema de portador es `Authorization`; no hay parámetro de consulta para tokens.
- **Inyección vía `traceparent`:** el parámetro se valida con patrón estricto (`^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$`) antes de propagarse al BUS como `idCorrelacion` y a los logs.
- **Existencia de recursos ajenos (API1):** el contrato fija que `404` es idéntico para "no existe" y "es de otro aliado" (`NoEncontrado`), y que los ids son opacos con prefijo (`pay_`, `cns_`, `rfd_`), no secuenciales.
- **Timeout del core sin reintento ciego (API10):** el protocolo del mapeo REST↔SOAP prohíbe reenviar una orden enviada y define `PENDING` + consulta por referencia; una respuesta malformada del BUS se trata como desconocida, no como éxito ni como fallo.
- **Rate limiting declarado** con `429`, `Retry-After` y encabezados `RateLimit-*` en los endpoints de negocio.
- **Webhooks sin secreto compartido:** firma asimétrica con la llave de la entidad, `Webhook-Id` + `Webhook-Timestamp` contra repetición; el aliado verifica con `/jwks`.
