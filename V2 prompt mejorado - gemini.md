# 📜 PROMPT MAESTRO: ESPECIFICACIÓN TÉCNICA ARQUITECTÓNICA v2.0
## Sistema de Gestión Transaccional Cloud-Native "Antigravity Domino's"
**Versión:** 2.0.0 | **Entorno:** Dart 3.5+ / Flutter 3.22+ | **Backend:** Ecosistema Firebase (Firestore, Cloud Functions, Auth, Storage) | **Plataformas:** Android, iOS, Web (PWA), Windows | **Alcance:** Grado Empresarial, Offline-First, Preparado para Multi-Tenant

---

### 🎯 VISIÓN ARQUITECTÓNICA Y CONTEXTO CLOUD
Actúa como **Arquitecto de Soluciones Principal e Ingeniero Cloud** especializado en sistemas transaccionales de alta concurrencia, arquitecturas reactivas y plataformas de consumo masivo (QSR/Retail). Tu misión es diseñar e implementar los cimientos técnicos de una solución nativa para la nube, escalable y tolerante a fallos, capaz de gestionar miles de pedidos concurrentes con precisión financiera absoluta, sincronización en tiempo real y una operación offline robusta. 

El sistema debe adherirse estrictamente a la **Arquitectura Limpia (Clean Architecture)**, donde Firebase se trata exclusivamente como un **detalle de infraestructura** aislado en la capa de datos. El dominio permanece puro, comprobable (`testable`) e independiente de proveedores. La plataforma debe cumplir con estándares de ingeniería moderna: inmutabilidad, tipado estricto, CI/CD automatizado, observabilidad completa y gobernanza de datos bajo regulaciones de privacidad (GDPR/LGPD).

---

### 🏛️ 1. ARQUITECTURA CLOUD-NATIVE E INTEGRACIÓN FIREBASE
Implementa una arquitectura hexagonal donde cada capa tiene responsabilidades delimitadas y Firebase se consume únicamente en los bordes del sistema.

- **📦 Capa de Dominio (`domain/`)**
  - Entidades inmutables (`@freezed`), Objetos de Valor, Casos de Uso puros (`Callable`/`UseCase`).
  - **Cero importaciones de Firebase, SDK de Firebase o `package:flutter`**.
  - Contratos de repositorio abstractos (`OrderRepository`, `InventoryRepository`).
  - Manejo de errores explícito con `Either<Failure, T>` o `Result<T, Failure>`.
  - Reglas de negocio invariantes: validación de sucursal-Empleado, máquina de estados, umbrales de inventario.

- **🗄️ Capa de Datos (`data/`)**
  - `RemoteDataSource`: Envoltorio tipado sobre `cloud_firestore` y `cloud_functions`. Implementa `runTransaction`, `batch` y `serverTimestamp`.
  - `LocalDataSource`: Caché offline con `hive`/`isar` o persistencia nativa de Firebase. Estrategia `L1 (Memoria) → L2 (Disco) → L3 (Nube)`.
  - `RepositoryImpl`: Orquestador que aplica políticas de respaldo, reconciliación de conflictos y mapeo `Snapshot → DTO → Entity`.
  - **Firebase como Detalle de Infraestructura:** Solo referenciado aquí. Uso de `FirebaseApp.initializeApp()` controlado por `core/injector/`.

- **⚡ Cloud Functions y Lógica del Servidor**
  - Lógica crítica (validación atómica de inventario, cálculo de impuestos, transiciones de estado, generación de recibos) ejecutada en **Cloud Functions (2da Generación)**.
  - Prevención de manipulación desde el cliente: Reglas de Seguridad de Firestore rechazan escrituras directas a `inventory.stock_actual` sin verificación por función.
  - Colas de mensajería: `Pub/Sub` o `Task Queues` para procesamiento asíncrono (notificaciones, auditoría, reconciliación de pagos).

---

