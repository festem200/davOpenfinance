# Fuentes verificadas

**Fecha de corte: 10 de septiembre de 2026.** Cada afirmación normativa o de estándar usada en
el diseño tiene aquí su fuente primaria. Nada se cita de memoria. La columna *Cómo se
verificó* distingue el texto leído directamente de la norma del que proviene de un documento
en trámite o de una fuente secundaria.

> Regla: si una afirmación no está en esta tabla, no está en el diseño. Lo que no pudo
> respaldarse se convirtió en pregunta abierta al equipo del BUS ([respuestas §4](./respuestas.md#4-insumos-de-integración)).

---

## Colombia — normas vigentes

| # | Afirmación usada en el diseño | Norma · artículo | Fuente primaria | Cómo se verificó |
|---|---|---|---|---|
| C1 | Finanzas abiertas obligatorias para entidades vigiladas desde el 7-abr-2026; sustituye el esquema voluntario | Decreto 0368 de 2026 | [PDF oficial (DAPRE)](https://dapre.presidencia.gov.co/normativa/normativa/DECRETO%20No.%200368%20DEL%2007%20DE%20ABRIL%20DE%202026.pdf) · [texto compilado](https://normativa.colpensiones.gov.co/compilacion/docs/decreto_0368_2026.htm) | Texto íntegro de la norma |
| C2 | Contenido mínimo de la autorización: identificación del tercero, datos, tratamiento, finalidad específica, tiempo; prohibición de autorizaciones abiertas y de condicionar productos | D-0368/2026, art. 2.35.8.3.2 | Ídem C1 | Texto íntegro |
| C3 | Confirmación del titular ante la entidad antes de que circule información (doble consentimiento), con opción de autorizar o denegar | D-0368/2026, art. 2.35.8.3.3 | Ídem C1 | Texto íntegro |
| C4 | Autenticación fuerte del titular para otorgar, modificar o revocar | D-0368/2026, art. 2.35.8.3.4 | Ídem C1 | Texto íntegro |
| C5 | Medición auditable por tercero y por volumen como base de la tarifa | D-0368/2026, art. 2.35.8.3.9 | Ídem C1 | Texto íntegro |
| C6 | Directorio de participantes administrado por la SFC, 3 módulos, inscripción con verificación previa | D-0368/2026, arts. 2.35.8.5.1 a 2.35.8.5.6 | Ídem C1 | Texto íntegro |
| C7 | Espacio de pruebas facultativo de la SFC | D-0368/2026, art. 2.35.8.4.2 | Ídem C1 | Texto íntegro |
| C8 | La SFC debe publicar el cronograma de estándares dentro de los 6 meses siguientes (≈ 10-oct-2026) | D-0368/2026, régimen de transición | Ídem C1 · [comunicado URF](https://www.urf.gov.co/w/colombia-consolida-el-sistema-de-finanzas-abiertas-obligatorio) | Texto íntegro + comunicado oficial |
| C9 | Iniciación de pagos habilitada desde julio de 2022, incluidas sociedades no vigiladas; se tramita vía EASPBV; el iniciador no tiene tenencia de fondos | Decreto 1297 de 2022, art. 4 → Decreto 2555/2010, art. 2.17.4.1.1 | [PDF oficial (DAPRE)](https://dapre.presidencia.gov.co/normativa/normativa/DECRETO%201297%20DEL%2025%20DE%20JULIO%20DE%202022.pdf) · [Gestor Normativo](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=190426) | Texto íntegro |
| C10 | Derecho de acceso: sin restricciones arbitrarias, sin bloqueo de órdenes, sin exclusividad; requisitos y costos informados | Decreto 2555/2010, art. 2.17.4.1.2 | Ídem C9 | Texto íntegro |
| C11 | Cada orden autorizada por el ordenante; la entidad emisora autentica al ordenante en todos los casos; el iniciador nunca accede a claves ni mecanismos de autenticación | Decreto 2555/2010, art. 2.17.4.1.3 nums. 2, 3 y 4 | Ídem C9 | Texto íntegro |
| C12 | La SFC "expedirá" (obligación) estándares para iniciación de pagos inmediatos o no, recurrentes o no | Decreto 2555/2010, art. 2.17.4.1.3 inciso final, modificado por D-0368/2026 art. 2 | Ídem C1 y C9 | Texto íntegro de ambas normas |
| C13 | El Título 4 del Libro 17 no fue derogado por el D-0368/2026 (solo se modificó un inciso) | D-0368/2026, artículos derogatorio y modificatorio | Ídem C1 | Texto íntegro |
| C14 | Estándares técnicos: JSON, REST/RESTful, ISO 20022, **FAPI 2.0**, OAuth 2.0, JWT PS256+, `private_key_jwt`, mTLS con certificados Ley 527 y dos suites de cifrado; logs 5 años; red lógicamente separada; no exponer repositorios; cláusula de obsolescencia | Circular Externa 004 de 2024 (SFC), Cap. IX, nums. 3.1 y 3.2 | [Circular](https://www.superfinanciera.gov.co/loader.php?lServicio=Tools2&lTipo=descargas&lFuncion=descargar&idFile=1069605) · [Anexo Cap. IX](https://www.superfinanciera.gov.co/loader.php?lServicio=Tools2&lTipo=descargas&lFuncion=descargar&idFile=1069606) | PDF escaneado sin capa de texto; se leyeron las imágenes de página directamente. Así se confirmó el numeral 3.2.3 lit. a), que fuentes secundarias reportaban de forma contradictoria |
| C15 | Requisitos exigibles a terceros no vigilados: RNBD o políticas de datos, ISO 27001 / NIST CSF / OWASP ASVS, **PCI-DSS con QSA y AoC** si tocan datos de tarjeta, cifrado AES/RSA, notificación de incidentes; políticas aprobadas por junta y publicadas; debida diligencia SARLAFT | CE 004/2024, num. 6.2 | Ídem C14 | PDF escaneado leído por imagen |
| C16 | Plazo de adopción vencido el 7-ago-2026 (18 + 6 + 6 meses) | CE 004/2024 · CE 009/2025 · CE 001/2026 | [CE 009/2025](https://www.superfinanciera.gov.co/loader.php?lServicio=Tools2&lTipo=descargas&lFuncion=descargar&idFile=1077170) · [CE 001/2026](https://www.superfinanciera.gov.co/loader.php?lServicio=Tools2&lTipo=descargas&lFuncion=descargar&idFile=1080722) | Texto de las tres circulares |
| C17 | **SOAP prohibido**; TLS 1.0 y 1.1 prohibidas; HS256 rechazado | FAQ de desarrolladores de la SFC (documento oficial complementario) | [Preguntas frecuentes — desarrolladores](https://www.superfinanciera.gov.co/publicaciones/10114733/innovasfcfinanzas-abiertasfinanzas-abiertas-colombiadesarrolladorespeguntas-frecuentes-10114733/) | Página oficial de la SFC |
| C18 | Bre-B operando desde el 6-oct-2025; 370,4 M de operaciones por $59 billones al 31-ene-2026; normas RE 6/2023, DSP-465, DSP-470, DSP-471 | Banco de la República | [Regulación Bre-B](https://www.banrep.gov.co/es/normatividad/sistemas-pago/pagos-inmediatos-bre-b) · [Documento técnico (feb-2026)](https://d1b4gd4m8561gs.cloudfront.net/sites/default/files/publicaciones/archivos/documento-tecnico-bre-b-febrero-2026.pdf) | Documento técnico oficial |
| C19 | La regulación de Bre-B gobierna la interoperabilidad entre administradores, no el acceso de terceros iniciadores | RE 6/2023 y DSP-465 | Ídem C18 | Lectura del documento técnico y la resolución |

## Colombia — proyectos en trámite (**no vigentes**)

| # | Afirmación | Documento | Fuente | Cómo se verificó |
|---|---|---|---|---|
| P1 | Nuevo Capítulo IX: mantiene FAPI 2.0 y añade OpenAPI 3.1, DAMA, OWASP API Top 10 / NIST SP 800-204 / CSA, validación periódica del intercambio, regla anti *dark patterns* (num. 7) | Proyecto de Circular Externa 10 de 2026 — comentarios cerrados el 11-ago-2026, **no expedida** | [Página del proyecto](https://www.superfinanciera.gov.co/publicaciones/10116197/proyecto-de-circular-externa-10-2026/) | Documento Word publicado por la SFC |
| P2 | Cronograma borrador: iniciación de pagos en el mes 132; catálogo de productos entre 36 y 72 meses; consulta hasta el 15-sep-2026 | Proyecto de Carta Circular del 31-ago-2026 | [Página del proyecto](https://www.superfinanciera.gov.co/publicaciones/10116237/proyecto-de-carta-circular-agosto-31-de-2026/) | Documento Word publicado por la SFC |

## Estándares internacionales

| # | Afirmación | Especificación | Fuente | Cómo se verificó |
|---|---|---|---|---|
| E1 | FAPI 2.0 Security Profile es especificación **Final** (aprobada en febrero de 2025); recomendación oficial para ecosistemas nuevos | OpenID Foundation, FAPI WG | [Especificación final](https://openid.net/specs/fapi-security-profile-2_0-final.html) · [Anuncio de aprobación](https://openid.net/fapi-2-security-profile-attacker-model-final-specifications-approved/) | Sitio oficial |
| E2 | Requisitos normativos de FAPI 2.0: PAR obligatorio, PKCE S256, tokens sender-constrained (mTLS o DPoP), cliente autenticado solo con mTLS o `private_key_jwt`, `code` ≤ 60 s, `iss` en la respuesta, rechazo de ROPC y de clientes públicos, token nunca en query | FAPI 2.0 Security Profile | Ídem E1 | Texto de la especificación |
| E3 | Existen suites de conformidad oficiales para FAPI 2.0 Security Profile y Message Signing, gratuitas y autoadministradas | OpenID Foundation | [Anuncio de las pruebas finales](https://openid.net/fapi2-0-final-conformance-tests-available/) · [Especificaciones del WG](https://openid.net/wg/fapi/specifications/) | Sitio oficial |
| E4 | FAPI-CIBA (flujos desacoplados) y Grant Management son *Implementer's Drafts* | OpenID Foundation, FAPI WG | Ídem E3 | Sitio oficial |
| E5 | RFC citadas: 6749 (OAuth 2.0), 6750 (Bearer), 7009 (revocación), 7517 (JWK), 7591/7592 (registro dinámico), 7636 (PKCE), 7662 (introspección), 8414 (metadatos del AS), 8594 (`Sunset`), 8705 (mTLS), 9101 (JAR), 9126 (PAR), 9207 (`iss`), 9396 (RAR), 9421 (firmas HTTP), 9449 (DPoP), 9457 (Problem Details) | IETF | `https://www.rfc-editor.org/rfc/rfc<número>` | Numeración tomada de la tabla de referencias de la base de investigación; se cita el número, no se parafrasea el contenido |
| E6 | Open Banking Read-Write API v4.0 y Open Finance Brasil como referencias de diseño de pagos e implementación FAPI | OBL · Open Finance Brasil | [OBL v4.0](https://openbankinguk.github.io/read-write-api-site3/v4.0/) | Sitio oficial |

---

## Nota metodológica

- Este documento **deriva** de una base de investigación propia con la misma fecha de corte,
  en la que el texto de los decretos se transcribió de la fuente normativa y las circulares
  escaneadas se leyeron por imagen. Aquí se conservan solo las afirmaciones que el diseño usa.
- Los análisis de firmas de abogados se usaron como contraste en la base de investigación,
  no como fuente; por eso no aparecen aquí.
- **Lo que no está respaldado no se afirma.** Tres ejemplos que quedaron como preguntas al
  equipo del BUS en vez de supuestos: el mecanismo operativo de una solicitud de cobro sobre
  Bre-B, las reglas de débito directo recurrente por ACH, y la versión vigente de PCI DSS
  que exige la entidad a sus aliados.
