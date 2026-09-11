# ADR-0004 · Un timeout del core produce `201 PENDING`, nunca `504`

**Estado:** aceptada · **Fecha:** 2026-09-10

## Contexto
La fachada envía `DebitarCuenta` al BUS y no recibe respuesta dentro del presupuesto. El
débito **pudo** haberse aplicado. Es el caso que más doble cobro produce en sistemas de pago.

## Alternativas
1. Responder `504 Gateway Timeout` y dejar que el aliado reintente.
2. Reintentar automáticamente contra el BUS.
3. Responder `201` con el pago en `PENDING` y resolver el estado por consulta de referencia.

## Decisión
La opción 3. El `504` induce al aliado a reintentar — y aunque `Idempotency-Key` protege
la fachada, si la fachada perdió la respuesta original no tiene qué reproducir y volvería a
llamar al core. Reintentar automáticamente (opción 2) es peor: reenvía una orden que pudo
ejecutarse. Con la opción 3 el recurso existe, el aliado tiene un `paymentId` que consultar,
y un reconciliador resuelve con `ConsultarTransaccion` por el `idTransaccion` **de la
fachada**.

## Consecuencias
- `PaymentStatus` incluye `PENDING` con `statusReason.code = CORE_TIMEOUT` y un mensaje que
  dice explícitamente "no reintentes el POST".
- `FAILED` solo se usa cuando la consulta confirma que el core no tiene la transacción tras
  la ventana de recepción; mientras haya duda, `PENDING`.
- **Insumo bloqueante**: el BUS debe exponer consulta por el id que la fachada envió. Sin
  eso el diseño tiene un hueco de doble cobro que ningún mecanismo de idempotencia cierra.
- `503` se reserva para "la orden no se envió" (circuito abierto), donde reintentar es seguro.