### ☁️ 2. ESTRATEGIA DE DATOS EN LA NUBE, SINCRONIZACIÓN Y OFFLINE-FIRST
Diseña un flujo de datos resiliente, predecible y optimizado para redes inestables.

- **📊 Estructura Firestore (Colecciones y Subcolecciones)**
  ```
  /categories/{catId}
  /products/{prodId} (subcolección: /variants/{varId})
  /branches/{branchId}
  /inventory/{branchId}/stock/{productId} → {stock_actual, stock_minimo, version, last_sync}
  /orders/{orderId} → {cliente, direccion, empleado_id, estado, total, created_at}
    /items/{itemId} → {producto_id, cantidad, personalizacion (Map/JSON), precio_unitario}
  /payments/{paymentId} → {metodo, monto, estado, referencia, id_pedido}
  /users/{uid} → {rol, sucursal_asignada, perfil, historial_fidelidad}
  ```

- **🔄 Sincronización y Estrategia Offline**
  - `enablePersistence()` activado con límites de caché (`cacheSizeBytes: 50MB`).
  - **UI Optimista:** BLoC emite `OrderSubmittedOptimistic` → actualiza UI inmediatamente → Cloud Function confirma o rechaza → BLoC emite `OrderConfirmed`/`OrderRejected` con rollback si falla.
  - **Cola de Reintentos:** `workmanager` (Android) / `BGTaskScheduler` (iOS) / `BackgroundSync` (Web) para enviar transacciones pendientes.
  - **Resolución de Conflictos:** `last-write-wins` con `serverTimestamp` + validación de `version` en inventario. Rechazo automático si `stock_actual < 0`.

- **📦 Firebase Storage y Activos**
  - Estructura: `/products/{id}/main.webp`, `/receipts/{orderId}.pdf`, `/delivery/{orderId}/photo.webp`.
  - Compresión automática, CDN habilitado, reglas de acceso por rol y tiempo de expiración.

---

### 📱 3. IMPLEMENTACIÓN MULTIPLATAFORMA (Android / iOS / Web / Windows)
Una única base de código, adaptaciones específicas por plataforma y comportamientos nativos optimizados.

| Plataforma | Optimizaciones Clave | Integraciones Firebase/Nativas |
|------------|----------------------|--------------------------------|
| **Android** | SDK Objetivo 34+, Material 3, renderizado virtualizado, listas perezosas (`LazyColumn/GridView`), `SafeArea` estricto | FCM, WorkManager, App Links, Google Play Billing (futuro), Crashlytics NDK |
| **iOS** | Interoperación Swift mínima, `Background App Refresh`, optimizaciones de memoria y ciclo de vida | FCM (proxy APNs), Universal Links, App Clips (reorden rápido), Sign in with Apple |
| **Web (PWA)** | Service Workers, `go_router` con URLs limpias, `LayoutBuilder` responsivo, `IndexedDB` como respaldo | Firebase Hosting, Analytics (GA4), Remote Config para pruebas A/B, manifiesto PWA y caché offline |
| **Windows** | Empaquetado MSIX, `NavigationRail` maestro-detalle, `FocusTraversal` para teclado, soporte alto DPI | Caché local SQLite como respaldo, Notificaciones de Windows, optimizaciones de renderizado Direct3D |

- **🌐 Enrutamiento y Deep Linking:** `go_router` con guardas de `redirect`, enlaces profundos (`antigravity://pedido/123`), enlaces universales (`https://antigravity.com/pedido/123`), restauración de estado por plataforma.
- **📐 Marco Responsivo:** Puntos de corte dinámicos (`móvil <600`, `tableta 600-1024`, `escritorio >1024`), adaptativo con `MediaQuery`, `responsive_framework` para escalado de UI sin pérdida de densidad.

---

