# agrovet_ai

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.







🐄 AgroVet AI
Aplicación móvil para ganaderos y veterinarios que permite registrar animales, llevar historial clínico, programar recordatorios de medicamentos y preparar la integración con diagnóstico por inteligencia artificial.

🛠️ Stack tecnológico
CategoríaTecnologíaFrameworkFlutter 3.x (Dart)Backend / DBSupabase (PostgreSQL + Auth + Storage)Base de datos localHive (offline-first)Estado globalRiverpod (StateNotifierProvider, Provider)Notificacionesflutter_local_notificationsImágenesimage_pickerAnimacionesflutter_animateDeep Linkingapp_linksConectividadconnectivity_plusIDs únicosuuidLogginglogger

🧩 Widgets principales utilizados
WidgetDónde se usaConsumerStatefulWidget / ConsumerWidgetTodas las páginas que leen estado de RiverpodStateNotifierProviderProfileProvider (tema, idioma, avatar)FutureBuilderListas de animales, historial médicoGridView.countPanel principal (home)ListView.builderLista de animales, historial, notificacionesshowModalBottomSheetFormularios de nuevo registro médico, notificacionesAnimatedContainerCards del menú principal con transición suaveStack + PositionedAvatar con botón de cámara superpuestoClipRRectImágenes con bordes redondeadosLinearGradientHeaders del home, historial y perfilDropdownButtonFormFieldSelector de tipo de usuario y animalTextFormFieldFormularios de registro y loginCircleAvatarAvatar de usuario y foto de perfil del animalCardRegistros médicos y notificacionesFloatingActionButton.extendedAcciones principales (agregar registro, notificación)showDatePicker / showTimePickerProgramación de notificacionesAlertDialogConfirmaciones de eliminación y logout

🗄️ Tablas en Supabase
TablaDescripciónprofilesDatos del usuario: nombre, avatar, idioma, temaanimalsAnimales registrados con imagen IA y foto de perfilmedical_recordsHistorial clínico con imagen para diagnóstico IAnotificationsRecordatorios de medicamentos programados
Todas las tablas tienen Row Level Security (RLS) activado — cada usuario solo ve sus propios datos.

📦 Almacenamiento

Supabase Storage (bucket animals): imágenes de perfil del animal, fotos para IA y avatar del usuario, organizadas por user_id/uuid.jpg
Hive (local): cache offline de animales, se sincroniza automáticamente con Supabase al recuperar conexión


🌍 Internacionalización
Textos en lib/l10n/es.json y lib/l10n/en.json. El cambio de idioma se guarda en Supabase y se aplica en toda la app incluyendo pantallas de autenticación.

🔔 Notificaciones
Se programan 20 minutos antes del horario indicado usando zonedSchedule de flutter_local_notifications. Se guardan también en Supabase para persistencia entre sesiones.


