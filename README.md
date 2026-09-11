# davOpenfinance — Diseño de APIs de pago para un ecosistema Open Finance

> Respuesta a un reto técnico: diseñar desde cero las APIs con las que una entidad financiera
> permite a sus **aliados comerciales y Fintechs** cobrar contra la **cuenta de ahorros** y la
> **tarjeta de crédito** de sus clientes, sobre un *backend* transaccional que expone sus
> servicios por **SOAP**. Ocho preguntas — contratos, seguridad, autenticación, insumos,
> pruebas, entornos, NFRs y experiencia de desarrollador — respondidas con un contrato
> ejecutable, el marco normativo colombiano vigente y diagramas.

**Fecha de corte normativa: 10 de septiembre de 2026.** La entidad se trata de forma
genérica: este repositorio no representa, ni está afiliado a, ninguna institución financiera;
no usa nombres, marcas ni datos reales. Los ejemplos son sintéticos.

## Lo que diferencia esta respuesta

| | |
|---|---|
| **No parte de cero de verdad** | En Colombia estas APIs ya tienen perímetro: finanzas abiertas obligatorias (Decreto 0368 de 2026), iniciación de pagos habilitada desde 2022 (Título 4 del Libro 17 del Decreto 2555), y estándares técnicos de la SFC (CE 004/2024) que exigen **FAPI 2.0** con plazo **vencido el 7-ago-2026** y **prohíben SOAP** hacia afuera. El diseño cumple eso, artículo por artículo → [`docs/marco-normativo-aplicable.md`](docs/marco-normativo-aplicable.md) |
| **El contrato se ejecuta** | OpenAPI 3.1 validado por dos linters con un ruleset propio (toda operación declara su scope), 31 ejemplos verificados contra esquema, y un *smoke* de **44 verificaciones** contra un mock generado del propio contrato — incluidos los rechazos → [`api/openapi.yaml`](api/openapi.yaml) |
| **Un timeout del core nunca es un `504`** | El pago existe en `PENDING` y se resuelve por consulta de referencia. La operación que lo permite es el insumo **bloqueante** del proyecto → [`contracts/soap/mapeo-rest-soap.md`](contracts/soap/mapeo-rest-soap.md) |
| **Dos planos de API** | Además de consentimientos, pagos y devoluciones, el plano de **confianza**: PAR, tokens vinculados al certificado, registro dinámico, prueba de conexión, y la cadena de ocho verificaciones que corre en cada llamada → [`docs/respuestas.md` §3](docs/respuestas.md#3-autenticación-y-autorización) |
| **El diseño se auditó a sí mismo** | Contra OWASP API Security Top 10 (2023, revalidado hoy): 3 hallazgos *medium*, 2 *low*, todos corregidos en el contrato → [`docs/auditoria-seguridad.md`](docs/auditoria-seguridad.md) |

## Cómo leerlo

1. **[`docs/respuestas.md`](docs/respuestas.md)** — el entregable: las 8 respuestas, con resumen ejecutivo de cinco decisiones.
2. **[`api/openapi.yaml`](api/openapi.yaml)** — el contrato. Se lee mejor renderizado: `npm run docs:preview`.
3. **[`docs/diagrams/`](docs/diagrams/)** — 8 diagramas (fuente `.drawio` editable + PNG): contexto, secuencia end-to-end, doble consentimiento, máquina de estados, timeout del core, cadena de validación, despliegue, y el plano de confianza de punta a punta.
4. **[`docs/marco-normativo-aplicable.md`](docs/marco-normativo-aplicable.md)** y **[`docs/fuentes-verificadas.md`](docs/fuentes-verificadas.md)** — qué norma aplica, desde cuándo, y la fuente primaria de cada afirmación. Nada se cita de memoria.
5. **[`docs/decisiones/`](docs/decisiones/)** — seis ADR con las decisiones que un lector podría cuestionar.
6. **[`contracts/soap/`](contracts/soap/)** — WSDL ilustrativo del BUS y mapeo REST↔SOAP campo a campo.

## Verificarlo

Requiere Node.js ≥ 20. Sin Docker, sin credenciales, sin red externa (el mock corre en local).

```bash
git clone https://github.com/festem200/davOpenfinance.git
cd davOpenfinance
npm ci
npm run lint:api      # Redocly + Spectral con ruleset propio: 0 errores, 0 warnings
npm run smoke         # levanta el mock (Prism) y recorre 44 verificaciones del contrato
```

Otros comandos:

```bash
npm run mock          # mock del contrato en http://127.0.0.1:4010 para probar con curl o Postman
npm run docs:preview  # documentación navegable del contrato (Redoc)
npm run diagrams      # re-exporta los .drawio a PNG (requiere la app de draw.io)
```

CI ejecuta lint, smoke, pareo `.drawio`/`.png` y verificación de enlaces en cada PR.

## Estructura

```
docs/respuestas.md                  ★ las 8 respuestas
docs/marco-normativo-aplicable.md   qué norma aplica y dónde aterriza en el diseño
docs/fuentes-verificadas.md         afirmación → norma/artículo → URL → cómo se verificó
docs/auditoria-seguridad.md         OWASP API Top 10 2023 sobre el propio diseño
docs/decisiones/                    ADR-0001 … ADR-0006
docs/diagrams/                      8 diagramas (.drawio + .png)
api/openapi.yaml                    contrato OpenAPI 3.1 (plano de confianza + negocio)
api/examples/                       31 ejemplos validados contra esquema
contracts/soap/                     WSDL ilustrativo del BUS + mapeo REST↔SOAP
scripts/smoke-contrato.sh           recorrido del contrato contra el mock
.spectral.yaml                      ruleset: security explícita y scopes del catálogo
```

## Flujo de trabajo

Ramas `feature/* → integration → laboratory → main`, todo por *pull request* con CI en verde.
El historial de PRs documenta cómo se construyó el entregable.
