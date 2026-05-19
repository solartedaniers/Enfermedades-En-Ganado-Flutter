# 🐄 AgroVet AI

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-Estado_Global-00B4D8?style=for-the-badge)
![Hive](https://img.shields.io/badge/Hive-Local_DB-FFC300?style=for-the-badge)

**Aplicación móvil para ganaderos y veterinarios que centraliza el registro de animales, historial clínico, recordatorios y diagnóstico asistido por inteligencia artificial.**

*Proyecto académico — Electiva III · Universidad Cooperativa de Colombia, Campus Pasto*

</div>

---

## 📋 Tabla de contenido

- [Descripción](#-descripción)
- [Características principales](#-características-principales)
- [Requisitos previos](#-requisitos-previos)
- [Configuración del entorno](#️-configuración-del-entorno)
- [Instalación y ejecución](#-instalación-y-ejecución)
- [Configuración de Supabase](#-configuración-de-supabase)
- [Stack tecnológico](#️-stack-tecnológico)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Widgets principales](#-widgets-principales)
- [Tablas en Supabase](#️-tablas-en-supabase)
- [Inteligencia artificial](#-inteligencia-artificial)
- [Geolocalización](#-geolocalización)
- [Sincronización offline](#-sincronización-offline)
- [Internacionalización](#-internacionalización)
- [Notificaciones](#-notificaciones)
- [Roles de usuario](#-roles-de-usuario)
- [Retos y soluciones](#-retos-y-soluciones)
- [Información académica](#-información-académica)

---

## 📖 Descripción

AgroVet AI es una aplicación móvil desarrollada en Flutter orientada al sector ganadero. Permite a ganaderos y veterinarios gestionar la información sanitaria del ganado de forma centralizada, con soporte para trabajo sin conexión y diagnóstico preliminar asistido por inteligencia artificial.

El sistema integra modelos de lenguaje y visión (Gemini y Groq) para generar reportes clínicos estructurados a partir de síntomas, imágenes y contexto geográfico del animal.

---

## ✨ Características principales

- 📝 Registro de animales con foto, raza, edad y peso
- 🩺 Historial clínico por animal con imágenes
- 🤖 Diagnóstico asistido por IA (Gemini + Groq)
- 🔔 Recordatorios de medicamentos con notificaciones locales
- 🌍 Geolocalización para contexto epidemiológico regional
- 📶 Modo offline con sincronización automática al recuperar conexión
- 👥 Roles diferenciados: Ganadero, Veterinario, Administrador
- 🌐 Soporte multiidioma (Español / Inglés)
- 🌙 Tema claro y oscuro

---

## 📋 Requisitos previos

Antes de clonar y ejecutar el proyecto asegúrate de tener instalado lo siguiente:

| Herramienta | Versión mínima | Descarga |
|---|---|---|
| Flutter SDK | 3.10.0 o superior | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| Dart SDK | 3.0.0 o superior | Incluido con Flutter |
| Android Studio | Cualquier versión reciente | [developer.android.com](https://developer.android.com/studio) |
| Git | Cualquier versión | [git-scm.com](https://git-scm.com/) |
| Cuenta Supabase | Gratuita | [supabase.com](https://supabase.com/) |

> **Verifica tu instalación de Flutter ejecutando:**
> ```bash
> flutter doctor
> ```
> Todos los ítems deben aparecer en verde antes de continuar.

---

## ⚙️ Configuración del entorno

### 1. Variables de entorno

Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui
```

> ⚠️ **Este archivo no debe subirse a Git.** Está incluido en `.gitignore`. Lo encuentras en el dashboard de tu proyecto Supabase en **Settings → API**.

### 2. Permisos en Android

El archivo `android/app/src/main/AndroidManifest.xml` ya incluye los permisos necesarios para:

- Cámara
- Galería
- Geolocalización
- Notificaciones
- Internet

No necesitas agregarlos manualmente.

---

## 🚀 Instalación y ejecución

```bash
# 1. Clona el repositorio
git clone https://github.com/solartedaniers/Enfermedades-En-Ganado-Flutter.git

# 2. Entra a la carpeta del proyecto
cd agrovet_ai

# 3. Crea el archivo .env con tus credenciales de Supabase
# (ver sección Configuración del entorno)

# 4. Instala las dependencias
flutter pub get

# 5. Conecta un dispositivo Android o inicia un emulador

# 6. Corre la aplicación
flutter run
```

> **Nota:** La primera vez que corres la app puede tardar unos minutos en compilar. Las siguientes ejecuciones son más rápidas.

---

## 🗄️ Configuración de Supabase

El proyecto requiere las siguientes tablas en Supabase. Ejecuta los scripts SQL en el **SQL Editor** de tu proyecto Supabase:

### Tablas principales

```sql
-- Perfiles de usuario
create table profiles (
  id uuid references auth.users on delete cascade,
  first_name text,
  last_name text,
  full_name text,
  email text,
  phone text,
  location text,
  user_type text default 'farmer',
  account_status text default 'active',
  admin_status_message text,
  avatar_url text,
  preferred_language text default 'es',
  primary key (id)
);

-- Animales
create table animals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  name text,
  breed text,
  age integer,
  symptoms text,
  weight double precision,
  temperature double precision,
  image_url text,
  profile_image_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Historial clínico
create table medical_records (
  id uuid primary key default gen_random_uuid(),
  animal_id uuid references animals(id) on delete cascade,
  user_id uuid references profiles(id),
  title text,
  notes text,
  image_url text,
  created_at timestamptz default now()
);

-- Notificaciones / recordatorios
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  animal_id uuid references animals(id),
  title text,
  message text,
  scheduled_at timestamptz,
  repeat_weekdays integer[],
  local_notification_ids integer[],
  completed_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz default now()
);

-- Clientes gestionados por veterinario
create table managed_clients (
  id uuid primary key default gen_random_uuid(),
  veterinarian_id uuid references profiles(id),
  client_id uuid references profiles(id),
  created_at timestamptz default now()
);

-- Relación cliente - animal
create table managed_client_animals (
  id uuid primary key default gen_random_uuid(),
  veterinarian_id uuid references profiles(id),
  client_id uuid references profiles(id),
  animal_id uuid references animals(id),
  created_at timestamptz default now()
);
```

### Row Level Security (RLS)

Activa RLS en todas las tablas desde **Authentication → Policies** en Supabase. Cada usuario solo puede leer y modificar sus propios datos.

### Storage

Crea un bucket llamado `animals` en **Storage** con acceso público para las imágenes de animales y avatares.

---

## 🛠️ Stack tecnológico

| Categoría | Tecnología |
|---|---|
| Framework | Flutter 3.x (Dart) |
| Backend / Auth / DB | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| Base de datos local | Hive (offline-first) |
| Preferencias locales | SharedPreferences |
| Estado global | Riverpod |
| IA — Diagnóstico remoto | Google Gemini (vía Supabase Edge Function) |
| IA — Diagnóstico alternativo | Groq API (texto + visión) |
| Notificaciones locales | flutter_local_notifications |
| Geolocalización | geolocator + geocoding |
| Imágenes | image_picker + camera |
| Animaciones | flutter_animate |
| Deep Linking | app_links |
| Conectividad | connectivity_plus |
| IDs únicos | uuid |
| Logging | logger |
| Variables de entorno | flutter_dotenv |

---

## 📁 Estructura del proyecto

```
lib/
├── core/
│   ├── ai/                  # Modelos, providers y servicios de IA
│   ├── constants/           # Constantes globales (rutas, keys, assets)
│   ├── network/             # Info y provider de red
│   ├── services/            # Servicios core (sync, auth offline, storage, notificaciones)
│   ├── theme/               # Colores, tamaños, estilos, tema de la app
│   ├── utils/               # Utilidades (strings, fechas, JSON)
│   └── widgets/             # Widgets compartidos globalmente
├── features/
│   ├── admin/               # Panel de administración de usuarios
│   ├── animals/             # Registro y gestión de animales
│   ├── auth/                # Autenticación, login, registro, OTP
│   ├── diagnosis/           # Flujo de diagnóstico por IA
│   ├── medical/             # Historial clínico
│   ├── notifications/       # Recordatorios y notificaciones
│   └── profile/             # Perfil de usuario y configuración
├── geolocation/             # Geolocalización y perfiles regionales de enfermedades
├── l10n/
│   ├── es.json              # Textos en español
│   └── en.json              # Textos en inglés
└── main.dart
```

Cada feature sigue arquitectura en capas:

```
feature/
├── data/
│   ├── datasources/         # Fuentes de datos (local y remota)
│   ├── models/              # Modelos de datos (Hive, JSON)
│   ├── repositories/        # Implementaciones de repositorios
│   └── services/            # Servicios específicos del feature
├── domain/
│   ├── constants/           # Constantes del dominio
│   ├── entities/            # Entidades de negocio
│   ├── repositories/        # Contratos (interfaces)
│   └── usecases/            # Casos de uso
└── presentation/
    ├── pages/               # Pantallas
    ├── providers/           # Providers de Riverpod
    └── widgets/             # Widgets del feature
```

---

## 🧩 Widgets principales

| Widget | Dónde se usa |
|---|---|
| `ConsumerStatefulWidget` / `ConsumerWidget` | Todas las páginas que leen o modifican estado global con Riverpod |
| `FutureProvider` / `FutureBuilder` | Carga asíncrona de animales, historial médico y catálogos |
| `ListView.builder` | Listas de animales, historial clínico y notificaciones |
| `GridView.count` | Panel principal (accesos rápidos a módulos) |
| `TextFormField` | Formularios de registro, login, edición de animales y notificaciones |
| `showModalBottomSheet` | Formularios secundarios sin salir de la pantalla actual |
| `AlertDialog` | Confirmaciones de eliminación, logout y acciones críticas |
| `FloatingActionButton.extended` | Acciones principales (agregar animal, registro médico) |
| `Stack` + `Positioned` | Botón de cámara superpuesto sobre foto de animal o avatar |
| `ClipRRect` | Imágenes con bordes redondeados |
| `AnimatedContainer` | Transiciones suaves en cards del menú |
| `RefreshIndicator` | Actualización de listas al deslizar hacia abajo |
| `PageView` | Navegación entre imágenes en el historial clínico |
| `InteractiveViewer` | Zoom sobre imágenes de diagnóstico e historial |
| `DraggableScrollableSheet` | Selectores de raza y edad con scroll ajustable |

---

## 🗃️ Tablas en Supabase

| Tabla | Descripción |
|---|---|
| `profiles` | Datos del usuario: nombre, avatar, idioma, tema, rol y estado de cuenta |
| `animals` | Animales registrados con imagen, raza, edad, peso y síntomas |
| `medical_records` | Historial clínico con imagen para diagnóstico IA |
| `notifications` | Recordatorios programados con días de repetición |
| `animal_diagnostics` | Diagnósticos generados y reportes asociados |
| `managed_clients` | Relación veterinario → cliente gestionado |
| `managed_client_animals` | Relación cliente → animal bajo gestión veterinaria |
| `animal_reference_options` | Catálogo de razas y edades disponibles para selección |

> Todas las tablas tienen **Row Level Security (RLS)** activado. Cada usuario accede únicamente a sus propios datos.

---

## 🤖 Inteligencia artificial

El diagnóstico por IA es la funcionalidad central de la aplicación. No reemplaza al veterinario — ofrece una orientación preliminar estructurada.

### Pipeline de diagnóstico

```
Síntomas + Imagen + Datos del animal + Contexto geográfico
         ↓
  Procesamiento local de evidencia
  (análisis de palabras clave y contexto epidemiológico regional)
         ↓
  Preprocesamiento de imagen
  (reducción de tamaño, ajuste de contraste y brillo)
         ↓
  ┌──────────────────────────────────┐
  │  Gemini (Supabase Edge Function) │  ← Proveedor principal
  └──────────────────────────────────┘
         ↓ (si falla)
  ┌──────────────────────────────────┐
  │         Groq API                 │  ← Proveedor alternativo
  └──────────────────────────────────┘
         ↓
  Reporte estructurado:
  diagnóstico principal · severidad · urgencia ·
  protocolo de tratamiento · medidas de aislamiento · monitoreo
```

### Proveedores de IA

**Google Gemini** — vía Supabase Edge Function (`animal-diagnosis`). Recibe nombre, especie, raza, edad, peso, temperatura, síntomas, imagen en base64, hallazgos visuales y contexto geográfico.

**Groq API** — proveedor alternativo con modelos de texto y visión. Se activa cuando la función remota no responde.

**Procesamiento local** — capa que analiza síntomas, hallazgos visuales y zona geográfica para enriquecer el contexto antes de enviarlo al modelo remoto.

---

## 🌍 Geolocalización

La app obtiene la ubicación del usuario mediante GPS y usa geocoding para convertir coordenadas en país, departamento y ciudad.

Se usa para:
- Registrar la ubicación durante el diagnóstico.
- Identificar la zona climática del usuario.
- Cargar el perfil regional de enfermedades desde `lib/geolocation/config/region_disease_profiles.json`.
- Enriquecer el contexto epidemiológico enviado al modelo de IA.

---

## 📶 Sincronización offline

La app implementa una estrategia **offline-first** con Hive:

1. Toda acción se guarda primero en Hive localmente.
2. Se marca como pendiente de sincronización (`isSynced: false`).
3. Cuando vuelve la conexión, `AnimalSyncService` detecta el evento y sincroniza con Supabase.
4. Se usa `upsert` para evitar duplicados al reintentar.
5. Las eliminaciones se marcan como `isDeleted: true` localmente y se eliminan en remoto al sincronizar.

---

## 🌐 Internacionalización

Los textos de la interfaz están en archivos JSON:

```
lib/l10n/
├── es.json   ← Español
└── en.json   ← Inglés
```

El idioma se guarda en Supabase y en `SharedPreferences`. Se aplica en toda la app incluyendo pantallas de autenticación. Se puede cambiar desde el perfil del usuario.

---

## 🔔 Notificaciones

Los recordatorios se programan usando `zonedSchedule` de `flutter_local_notifications`, con soporte para:

- Hora y fecha exacta.
- Repetición por días de la semana.
- Notificación anticipada (minutos antes del evento).
- Opción de posponer 5 minutos desde la notificación.

También se persisten en Supabase para mantener coherencia entre sesiones y dispositivos.

---

## 👥 Roles de usuario

| Rol | Acceso |
|---|---|
| **Ganadero** | Registra sus propios animales, historial y recordatorios. Usa el diagnóstico IA. |
| **Veterinario** | Gestiona clientes, visualiza y trabaja con los animales de sus clientes. |
| **Administrador** | Consulta todos los usuarios, cambia roles, desactiva o elimina cuentas. |

---

## 🧗 Retos y soluciones

| # | Reto | Solución aplicada |
|---|---|---|
| 1 | **Sincronización offline sin conflictos** — Al volver la conexión, los datos locales y remotos podían entrar en conflicto si el mismo animal fue modificado en ambos lados. | Se implementó una estrategia offline-first con Hive donde los cambios locales tienen prioridad. Se usa `upsert` con `onConflict: 'id'` en Supabase para resolver duplicados. Los animales pendientes conservan su estado hasta confirmar sincronización exitosa. |
| 2 | **Imágenes que no persisten entre sesiones** — Las fotos subidas al Storage de Supabase no siempre estaban disponibles rápido, y la imagen local se perdía al reiniciar. | Se combinaron dos rutas: `localProfileImagePath` (ruta local en Hive) y `profileImageUrl` (URL remota). El widget `AnimalProfileImage` prioriza la imagen local y descarga la remota con caché en disco para sesiones futuras. |
| 3 | **Contexto de IA insuficiente sin geolocalización** — El modelo de IA generaba diagnósticos genéricos sin considerar enfermedades comunes de la región del usuario. | Se integró un archivo local `region_disease_profiles.json` con perfiles epidemiológicos por zona climática. La geolocalización identifica la zona del usuario y enriquece el prompt enviado al modelo con enfermedades prevalentes de esa región. |
| 4 | **Caída del proveedor principal de IA** — Cuando la Edge Function de Gemini fallaba, el usuario quedaba sin diagnóstico. | Se implementó un pipeline con fallback automático: si Gemini falla, el sistema redirige la solicitud a Groq API de forma transparente para el usuario. |
| 5 | **Manejo de roles sin recargar la app** — Al cambiar el rol de un usuario desde el panel admin, la sesión activa del usuario no reflejaba el cambio. | Se usa `ProfileProvider` con Riverpod que escucha cambios en la sesión. Al detectar un cambio de estado de cuenta o rol, recarga el perfil y actualiza la UI reactivamente sin necesidad de cerrar sesión. |
| 6 | **Adaptador Hive acoplado al modelo** — El `AnimalModelAdapter` y `AnimalModel` estaban en el mismo archivo, violando el principio de responsabilidad única y dificultando el mantenimiento. | Se separaron en dos archivos: `animal_model.dart` (solo el modelo con sus campos y mapeos) y `animal_model_adapter.dart` (solo la lógica de serialización binaria de Hive). |
| 7 | **Código duplicado entre formularios de animal** — `AddAnimalPage` y `AnimalDetailPage` tenían exactamente la misma lógica de selección de imagen, parseo de peso y manejo de `TextEditingController`. | Se extrajo un `AnimalFormController` que encapsula ese estado compartido. Ambas páginas lo instancian y delegan, eliminando la duplicación y centralizando posibles correcciones futuras. |

---

## 📚 Información académica

| Campo | Detalle |
|---|---|
| **Universidad** | Universidad Cooperativa de Colombia, Campus Pasto |
| **Programa** | Ingeniería de Software |
| **Semestre** | Sexto semestre |
| **Materia** | Electiva III |
| **Profesor** | JHONATAN MIDEROS NARVAEZ |
| **Integrantes** | Juan Felipe Mora Revelo · Daniers Alexander Solarte Limas |

---

<div align="center">

Hecho por el equipo Daniers Solarte y Juan Mora -  AgroVet AI · 2026

</div>