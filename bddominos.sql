-- =============================================================
--  BASE DE DATOS: DOMINO'S PIZZA
--  Descripción : DDL completo con 10 entidades y sus relaciones
--  Motor        : MySQL 8.x / MariaDB 10.x
--  Codificación : UTF-8
--  Fecha        : 2026-05-12
-- =============================================================

CREATE DATABASE IF NOT EXISTS bddominos
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bddominos;

-- -------------------------------------------------------------
-- 1. SUCURSAL
--    Tiendas físicas de la cadena
-- -------------------------------------------------------------
CREATE TABLE sucursal (
    id_sucursal      INT            NOT NULL AUTO_INCREMENT,
    nombre           VARCHAR(100)   NOT NULL,
    direccion        VARCHAR(255)   NOT NULL,
    telefono         VARCHAR(20)    NOT NULL,
    ciudad           VARCHAR(100)   NOT NULL,
    zona             VARCHAR(50)        NULL,
    horario_apertura TIME           NOT NULL,
    horario_cierre   TIME           NOT NULL,
    activa           BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_sucursal PRIMARY KEY (id_sucursal)
) ENGINE=InnoDB;


-- -------------------------------------------------------------
-- 2. EMPLEADO
--    Personal adscrito a cada sucursal
-- -------------------------------------------------------------
CREATE TABLE empleado (
    id_empleado   INT          NOT NULL AUTO_INCREMENT,
    id_sucursal   INT          NOT NULL,
    nombre        VARCHAR(100) NOT NULL,
    telefono      VARCHAR(20)      NULL,
    rol           ENUM('gerente','cajero','cocinero','repartidor') NOT NULL,
    turno         ENUM('manana','tarde','noche')                   NOT NULL,
    fecha_ingreso DATE         NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_empleado    PRIMARY KEY (id_empleado),
    CONSTRAINT fk_emp_suc     FOREIGN KEY (id_sucursal)
        REFERENCES sucursal(id_sucursal)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX idx_empleado_sucursal ON empleado (id_sucursal);
CREATE INDEX idx_empleado_rol      ON empleado (rol);


-- -------------------------------------------------------------
-- 3. CLIENTE
--    Personas registradas que realizan pedidos
-- -------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente       INT          NOT NULL AUTO_INCREMENT,
    nombre           VARCHAR(100) NOT NULL,
    telefono         VARCHAR(20)  NOT NULL,
    email            VARCHAR(150)     NULL,
    fecha_registro   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    puntos_fidelidad INT          NOT NULL DEFAULT 0,
    activo           BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_cliente       PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_tel   UNIQUE (telefono)
) ENGINE=InnoDB;

CREATE INDEX idx_cliente_email ON cliente (email);


