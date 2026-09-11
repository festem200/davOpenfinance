# ADR-0005 · El aliado nunca ve productos, PAN ni credenciales del titular

**Estado:** aceptada · **Fecha:** 2026-09-10

## Contexto
Un cobro necesita saber contra qué producto se ejecuta. La forma obvia — que el aliado pida
al titular su número de cuenta o de tarjeta, o que liste sus productos — arrastra al aliado
al alcance PCI-DSS y a la custodia de datos financieros, y en Colombia el iniciador tiene
prohibido acceder a claves o mecanismos de autenticación del ordenante (art. 2.17.4.1.3
num. 4 del Decreto 2555 de 2010).

## Alternativas
1. El aliado captura el PAN / número de cuenta (con tokenización posterior).
2. El aliado lista los productos del titular vía API y elige.
3. **El titular elige su producto en la entidad** durante la confirmación; el aliado recibe
   una referencia opaca y un enmascarado.

## Decisión
La opción 3. El aliado declara solo el *tipo* de instrumento; la entidad autentica al
titular, le muestra sus productos y registra la elección en el consentimiento. El aliado
recibe `productReference` (opaca, válida solo para él) y `maskedNumber` (`****4821`).

## Consecuencias
- El alcance PCI-DSS del aliado es cero por construcción; el numeral 6.2 de la CE 004/2024
  (QSA + AoC) no se le aplica porque no almacena, procesa ni transmite datos de tarjeta.
- No existe endpoint que reciba credenciales ni que liste productos del cliente.
- La resolución `productReference → token del core` ocurre dentro del adaptador SOAP.
- En el flujo desacoplado (CIBA), el aliado necesita un `login_hint` que el titular ya le
  entregó legítimamente; nunca credenciales.
