# 🍕 Plan de Implementación: Aplicación "Domino's Pizza" (Flutter + Firebase + Provider)

## 📋 1. Resumen del Proyecto
- **Objetivo**: Desarrollar una aplicación multiplataforma (Android, iOS, Web) que simule el flujo principal de pedido de Domino's Pizza.
- **Stack Tecnológico**: Flutter/Dart, Firebase (Authentication + Firestore), Provider (gestión de estado), VS Code (IDE principal).
- **Alcance Funcional**: Registro/Login con email/contraseña, exploración de menú, carrito de compras, creación de pedidos, seguimiento básico de estado, perfiles de usuario.

> ⚠️ Nota sobre el IDE: *Antigravity* no es un entorno de desarrollo reconocido para Flutter. Se recomienda **VS Code** (con extensiones oficiales) como solicitaste, complementado con **Android Studio** y/o **Xcode** únicamente para gestionar emuladores y firmas de compilación.

---

## 🛠️ 2. Herramientas Requeridas
| Categoría | Herramienta | Propósito |
|-----------|-------------|-----------|
| **SDK & Lenguaje** | Flutter SDK, Dart | Desarrollo UI y lógica |
| **IDE** | VS Code + Extensiones (Flutter, Dart, Firebase, Error Lens) | Edición, depuración, formateo |
| **Emuladores/Simuladores** | Android Emulator, iOS Simulator | Pruebas en tiempo real |
| **Backend** | Firebase Console, Firebase CLI | Auth, Firestore, Hosting, Crashlytics |
| **Diseño UI/UX** | Figma, Adobe XD o Penpot | Prototipado, diseño de componentes, guía de estilos |
| **Control de Versiones** | Git + GitHub/GitLab | Historial, colaboración, CI/CD |
| **Pruebas** | Firebase Emulator Suite, Flutter Test Runner | Validación local antes de producción |
| **Gestión de Entornos** | `flutter_dotenv` o archivos de configuración separados | Separación de claves y URLs por entorno |

---

## 🎨 3. Directrices UI/UX
- **Identidad Visual**: Paleta basada en rojo corporativo (`#E31837`), azul (`#006491`), blanco y grises neutros. Tipografía legible y jerárquica.
- **Navegación**: Barra inferior (`BottomNavigationBar`) con secciones: Inicio, Menú, Carrito, Pedidos, Perfil.
- **Componentes Clave**:
  - Tarjetas de producto con imagen, nombre, descripción corta, precio y selector de tamaño.
  - Modal o Drawer para el carrito con edición de cantidades y resumen de totales.
  - Formularios de autenticación con validación en tiempo real y mensajes de error accesibles.
  - Indicadores de carga (`CircularProgressIndicator`/skeleton screens) y estados vacíos con ilustraciones.
- **Responsive & Accesibilidad**: Adaptación a tablets y web, contraste WCAG AA, etiquetas semánticas, áreas táctiles mínimas de 44x44px.

---

## 📦 4. Dependencias (`pubspec.yaml`)
*(Listado conceptual por categoría; se deben agregar en `dependencies` y `dev_dependencies`)*

