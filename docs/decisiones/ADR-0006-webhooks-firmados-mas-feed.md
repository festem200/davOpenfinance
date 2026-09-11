# ADR-0006 · Eventos por webhook firmado **y** feed pull

**Estado:** aceptada · **Fecha:** 2026-09-10

## Contexto
Los pagos cambian de estado de forma asíncrona (liquidación, resolución de un `PENDING`,
revocación de un consentimiento por el titular). El aliado necesita enterarse sin sondear.

## Alternativas
1. Solo webhooks con reintentos.
2. Solo un feed paginado que el aliado consulta.
3. Webhooks **y** feed.

## Decisión
La opción 3. Los webhooks dan latencia baja pero dependen de que el aliado esté arriba;
los reintentos no resuelven una caída larga ni un bug del receptor. El feed (`GET /events`,
30 días, cursor) es el mecanismo de recuperación: un aliado que estuvo caído lee desde su
último cursor y queda al día sin pedir reenvíos.

Las entregas se firman con la llave de la entidad (RFC 9421; pública en `/jwks`) en vez de
un secreto compartido: el aliado verifica sin custodiar secretos, y la rotación es publicar
una llave nueva. `Webhook-Id` + `Webhook-Timestamp` cierran la repetición.

## Consecuencias
- El evento nunca lleva datos del titular; avisa y enlaza el recurso. El aliado consulta el
  recurso antes de actuar (`el evento avisa, el recurso decide`).
- Tras 24 h de fallos la suscripción pasa a `SUSPENDED` y se emite `webhook.suspended` al
  feed, que es lo único que sigue funcionando en ese escenario.
- El feed exige retención de 30 días y un cursor estable — un *outbox* con orden total.