### 🔒 4. SEGURIDAD, GOBERNANZA Y FIREBASE CONSOLE/STUDIO
- **🛡️ Reglas de Seguridad de Firestore (RBAC y Validación de Campos)**
  ```javascript
  match /orders/{orderId} {
    // Permitir lectura solo si el usuario está autenticado y es el dueño del pedido
    allow read: if request.auth != null && resource.data.cliente_id == request.auth.uid;
    // Permitir creación solo con estado inicial válido y empleado asignado correctamente
    allow create: if request.auth != null && request.resource.data.estado == "RECIBIDO"
                    && request.resource.data.empleado_id in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.sucursales_asignadas;
    // Permitir actualización solo para transiciones de estado válidas
    allow update: if request.auth != null && 
                    (resource.data.estado in ["RECIBIDO","EN_PREPARACION","HORNEANDO","EN_CAMINO"] &&
                     request.resource.data.estado == getNextValidState(resource.data.estado));
  }
  ```
- **🔐 Cumplimiento y Privacidad:** PII cifrada en tránsito (TLS 1.3) y en reposo. Campos sensibles (`teléfono`, `dirección_exacta`) tokenizados u ofuscados en registros. Auditoría vía Cloud Logging con retención de 90 días.
- **📊 Firebase Console y Studio:**
  - **Firebase Studio:** Prototipado rápido de esquemas, prueba de reglas, simulación de carga con `Firebase Local Emulator Suite`.
  - **Crashlytics y Performance:** Rastreo de `ANR`, congelamientos, inicio en frío, red lenta. Métricas de `Time to Interactive` y `Frame Drops`.
  - **Analytics y Remote Config:** Embudo de conversión (Catálogo → Carrito → Pago → Entrega), flags de funciones, banners promocionales dinámicos sin redespliegue.
  - **App Distribution:** Pruebas beta por canal (dev, staging, prod), despliegue progresivo, reversión automática ante métricas críticas.

---

### 📦 5. PILA DE DEPENDENCIAS Y HERRAMIENTAS FIREBASE
```yaml
dependencies:
  flutter: sdk: flutter
  flutter_bloc: ^9.0.0
  equatable: ^2.0.5
  go_router: ^14.0.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  decimal: ^3.0.0
  get_it: ^8.0.0
  logger: ^2.0.2+1
  responsive_framework: ^1.1.1
  intl: ^0.20.0
  formz: ^0.7.0

  # Ecosistema Firebase
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
  firebase_auth: ^5.0.0
  firebase_storage: ^12.0.0
  firebase_messaging: ^15.0.0
  firebase_remote_config: ^5.0.0
  firebase_analytics: ^11.0.0
  firebase_crashlytics: ^4.0.0
  cloud_functions: ^5.0.0

dev_dependencies:
  flutter_test: sdk: flutter
  build_runner: ^2.4.8
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  mocktail: ^1.0.4
  bloc_test: ^9.1.0
  lint: ^2.3.0
  firebase_core_platform_interface: ^5.0.0 # para emuladores
```
- **Cadena de Herramientas:** `flutterfire configure`, `firebase emulators:start --only firestore,auth,functions`, `flutter analyze --fatal-infos`, `dart format .`, GitHub Actions (lint → test → build → deploy Firebase Hosting/Play/App Store).
- **Gobernanza:** Confirmaciones semánticas (`feat:`, `fix:`, `chore:`, `refactor:`), plantillas de PR con lista de verificación de seguridad, cobertura mínima del 80 %, pruebas unitarias por capa, mocks estrictos del SDK de Firebase.

---

### 📤 6. ENTREGABLES TÉCNICOS ESPERADOS (GENERACIÓN INMEDIATA)
Proporciona **exclusivamente** los siguientes artefactos listos para integración en un pipeline CI/CD:

