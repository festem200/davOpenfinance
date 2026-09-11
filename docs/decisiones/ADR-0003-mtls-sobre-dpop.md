# ADR-0003 · Tokens vinculados por mTLS (RFC 8705), DPoP como secundario

**Estado:** aceptada · **Fecha:** 2026-09-10

## Contexto
FAPI 2.0 exige tokens *sender-constrained*: mTLS (RFC 8705) o DPoP (RFC 9449). Sin
vínculo, un token robado sirve a cualquiera.

## Alternativas
1. **mTLS**: el token lleva `cnf.x5t#S256` con la huella del certificado; el servidor de
   recursos compara con el certificado de la conexión.
2. **DPoP**: el cliente firma cada petición con una llave efímera y el token lleva `cnf.jkt`.
3. Ambos, a elección del aliado.

## Decisión
mTLS como mecanismo principal; DPoP admitido como secundario para clientes que no puedan
terminar TLS con certificado propio (p. ej. detrás de ciertos proxies).

Razones: el transporte mTLS **ya es obligatorio** en Colombia (CE 004/2024 3.2.3 c) con
certificados Ley 527), así que el certificado existe de todos modos; es lo que usan Brasil,
Reino Unido y Australia; y la validación es una comparación de huellas, sin verificar una
firma adicional por petición.

## Consecuencias
- El gateway debe exponer al servicio la huella del certificado de la conexión.
- La rotación de certificados del aliado invalida tokens vivos: se documenta como
  comportamiento esperado y `/connection-test` lo hace visible (`tokenBoundToCertificate`).
- Si se habilita DPoP, el AS debe publicar `dpop_signing_alg_values_supported` y el
  servicio validar el `DPoP` header y el `jkt`.
