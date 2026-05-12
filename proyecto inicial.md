Como administrador de bases de datos, aquí están las entidades principales que necesitaría para gestionar un sistema como Domino's Pizza:Aquí el resumen de las **10 entidades** identificadas y su justificación:
<img width="940" height="486" alt="image" src="https://github.com/user-attachments/assets/7f2ef34f-be0f-44da-8e61-d6d4fab20656" />

---

**Núcleo operativo**

- `SUCURSAL` — cada tienda física, con su zona y datos de contacto. Es el centro de todo: procesa pedidos, tiene empleados y controla su propio inventario.
- `PEDIDO` — entidad principal del negocio. Registra tipo (domicilio, recoger, en local), estado (en preparación, en camino, entregado) y se conecta con casi todo el modelo.
- `DETALLE_PEDIDO` — tabla pivote entre `PEDIDO` y `PRODUCTO`. Permite múltiples productos por pedido con cantidad, precio y personalizaciones (sin jitomate, extra queso, etc.).

**Catálogo de productos**

- `PRODUCTO` — pizzas, alitas, bebidas, postres. Incluye precio base y disponibilidad.
- `CATEGORIA` — agrupa los productos (pizzas, entradas, bebidas...). Facilita el menú y filtros.

**Clientes y entrega**

- `CLIENTE` — historial de compras, datos de contacto y fidelización.
- `DIRECCION` — separada del cliente para que pueda tener varias (casa, trabajo) y reutilizarlas en futuros pedidos.

**Operaciones internas**

- `EMPLEADO` — incluye el rol (repartidor, cocinero, cajero, gerente) y turno. Se asocia al pedido para saber quién lo tomó o lo entregó.
- `INVENTARIO` — control de stock por sucursal, con un mínimo configurable para disparar alertas de reabastecimiento.
- `PAGO` — separado del pedido para soportar múltiples métodos (efectivo, tarjeta, app) y registrar el estado de la transacción.

---

¿Quieres profundizar en alguna entidad, definir los índices, las reglas de negocio, o hablar de normalización y particionamiento?

Las entidades con sus atributos y tipo en forma de tabla para cada una de las entidades
<img width="664" height="690" alt="image" src="https://github.com/user-attachments/assets/cc335b06-38eb-4db7-8475-23df7cff1405" />
<img width="659" height="657" alt="image" src="https://github.com/user-attachments/assets/ce3687a8-7b4f-4885-8b6c-8db981845f2c" />
<img width="586" height="736" alt="image" src="https://github.com/user-attachments/assets/272d85f9-a535-4da2-a7f2-786650d05965" />
<img width="657" height="562" alt="image" src="https://github.com/user-attachments/assets/cdcafb52-1b2f-4601-914f-f7370e703bf1" />
<img width="662" height="604" alt="image" src="https://github.com/user-attachments/assets/5fc0595c-8a61-4948-ac12-294a8a0c0b96" />
Las 10 entidades quedan documentadas con sus atributos completos. Algunos criterios de diseño que vale la pena destacar:
DETALLE_PEDIDO guarda precio_unitario como campo propio (no referencia al catálogo) para que el precio histórico quede fijo aunque el menú cambie después.
INVENTARIO usa DECIMAL en lugar de INT para el stock, pensando en ingredientes que se miden por peso o volumen (kg de queso, litros de salsa), no solo por piezas.
PAGO es una entidad separada de PEDIDO para soportar pagos divididos o reembolsos parciales sin alterar el pedido original.
Los campos ENUM (estado, tipo, rol, método) conviene implementarlos como tablas de catálogo independientes en producción, para mayor flexibilidad.
¿Quieres que continúe con los índices recomendados, las relaciones con cardinalidad detallada, o el script DDL en SQL?
