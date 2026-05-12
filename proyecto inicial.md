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