1. **📁 Estructura de Directorios (Arquitectura Limpia + Cloud-Native)**
   ```
   lib/
   ├── core/
   │   ├── constants/          # Rutas, colecciones Firebase, puntos de corte
   │   ├── errors/             # Fallos, Either, excepciones de dominio
   │   ├── network/            # Interceptores Dio, políticas de reintento, cabeceras de caché
   │   ├── utils/              # Formateadores, validadores, auxiliares de moneda
   │   └── theme/              # ThemeData, tokens, tipografía, mixins responsivos
   ├── data/
   │   ├── datasources/        # Remoto (Firestore/Functions), Local (Hive/Isar)
   │   ├── models/             # DTOs (@freezed + @JsonSerializable)
   │   └── repositories/       # Contratos → Implementaciones con lógica de sincronización
   ├── domain/
   │   ├── entities/           # Objetos puros de negocio
   │   ├── repositories/       # Interfaces abstractas
   │   └── usecases/           # ColocaciónPedido, VerificarStock, TransiciónEstado
   ├── presentation/
   │   ├── bloc/               # Eventos, Estados, BLoCs (Cubit para casos simples)
   │   ├── pages/              # Constructores de rutas, adaptadores de layout
   │   └── widgets/            # Componentes atómicos, moleculares y organizacionales
   ├── cloud_functions/        # TypeScript/Node18 (stock, pago, estado)
   ├── firebase/               # firestore.rules, firebase.json, .firebaserc
   └── main.dart               # Arranque de app, inicialización Firebase, configuración DI
   ```

2. **🎨 `ThemeData` (Material 3 + Tokens Domino's + Claro/Oscuro)**
   - Implementación completa con `ColorScheme.fromSeed`, escalas de tipografía, elevaciones, estados de botón y `ShapeBorder` estandarizado (`RoundedRectangleBorder`, `StadiumBorder`).

3. **📦 Modelos Base (`Producto` y `Pedido`)**
   - Clases `@freezed` con `json_serializable`, validación de dominio en fábricas, manejo de `Decimal` para precios, máquina de estados tipada (`OrderStatus` enum con transiciones válidas), campo `personalizacion` tipado como `Map<String, dynamic>` con validación de esquema.
   - Métodos `fromFirestore`, `toMap`, `copyWith` seguros. Documentación `///` estilo Javadoc.

4. **🔐 Reglas de Seguridad de Firestore (Fragmento Validado)**
   - Reglas de acceso por rol, validación de estados permitidos, restricción de escritura directa a inventario, validación de monto de pago vs total del pedido.

5. **⚡ Cloud Function (TypeScript/Node 18) para `placeOrder`**
   - Función HTTPS o `onCall` que ejecuta `runTransaction`, valida inventario atómico, aplica descuentos, genera referencia de pago, emite evento a Pub/Sub para notificaciones.

6. **✅ Criterios de Aceptación Estrictos**
   - Cero importaciones de `firebase_*` en `domain/`.
   - Uso explícito de `Result<T, Failure>` en repositorios.
   - `decimal` obligatorio para moneda. `double` prohibido en cálculos financieros.
   - Código limpio con `flutter analyze --fatal-infos`, `const` donde aplique, `@visibleForTesting` para mocks.
   - Compatibilidad con `firebase emulators` sin cambios en el código.
   - Funcionamiento offline-first: la UI responde inmediatamente, sincronización en segundo plano, reconciliación automática.

---
🔹 **INSTRUCCIÓN FINAL PARA EL AGENTE/IA:**  
Genera el código completo solicitado en el punto 6, manteniendo sintaxis **Dart 3.5+** impecable, patrones inmutables, separación estricta de capas y adherencia absoluta a las directrices arquitectónicas, de nube, multiplataforma y de negocio descritas. No omitas validaciones, no uses `dynamic` donde exista tipado seguro, y prioriza la mantenibilidad, observabilidad y resiliencia sobre la brevedad. El resultado debe ser compatible con `flutter analyze`, funcional con `firebase emulators`, listo para despliegue en **Android, iOS, Web y Windows**, y documentado para integración inmediata en un pipeline CI/CD empresarial.