**Core & Firebase**
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`

**Estado & Navegación**
- `provider`
- `go_router` (o `auto_route`)

**UI & Utilidades**
- `cached_network_image`
- `flutter_svg`
- `intl` (formato de moneda/fecha)
- `flutter_form_builder` + `form_builder_validators` (opcional, si se usa validación declarativa)
- `logger`

**Persistencia & Seguridad**
- `flutter_secure_storage` (tokens/sesiones)
- `shared_preferences` (preferencias locales como dirección última seleccionada)

**Dev**
- `flutter_lints`
- `mockito` o `mocktail`
- `integration_test`
- `build_runner` (si se usan generadores de código)

---

## 🔐 5. Flujo de Autenticación (Email/Password)
1. **Registro**: Captura de email, contraseña, confirmación. Validación de formato y fuerza mínima. Creación de documento en `users/{uid}`.
2. **Inicio de Sesión**: Verificación de credenciales, manejo de errores (usuario no encontrado, contraseña incorrecta, red).
3. **Recuperación**: Envío de enlace de restablecimiento por correo, UI de confirmación y redirección.
4. **Persistencia de Sesión**: Uso de `setPersistence` o almacenamiento seguro para mantener autenticación entre reinicios.
5. **Guardias de Ruta**: Middleware que redirige a login si no hay sesión activa; bloquea acceso a rutas autenticadas para usuarios invitados.

---

## 🗄️ 6. Estructura de Firestore
| Colección | Documento | Campos Principales |
|-----------|-----------|-------------------|
| `users` | `{userId}` | `email`, `displayName`, `createdAt`, `addresses[]`, `lastOrderRef` |
| `menu` | `{categoryId}` → subcolección `items` | `id`, `name`, `description`, `priceBase`, `imageURL`, `available`, `sizes[]`, `toppings[]` |
| `orders` | `{orderId}` | `userId`, `items[]` (con id, cantidad, personalizaciones), `total`, `status` (`pending`, `preparing`, `delivering`, `completed`), `address`, `createdAt`, `updatedAt` |

**Reglas de Seguridad**:
- `users`: solo lectura/escritura por el `userId` propietario.
- `menu`: lectura pública, escritura restringida a roles administrativos (si aplica).
- `orders`: creación permitida con `auth.uid == request.resource.data.userId`, lectura/actualización solo por el creador o admin.

---

## 🧩 7. Arquitectura con Provider
- **`AuthProvider`**: Expone `currentUser`, `isAuthenticated`, métodos `signIn`, `signUp`, `signOut`, `resetPassword`. Maneja la escucha de cambios de estado de Firebase Auth.
- **`MenuProvider`**: Carga categorías y productos bajo demanda, implementa caché local para evitar lecturas repetidas, expone filtros y búsqueda.
- **`CartProvider`**: Estado del carrito en memoria, sincronización opcional con Firestore para recuperación entre sesiones, cálculo de totales, aplicación de impuestos/envío.
- **`OrderProvider`**: Gestión del flujo de checkout, envío a Firestore, suscripción en tiempo real al estado del pedido, manejo de reintentos y errores de red.
- **Inyección**: `MultiProvider` en la raíz de la app, con `ChangeNotifierProvider` o `Provider` según inmutabilidad requerida. Separación estricta entre capa de presentación y lógica de negocio.

---

## 📝 8. Procedimiento Paso a Paso (Sin Código)

### Fase 1: Configuración Inicial
1. Instalar Flutter SDK, Dart y verificar con `flutter doctor`.
2. Configurar VS Code con extensiones oficiales.
3. Crear proyecto Flutter multiplataforma.
4. Crear proyecto en Firebase Console, registrar apps Android/iOS/Web, descargar `google-services.json` y `GoogleService-Info.plist`.
5. Inicializar Firebase en la app y configurar variables de entorno para claves y `appId`.

### Fase 2: Diseño UI/UX
1. Definir wireframes en Figma para pantallas clave: Login, Registro, Inicio, Detalle de Pizza, Carrito, Checkout, Historial.
2. Establecer sistema de diseño: colores, tipografías, espaciado, componentes reutilizables.
3. Exportar assets optimizados y definir estructura de carpetas del proyecto por características (`/features/auth`, `/features/menu`, etc.).

### Fase 3: Integración Firebase & Autenticación
1. Implementar inicialización segura de Firebase.
2. Crear vistas de Login/Registro con validación de formularios.
3. Conectar con Firebase Auth (email/password), manejar excepciones comunes.
4. Implementar recuperación de contraseña y verificación de correo (opcional).
5. Crear documento de usuario en Firestore tras registro exitoso.
6. Configurar guardias de navegación basadas en estado de autenticación.

### Fase 4: Modelo de Datos & Firestore
1. Definir clases de datos (DTO/Models) para Usuario, Producto, Item de Carrito, Pedido.
2. Implementar repositorios o servicios para lectura/escritura en Firestore.
3. Configurar índices compuestos si se requiere búsqueda o filtrado avanzado.
4. Validar reglas de seguridad en Emulator Suite antes de desplegar a producción.

### Fase 5: State Management con Provider
1. Crear `AuthProvider`, `MenuProvider`, `CartProvider`, `OrderProvider`.
2. Configurar `MultiProvider` en `main`.
3. Vincular UI a proveedores mediante `Consumer` o `Provider.of`.
4. Implementar notificación de cambios (`notifyListeners`) solo en mutaciones de estado relevantes.
5. Añadir persistencia local para carrito y última dirección seleccionada.

### Fase 6: Desarrollo de Funcionalidades Principales
1. **Menú**: Listado paginado o por categorías, carga diferida de imágenes, estado de disponibilidad.
2. **Carrito**: Agregar/eliminar items, ajustar cantidades, calcular subtotales, impuestos, envío.
3. **Checkout**: Selección de dirección, resumen, confirmación, creación de documento en `orders`.
4. **Seguimiento**: Suscripción en tiempo real al estado del pedido, UI de progreso por etapas.
5. **Perfil**: Edición de datos básicos, direcciones guardadas, historial de pedidos.

### Fase 7: Navegación & UX Refinada
1. Configurar enrutamiento centralizado con `go_router`.
2. Implementar transiciones suaves entre pantallas.
3. Añadir manejo global de errores y estados de carga.
4. Optimizar rendimiento: evitar rebuilds innecesarios, usar `const`, lazy loading.

### Fase 8: Pruebas
1. **Unitarias**: Lógica de cálculo de carrito, validaciones de formulario, parsing de modelos.
2. **Widget**: Renderizado de componentes, interacciones básicas, estados vacíos/carga.
3. **Integración**: Flujo completo login → selección → carrito → pedido (usando Emulator Suite).
4. **Performance**: Profiling con Flutter DevTools, revisión de frames por segundo, uso de memoria.

### Fase 9: Despliegue & CI/CD
1. Configurar firma de apps Android (keystore) y iOS (provisioning profiles).
2. Ejecutar `flutter build` para cada plataforma.
3. Subir a Firebase App Distribution para pruebas internas.
4. Publicar en Play Store y App Store siguiendo lineamientos de revisión.
5. (Opcional) Implementar pipeline con GitHub Actions para builds automáticos y pruebas.

---

## ✅ 9. Estrategia de Mantenimiento & Escalabilidad
- Monitoreo con Firebase Crashlytics y Performance Monitoring.
- Implementación de Analytics para seguimiento de conversiones (carrito abandonado, pedidos completados).
- Estructura de carpetas escalable (`features/`, `core/`, `shared/`).
- Documentación interna de flujos y decisiones arquitectónicas.
- Plan de actualización de dependencias trimestral para mantener compatibilidad y seguridad.

---

## 📌 10. Recomendaciones Finales
- **No hardcodees claves**: Usa variables de entorno o archivos `.env` ignorados por Git.
- **Valida siempre en cliente y servidor**: Firestore Rules son la última línea de defensa.
- **Provider es suficiente para este alcance**, pero si el proyecto crece, evalúa `riverpod` para inyección más segura y compilación anticipada.
- **Mantén la UI desacoplada**: Los proveedores no deben conocer widgets, solo modelos y estados.
- **Prueba con datos realistas**: Usa seeds en Firestore emulado para validar paginación, listas largas y estados de error.

Este plan está listo para servir como hoja de ruta completa antes de iniciar la escritura de código. Cuando desees, puedo generar el esqueleto de carpetas, los diagramas de flujo de datos o las especificaciones detalladas de cada proveedor.
