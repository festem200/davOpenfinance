# Registros de decisión (ADR)

Decisiones de diseño que un lector podría cuestionar y que conviene dejar con su contexto,
alternativas y consecuencias. Formato corto; una decisión por archivo.

| # | Decisión | Estado |
|---|---|---|
| [0001](./ADR-0001-un-recurso-payments-dos-rieles.md) | Un solo recurso `/payments` con dos rieles | Aceptada |
| [0002](./ADR-0002-fapi2-puro-mas-requisitos-colombianos.md) | FAPI 2.0 puro más los requisitos literales de la CE 004/2024 | Aceptada |
| [0003](./ADR-0003-mtls-sobre-dpop.md) | Tokens vinculados por mTLS (RFC 8705), DPoP como secundario | Aceptada |
| [0004](./ADR-0004-timeout-del-core-es-pending-no-504.md) | Un timeout del core produce `201 PENDING`, nunca `504` | Aceptada |
| [0005](./ADR-0005-el-aliado-no-ve-productos-ni-credenciales.md) | El aliado nunca ve productos, PAN ni credenciales del titular | Aceptada |
| [0006](./ADR-0006-webhooks-firmados-mas-feed.md) | Eventos por webhook firmado **y** feed pull | Aceptada |
