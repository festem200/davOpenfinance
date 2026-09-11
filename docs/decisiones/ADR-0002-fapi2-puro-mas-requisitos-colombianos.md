# ADR-0002 · FAPI 2.0 puro más los requisitos literales de la CE 004/2024

**Estado:** aceptada · **Fecha:** 2026-09-10

## Contexto
La Circular Externa 004 de 2024 exige "cumplir el marco FAPI 2.0" (num. 3.2.3 lit. a) y a
continuación enumera requisitos que corresponden a FAPI 1.0 o que 2.0 no exige: menciona
`private_key_jwt` como único método, JWT PS256+, dos suites TLS 1.2, y Client Credentials
entre los grants; **no menciona PAR ni tokens vinculados al remitente**, los dos requisitos
centrales de FAPI 2.0. El proyecto de Capítulo IX de 2026 repite el texto.

## Alternativas
1. Implementar solo la lista literal del numeral 3.2.3.
2. Implementar FAPI 2.0 puro e ignorar los detalles literales que 2.0 no exige.
3. Implementar FAPI 2.0 puro **y además** los detalles literales colombianos.

## Decisión
La opción 3. La opción 1 no cumple FAPI 2.0 pese a que la norma lo exige — riesgo de
incumplimiento en una eventual verificación con la suite de conformidad. La opción 2 deja
sin cumplir requisitos literales (PS256+, suites) que un supervisor puede exigir tal cual.
La 3 cumple ambas lecturas y cuesta poco: PS256+ y las dos suites son compatibles con 2.0.

## Consecuencias
- El AS debe soportar PAR obligatorio, PKCE S256, `iss` (RFC 9207), `code` ≤ 60 s, tokens
  vinculados (mTLS) — y además JWT PS256+, `private_key_jwt` como **único** método de
  autenticación de cliente (FAPI 2.0 permitiría también mTLS, pero la circular lo nombra en
  singular y el vínculo del token no depende de ello), y TLS 1.2 con las dos suites **más** TLS 1.3.
- Client Credentials queda restringido a scopes que no tocan dinero ni datos del titular.
- Certificación FAPI 2.0 de la OIDF como condición de paso a producción.
- Se documenta la brecha en `docs/marco-normativo-aplicable.md` §3 como riesgo de
  interpretación, no como crítica a la norma.