-- -------------------------------------------------------------
-- 4. DIRECCION
--    Domicilios registrados por cliente (puede tener varios)
-- -------------------------------------------------------------
CREATE TABLE direccion (
    id_direccion  INT          NOT NULL AUTO_INCREMENT,
    id_cliente    INT          NOT NULL,
    alias         VARCHAR(50)      NULL,
    calle         VARCHAR(150) NOT NULL,
    colonia       VARCHAR(100) NOT NULL,
    ciudad        VARCHAR(100) NOT NULL,
    codigo_postal CHAR(5)      NOT NULL,
    referencia    VARCHAR(200)     NULL,
    predeterminada BOOLEAN     NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_direccion   PRIMARY KEY (id_direccion),
    CONSTRAINT fk_dir_cli     FOREIGN KEY (id_cliente)
        REFERENCES cliente(id_cliente)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_direccion_cliente ON direccion (id_cliente);


-- -------------------------------------------------------------
-- 5. CATEGORIA
--    Agrupación de productos en el menú
-- -------------------------------------------------------------
CREATE TABLE categoria (
    id_categoria INT          NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(80)  NOT NULL,
    descripcion  VARCHAR(200)     NULL,
    orden_menu   TINYINT      NOT NULL DEFAULT 1,
    activa       BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_categoria   PRIMARY KEY (id_categoria),
    CONSTRAINT uq_cat_nombre  UNIQUE (nombre)
) ENGINE=InnoDB;


-- -------------------------------------------------------------
-- 6. PRODUCTO
--    Catálogo de artículos disponibles en el menú
-- -------------------------------------------------------------
CREATE TABLE producto (
    id_producto  INT            NOT NULL AUTO_INCREMENT,
    id_categoria INT            NOT NULL,
    nombre       VARCHAR(100)   NOT NULL,
    descripcion  TEXT               NULL,
    precio_base  DECIMAL(8,2)   NOT NULL,
    calorias     INT                NULL,
    imagen_url   VARCHAR(300)       NULL,
    disponible   BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_producto    PRIMARY KEY (id_producto),
    CONSTRAINT fk_prod_cat    FOREIGN KEY (id_categoria)
        REFERENCES categoria(id_categoria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX idx_producto_categoria  ON producto (id_categoria);
CREATE INDEX idx_producto_disponible ON producto (disponible);


-- -------------------------------------------------------------
-- 7. PEDIDO
--    Transacción principal del negocio
-- -------------------------------------------------------------
CREATE TABLE pedido (
    id_pedido    INT            NOT NULL AUTO_INCREMENT,
    id_cliente   INT            NOT NULL,
    id_sucursal  INT            NOT NULL,
    id_empleado  INT                NULL,
    id_direccion INT                NULL,
    tipo         ENUM('domicilio','recoger','local') NOT NULL,
    estado       ENUM('recibido','preparando','en_camino','entregado','cancelado')
                                    NOT NULL DEFAULT 'recibido',
    fecha_hora   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega DATETIME          NULL,
    subtotal     DECIMAL(10,2)  NOT NULL,
    descuento    DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    total        DECIMAL(10,2)  NOT NULL,
    notas        TEXT               NULL,
    CONSTRAINT pk_pedido      PRIMARY KEY (id_pedido),
    CONSTRAINT fk_ped_cli     FOREIGN KEY (id_cliente)
        REFERENCES cliente(id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_ped_suc     FOREIGN KEY (id_sucursal)
        REFERENCES sucursal(id_sucursal)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_ped_emp     FOREIGN KEY (id_empleado)
        REFERENCES empleado(id_empleado)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_ped_dir     FOREIGN KEY (id_direccion)
        REFERENCES direccion(id_direccion)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT chk_total      CHECK (total >= 0),
    CONSTRAINT chk_descuento  CHECK (descuento >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_pedido_cliente   ON pedido (id_cliente);
CREATE INDEX idx_pedido_sucursal  ON pedido (id_sucursal);
CREATE INDEX idx_pedido_estado    ON pedido (estado);
CREATE INDEX idx_pedido_fecha     ON pedido (fecha_hora);


-- -------------------------------------------------------------
-- 8. DETALLE_PEDIDO
--    Líneas de producto dentro de cada pedido
-- -------------------------------------------------------------
CREATE TABLE detalle_pedido (
    id_detalle      INT           NOT NULL AUTO_INCREMENT,
    id_pedido       INT           NOT NULL,
    id_producto     INT           NOT NULL,
    cantidad        TINYINT       NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(8,2)  NOT NULL,
    tamano          ENUM('personal','mediana','grande','familiar') NULL,
    personalizacion TEXT              NULL,
    subtotal_linea  DECIMAL(8,2)  NOT NULL,
    CONSTRAINT pk_detalle       PRIMARY KEY (id_detalle),
    CONSTRAINT fk_det_ped       FOREIGN KEY (id_pedido)
        REFERENCES pedido(id_pedido)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_det_prod      FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_cantidad     CHECK (cantidad > 0),
    CONSTRAINT chk_precio_unit  CHECK (precio_unitario >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_detalle_pedido   ON detalle_pedido (id_pedido);
CREATE INDEX idx_detalle_producto ON detalle_pedido (id_producto);


-- -------------------------------------------------------------
-- 9. INVENTARIO
--    Control de stock de ingredientes/productos por sucursal
-- -------------------------------------------------------------
CREATE TABLE inventario (
    id_inventario        INT           NOT NULL AUTO_INCREMENT,
    id_sucursal          INT           NOT NULL,
    id_producto          INT           NOT NULL,
    unidad_medida        VARCHAR(20)   NOT NULL,
    stock_actual         DECIMAL(8,2)  NOT NULL DEFAULT 0,
    stock_minimo         DECIMAL(8,2)  NOT NULL DEFAULT 0,
    ultima_actualizacion DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                       ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_inventario    PRIMARY KEY (id_inventario),
    CONSTRAINT uq_inv_suc_prod  UNIQUE (id_sucursal, id_producto),
    CONSTRAINT fk_inv_suc       FOREIGN KEY (id_sucursal)
        REFERENCES sucursal(id_sucursal)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_inv_prod      FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT chk_stock        CHECK (stock_actual >= 0),
    CONSTRAINT chk_stock_min    CHECK (stock_minimo >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_inventario_sucursal ON inventario (id_sucursal);
CREATE INDEX idx_inventario_producto ON inventario (id_producto);


-- -------------------------------------------------------------
-- 10. PAGO
--     Registro de transacciones de cobro por pedido
-- -------------------------------------------------------------
CREATE TABLE pago (
    id_pago    INT           NOT NULL AUTO_INCREMENT,
    id_pedido  INT           NOT NULL,
    metodo     ENUM('efectivo','tarjeta','app','transferencia') NOT NULL,
    monto      DECIMAL(10,2) NOT NULL,
    referencia VARCHAR(100)      NULL,
    estado     ENUM('pendiente','aprobado','rechazado','devuelto')
                              NOT NULL DEFAULT 'pendiente',
    fecha_hora DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_pago      PRIMARY KEY (id_pago),
    CONSTRAINT fk_pago_ped  FOREIGN KEY (id_pedido)
        REFERENCES pedido(id_pedido)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_monto    CHECK (monto > 0)
) ENGINE=InnoDB;

CREATE INDEX idx_pago_pedido ON pago (id_pedido);
CREATE INDEX idx_pago_estado ON pago (estado);


-- =============================================================
--  DATOS DE EJEMPLO (seed mínimo para pruebas)
-- =============================================================

INSERT INTO categoria (nombre, descripcion, orden_menu) VALUES
    ('Pizzas',    'Pizzas en varios tamaños y estilos', 1),
    ('Alitas',    'Alitas con diferentes salsas',       2),
    ('Entradas',  'Complementos y botanas',             3),
    ('Bebidas',   'Refrescos y agua',                   4),
    ('Postres',   'Pays y postres Dominos',             5);

INSERT INTO producto (id_categoria, nombre, descripcion, precio_base, disponible) VALUES
    (1, 'Pizza Pepperoni Mediana',  'Salsa de tomate, queso, pepperoni',          219.00, TRUE),
    (1, 'Pizza Hawaiana Grande',    'Salsa de tomate, queso, jamón, piña',        259.00, TRUE),
    (1, 'Pizza Mexicana Familiar',  'Jalapeños, chorizo, cebolla, queso',         299.00, TRUE),
    (2, 'Alitas BBQ x8',            'Alitas bañadas en salsa BBQ',                149.00, TRUE),
    (2, 'Alitas Buffalo x8',        'Alitas bañadas en salsa Buffalo',            149.00, TRUE),
    (3, 'Pan de ajo',               'Pan artesanal con mantequilla de ajo',        59.00, TRUE),
    (4, 'Coca-Cola 600ml',          'Refresco de cola',                            35.00, TRUE),
    (5, 'Pay de Queso',             'Rebanada de pay de queso con fresa',          55.00, TRUE);

INSERT INTO sucursal (nombre, direccion, telefono, ciudad, zona, horario_apertura, horario_cierre) VALUES
    ('Sucursal Centro',  'Av. Juárez 120, Centro',         '656-100-0001', 'Ciudad Juárez', 'Centro',  '11:00:00', '23:00:00'),
    ('Sucursal Norte',   'Blvd. Independencia 4500, Norte','656-100-0002', 'Ciudad Juárez', 'Norte',   '11:00:00', '23:30:00');

INSERT INTO empleado (id_sucursal, nombre, telefono, rol, turno, fecha_ingreso) VALUES
    (1, 'María González',   '656-200-0001', 'gerente',    'manana', '2021-03-15'),
    (1, 'Carlos Ramos',     '656-200-0002', 'cocinero',   'tarde',  '2022-07-01'),
    (1, 'Jesús Montes',     '656-200-0003', 'repartidor', 'tarde',  '2023-01-10'),
    (2, 'Lucía Hernández',  '656-200-0004', 'gerente',    'manana', '2020-11-20'),
    (2, 'Pedro Salcido',    '656-200-0005', 'cajero',     'noche',  '2023-06-05');

INSERT INTO cliente (nombre, telefono, email, puntos_fidelidad) VALUES
    ('Ana Martínez',  '656-300-0001', 'ana.martinez@email.com',  150),
    ('Luis Pérez',    '656-300-0002', 'luis.perez@email.com',     80),
    ('Sofia Torres',  '656-300-0003', NULL,                        0);

INSERT INTO direccion (id_cliente, alias, calle, colonia, ciudad, codigo_postal, predeterminada) VALUES
    (1, 'Casa',    'Calle Roble 45',      'Jardines del Sol', 'Ciudad Juárez', '32500', TRUE),
    (1, 'Trabajo', 'Av. Lincoln 890',     'Centro',           'Ciudad Juárez', '32000', FALSE),
    (2, 'Casa',    'Paseo del Norte 210', 'Infonavit Norte',  'Ciudad Juárez', '32320', TRUE);

INSERT INTO inventario (id_sucursal, id_producto, unidad_medida, stock_actual, stock_minimo) VALUES
    (1, 1, 'piezas', 50, 10),
    (1, 2, 'piezas', 40, 10),
    (1, 4, 'kg',     15,  5),
    (2, 1, 'piezas', 60, 10),
    (2, 3, 'piezas', 35, 10);

-- Pedido de prueba
INSERT INTO pedido (id_cliente, id_sucursal, id_empleado, id_direccion, tipo, estado, subtotal, descuento, total)
VALUES (1, 1, 3, 1, 'domicilio', 'entregado', 368.00, 0.00, 368.00);

INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario, tamano, subtotal_linea)
VALUES
    (1, 1, 1, 219.00, 'mediana', 219.00),
    (1, 4, 1, 149.00, NULL,      149.00);

INSERT INTO pago (id_pedido, metodo, monto, referencia, estado)
VALUES (1, 'tarjeta', 368.00, 'TXN-20260512-001', 'aprobado');


-- =============================================================
--  VISTAS ÚTILES
-- =============================================================

CREATE OR REPLACE VIEW v_pedidos_detalle AS
SELECT
    p.id_pedido,
    p.fecha_hora,
    c.nombre        AS cliente,
    c.telefono      AS tel_cliente,
    s.nombre        AS sucursal,
    p.tipo,
    p.estado,
    p.total,
    pa.metodo       AS metodo_pago,
    pa.estado       AS estado_pago
FROM pedido p
JOIN cliente  c  ON c.id_cliente  = p.id_cliente
JOIN sucursal s  ON s.id_sucursal = p.id_sucursal
LEFT JOIN pago pa ON pa.id_pedido  = p.id_pedido;


CREATE OR REPLACE VIEW v_inventario_bajo AS
SELECT
    s.nombre        AS sucursal,
    pr.nombre       AS producto,
    i.unidad_medida,
    i.stock_actual,
    i.stock_minimo,
    (i.stock_minimo - i.stock_actual) AS faltante
FROM inventario i
JOIN sucursal s  ON s.id_sucursal = i.id_sucursal
JOIN producto pr ON pr.id_producto = i.id_producto
WHERE i.stock_actual < i.stock_minimo
ORDER BY faltante DESC;


CREATE OR REPLACE VIEW v_ventas_por_sucursal AS
SELECT
    s.nombre               AS sucursal,
    COUNT(p.id_pedido)     AS total_pedidos,
    SUM(p.total)           AS ingresos_total,
    AVG(p.total)           AS ticket_promedio
FROM pedido p
JOIN sucursal s ON s.id_sucursal = p.id_sucursal
WHERE p.estado = 'entregado'
GROUP BY s.id_sucursal, s.nombre
ORDER BY ingresos_total DESC;

-- =============================================================
--  FIN DEL SCRIPT
-- =============================================================
