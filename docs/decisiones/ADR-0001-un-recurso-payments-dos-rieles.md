# ADR-0001 · Un solo recurso `/payments` con dos rieles

**Estado:** aceptada · **Fecha:** 2026-09-10

## Contexto
El reto pide cobrar contra dos productos con ciclos de vida distintos: cuenta de ahorros
(una fase: el débito se ejecuta al crear) y tarjeta de crédito (dos fases: autorización con
retención de cupo y captura posterior, total o parcial).

## Alternativas
1. **Dos recursos**: `/account-payments` y `/card-payments`, cada uno con su ciclo.
2. **Un recurso `/payments`** con `instrumentType` discriminado y sub-recursos que aplican
   según el instrumento (`/captures`, `/cancellations` solo para tarjeta).
3. Un recurso genérico `/transactions` con `type` libre.

## Decisión
La opción 2. Consentimiento, idempotencia, errores, eventos, devoluciones, conciliación y
seguridad son idénticos en ambos rieles — más del 80 % del contrato. Lo que difiere se
expresa con el instrumento y con qué sub-recursos existen; una transición inválida (capturar
un pago de ahorros) responde `409`.

## Consecuencias
- Un SDK, un catálogo de errores, una máquina de estados documentada (diagrama 04).
- El esquema `Payment` lleva campos que no aplican a todos los instrumentos
  (`installments`, `captureMode`, `authorizationExpiresAt`); se documentan como "solo
  tarjeta" en vez de crear dos esquemas.
- Si aparece un tercer instrumento (p. ej. billetera), entra como valor de `instrumentType`
  sin nuevo recurso.
