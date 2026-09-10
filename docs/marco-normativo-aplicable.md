# Marco normativo aplicable a estas APIs

**Fecha de corte: 10 de septiembre de 2026.** Toda afirmación está fechada y respaldada en
[`fuentes-verificadas.md`](./fuentes-verificadas.md). Las normas en trámite se marcan como
**no vigentes**: confundirlas con las expedidas invalidaría el diseño entero.

> **Por qué este documento existe.** El reto pide diseñar "desde cero" APIs para que aliados y
> Fintechs cobren contra cuentas de ahorro y tarjetas de crédito. En Colombia eso no parte de
> cero: hay tres regímenes vigentes que fijan qué puede hacerse, cómo debe autenticarse al
> cliente y con qué estándares técnicos. Diseñar sin leerlos es diseñar para reprocesar.

---

## 1. Los tres regímenes que tocan estas APIs

### 1.1 Finanzas abiertas — Decreto 0368 de 2026 (vigente, obligatorio)

Expedido el **7 de abril de 2026**. Sustituye el esquema **voluntario** del Decreto 1297 de 2022
por uno **obligatorio** para las entidades vigiladas por la SFC (establecimientos bancarios,
SEDPE, fiduciarias, aseguradoras, entre otras). Lo que importa para este diseño:

| Artículo | Qué exige | Dónde aterriza en el diseño |
|---|---|---|
| **2.35.8.3.2 — Autorización** | El tercero necesita autorización del titular con contenido mínimo: identificación del tercero, datos autorizados, tratamiento, **finalidad específica** y **tiempo** de la finalidad. Prohíbe autorizaciones generales o abiertas y condicionar un producto a la autorización | Recurso `/payment-consents` con esos campos como obligatorios; scope + `authorization_details` + vigencia ([respuestas §3](./respuestas.md#3-autenticación-y-autorización)) |
| **2.35.8.3.3 — Confirmación** | Antes de que circule información, **la entidad confirma con el titular** que el tercero tiene su autorización, mostrando el contenido mínimo y permitiéndole **autorizar o denegar** | El "doble consentimiento": confirmación fusionada con la autenticación fuerte en una sola pantalla de la entidad ([diagrama 3](./diagrams/03-secuencia-doble-consentimiento.png)) |
| **2.35.8.3.4 — Autenticación** | Mecanismos **fuertes** de autenticación del titular para otorgar, modificar o revocar | FAPI 2.0 + autenticación fuerte en el Authorization Server de la entidad |
| **2.35.8.3.9 — Medición** | Contador auditable por tercero, por volumen de consultas, base de la tarifa | Los scopes son la unidad de medición y de *rate limiting* por aliado |
| **2.35.8.5.1 – 5.6 — Directorio** | Directorio de participantes administrado por la SFC (3 módulos), inscripción con **verificación previa**, en funcionamiento a más tardar 12 meses después de los lineamientos | Registro dinámico de clientes (`/register`, RFC 7591) contra un *Software Statement* — el diseño anticipa el directorio en vez de inventar un alta manual |
| **2.35.8.4.2 — Espacio de pruebas** | La SFC **podrá** habilitar un espacio de pruebas (facultativo) | Sandbox propio con `/connection-test` y escenarios deterministas ([respuestas §8](./respuestas.md#8-developer-experience)) |

**Relojes que corren:** la SFC debe publicar el cronograma definitivo de estándares antes del
**10 de octubre de 2026** (6 meses desde la vigencia del decreto). El proyecto de cronograma
estuvo en consulta hasta el **15 de septiembre de 2026**.

### 1.2 Iniciación de pagos — Decreto 1297 de 2022, art. 4 (vigente desde julio de 2022)

Es el régimen que gobierna el riel de **cuenta de ahorros** cuando el aliado inicia órdenes de
pago. Vive en el **Título 4 del Libro 17** del Decreto 2555 de 2010 — un título distinto al de
finanzas abiertas — y **no fue derogado** por el Decreto 0368 de 2026, que solo modificó el
inciso final del art. 2.17.4.1.3.

| Artículo | Qué exige | Dónde aterriza en el diseño |
|---|---|---|
| **2.17.4.1.1 — Quién inicia** | Establecimientos de crédito, SEDPE, EASPBV y **sociedades no vigiladas**. Requiere autorización previa del ordenante, se tramita a través de una EASPBV, y el iniciador **no puede tener tenencia de los fondos** | Un aliado Fintech puede ser iniciador sin licencia de la SFC; el diseño nunca le entrega custodia de fondos — el débito lo ejecuta la entidad contra su propio core |
| **2.17.4.1.2 — Derecho de acceso** | Las EASPBV no pueden restringir arbitrariamente el acceso, bloquear órdenes ni pactar exclusividad; deben informar requisitos y costos | Condiciones de acceso publicadas en el portal de desarrolladores, iguales para todos los aliados |
| **2.17.4.1.3 num. 2 — Cada orden** | **Cada** orden de pago debe ser autorizada por el ordenante | Un consentimiento cubre **un** pago (o una serie recurrente explícita); `authorization_details` ata el token a ese monto y beneficiario |
| **2.17.4.1.3 num. 3 — Autenticación** | La entidad emisora **autentica al ordenante en todos los casos**, según reglas que dicte la SFC | El aliado nunca autentica al cliente; lo hace la entidad en su propio Authorization Server (redirección o CIBA) |
| **2.17.4.1.3 num. 4 — Credenciales** | El iniciador no puede pedir más información de la necesaria y **en ningún caso** acceder a claves, contraseñas o mecanismos de autenticación del ordenante | Prohibición efectiva del *screen scraping*: no existe ningún endpoint que reciba credenciales del cliente |
| **2.17.4.1.3 inciso final** (modificado por D-0368/2026, art. 2) | La SFC **expedirá** estándares para iniciación de pagos, inmediatos o no, **recurrentes o no** | El modelo de consentimiento contempla `single` y `recurring` desde el día uno |

> ⚠️ Los **estándares de la SFC** para iniciación de pagos (reglas de autenticación y
> confirmación del num. 3) **no existen todavía**; el proyecto de cronograma los ubica en el
> mes 132. Eso no bloquea la actividad — está habilitada desde 2022 — pero sí implica que hoy
> cada EASPBV fija sus reglas técnicas en su reglamento. El diseño se ancla en FAPI 2.0
> precisamente para no depender de esa fragmentación.

### 1.3 Estándares técnicos — Circular Externa 004 de 2024 de la SFC (vigente; plazo vencido)

Capítulo IX del Título I de la Parte I de la Circular Básica Jurídica. Plazo de adopción:
18 meses + 6 (CE 009/2025) + 6 (CE 001/2026) = **vencido el 7 de agosto de 2026**. Una
entidad vigilada que participe en finanzas abiertas sin cumplirlo está en incumplimiento hoy.

| Numeral | Qué exige | Dónde aterriza en el diseño |
|---|---|---|
| **3.2.1 Arquitectura** | Intercambio en **JSON**, marco **REST**, implementación **RESTful** | Todo el contrato ([`api/openapi.yaml`](../api/openapi.yaml)) |
| **3.2.2 Datos** | Diccionario de datos **ISO 20022** en los campos financieros que corresponda | Montos, cuentas, partes y referencias mapeados a componentes ISO 20022 |
| **3.2.3 a) Seguridad** | **Cumplir el marco FAPI 2.0** de la OpenID Foundation | Perfil obligatorio del Authorization Server ([respuestas §3](./respuestas.md#3-autenticación-y-autorización)) |
| **3.2.3 b)** | OAuth 2.0; token **JWT firmado con PS256 o superior**; **`private_key_jwt`** como autenticación de cliente | Esquema `oauth2` del contrato; `client_secret_*` no se admite |
| **3.2.3 c)** | **TLS con autenticación mutua**, certificados vigentes conforme a la **Ley 527 de 1999**, suites `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256` o `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384` | mTLS en el gateway; se soportan las dos suites (cumplimiento literal) **y** TLS 1.3 (buena práctica) |
| **3.1 Principios** | Red interna **lógicamente separada**; monitoreo; **no exponer públicamente los repositorios** de desarrollo; **logs de auditoría por 5 años** por cada solicitud con origen, momento, usuario, información circulada y estado; redundancia, balanceo y tolerancia a fallos | NFRs con umbral y herramienta ([respuestas §7](./respuestas.md#7-requerimientos-no-funcionales)) |
| **Cláusula de obsolescencia** | Si el organismo que sostiene un estándar lo declara obsoleto, la entidad adopta el sustituto | El diseño sigue al FAPI Working Group; no se congela una versión |
| **6.2 Terceros no vigilados** | La entidad verifica que el tercero: esté en el RNBD o tenga políticas de datos; atienda consultas y revocatorias; gestione riesgo operacional; tenga capacidad humana, técnica y financiera; gestione ciberseguridad con **ISO 27001, NIST CSF u OWASP ASVS**; tenga **PCI-DSS con QSA y AoC** si toca datos de tarjeta; cifre con al menos **AES/RSA**; notifique incidentes | Checklist de alta del aliado ([respuestas §3](./respuestas.md#3-autenticación-y-autorización)) |

**Precisiones del FAQ de desarrolladores de la SFC** (documento oficial complementario):
**SOAP está prohibido** en las APIs del sistema; **TLS 1.0 y 1.1 prohibidas** (1.2 o superior);
**HS256 rechazado** por usar clave simétrica.

> 🔑 **Consecuencia directa para este reto:** el BUS corporativo habla SOAP. Exponerlo, aun
> detrás de un gateway, **incumpliría la norma**. La fachada REST no es una preferencia de
> diseño: es el único camino permitido. Y el mapeo REST↔SOAP pasa a ser parte del alcance
> regulado, no un detalle de integración.

### 1.4 Lo que **no** es finanzas abiertas: el riel de tarjeta de crédito

El cobro con tarjeta de crédito corre por **adquirencia y franquicias**, no por el Título 8 ni
por el Título 4. Es un contrato bilateral entre la entidad y el aliado. Lo que sí le aplica de
la CE 004/2024 es el numeral **6.2**: un aliado que almacene, procese o transmita datos de
tarjeta necesita **certificación PCI-DSS emitida por un QSA y soportada por el AoC**. El diseño
evita ese alcance por construcción: **el aliado nunca recibe ni envía el PAN** — cobra contra
un producto que el cliente ya tiene en la entidad, bajo consentimiento.

### 1.5 Infraestructura de pagos inmediatos — Bre-B (Banco de la República)

Operando desde el **6 de octubre de 2025**. Entre esa fecha y el 31 de enero de 2026 liquidó
**370,4 millones de operaciones** por **$59 billones**. Normas: Resolución Externa 6 del
31-oct-2023 (interoperabilidad, al amparo del art. 104 de la Ley 2294 de 2023), Circulares
Reglamentarias DSP-465 (estándares), DSP-470 (DICE, directorio centralizado de llaves) y
DSP-471 (MOL, liquidación).

> ⚠️ Esa regulación gobierna la **interoperabilidad entre administradores** de sistemas de
> pago, no el acceso de terceros iniciadores. El derecho de acceso del iniciador vive en el
> art. 2.17.4.1.2 y se materializa en el reglamento de cada EASPBV. El detalle operativo de
> cómo un aliado inicia un cobro sobre Bre-B es un **insumo a pedir**, no un supuesto a
> inventar — ver [respuestas §4](./respuestas.md#4-insumos-de-integración).

---

## 2. Normas en trámite — **no vigentes** a la fecha de corte

| Proyecto | Estado | Qué añadiría (si se expide como está) |
|---|---|---|
| **Proyecto de Circular Externa 10 de 2026** — nuevo Capítulo IX de la CBJ | Comentarios cerrados el 11-ago-2026; **no expedida** | Mantiene FAPI 2.0, OAuth 2.0, PS256+, `private_key_jwt`, mTLS y las mismas suites. **Añade**: diseño con **OpenAPI 3.1**; pruebas de calidad de datos con criterios **DAMA**; gestión de vulnerabilidades con **OWASP API Security Top 10, NIST SP 800-204 y CSA API Security**; **validación periódica del intercambio por API**; prohibición expresa de interferir, añadir validaciones redundantes o usar diseños que generen desconfianza en la confirmación (regla anti *dark patterns*, numeral 7) |
| **Proyecto de Carta Circular** — cronograma de estándares | En consulta hasta el 15-sep-2026 | Iniciación de pagos en el **mes 132**; catálogo de productos entre 36 y 72 meses |

El diseño **cumple el proyecto de Capítulo IX desde ya** (OpenAPI 3.1, OWASP/NIST/CSA,
`/connection-test` como validación periódica) porque el costo de anticiparlo es bajo y el de
reprocesar, alto.

---

## 3. Una brecha en la propia norma que el diseño resuelve a favor del estándar

La CE 004/2024 — y el proyecto de 2026, idéntico en este punto — exige "cumplir el marco FAPI
2.0" y a continuación enumera requisitos que son de **FAPI 1.0** o incompatibles con 2.0:

| Punto | Lo que dice la norma | Lo que exige FAPI 2.0 |
|---|---|---|
| **PAR** (RFC 9126) | No lo menciona | **Obligatorio** |
| Tokens **sender-constrained** (mTLS RFC 8705 o DPoP RFC 9449) | No los menciona | **Obligatorio** — es el requisito central |
| Autenticación de cliente | Solo `private_key_jwt` | `private_key_jwt` **o** mTLS |
| Client Credentials | Listado entre los "mecanismos seguros" | No es un flujo para acceder a datos ni dinero del titular |
| Suites TLS | Dos suites de **TLS 1.2**, sin ECDSA | No restringe; la práctica actual es TLS 1.3 |

**Decisión:** implementar **FAPI 2.0 puro** (PAR + tokens vinculados + PKCE S256 + `iss`), que
cumple la norma con holgura, y **además** los requisitos literales colombianos (JWT PS256+,
`private_key_jwt`, las dos suites, mTLS Ley 527). Implementar solo la lista literal del numeral
3.2.3 **no cumple FAPI 2.0**, pese a que la propia norma lo exige. Con Client Credentials solo
viajan scopes que no tocan dinero ni datos del titular.
