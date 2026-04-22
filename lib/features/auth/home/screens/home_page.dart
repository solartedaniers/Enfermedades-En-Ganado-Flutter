import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/managed_client_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../geolocation/presentation/providers/geolocation_provider.dart';
import '../../../animals/domain/constants/animal_constants.dart';
import '../../../animals/domain/entities/animal_entity.dart';
import '../../../animals/presentation/pages/add_animal_page.dart';
import '../../../animals/presentation/pages/animals_page.dart';
import '../../../animals/presentation/providers/animal_reference_catalog_provider.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
import '../../../diagnosis/screens/scanner_screen.dart';
import '../../../medical/domain/entities/medical_record_entity.dart';
import '../../../medical/presentation/providers/medical_provider.dart';
import '../../../notifications/data/datasources/notification_remote_datasource.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../admin/presentation/pages/admin_users_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/presentation/providers/managed_client_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../screens/login_page.dart';
import '../models/home_dashboard_summary.dart';
import '../widgets/home_dashboard_section.dart';
import '../widgets/veterinarian_client_panel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final NotificationRemoteDataSource _notificationDataSource =
      NotificationRemoteDataSource();

  bool _hasPromptedInitialManagedClient = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        await ref
            .read(currentGeolocationContextProvider.notifier)
            .loadCurrentContext();
        // Precarga el catalogo para dejar copia local disponible tras el primer acceso con internet.
        await ref.read(animalBreedChoicesProvider.future);
        await ref.read(animalAgeOptionsProvider.future);
      },
    );
  }

  @override
  void dispose() => super.dispose();

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.t('logout')),
        content: Text(AppStrings.t('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.danger,
            ),
            child: Text(AppStrings.t('exit')),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    await supabase.auth.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _handleAppBarAction(_HomeAppBarAction action) async {
    switch (action) {
      case _HomeAppBarAction.profile:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
      case _HomeAppBarAction.adminUsers:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminUsersPage()),
        );
        break;
      case _HomeAppBarAction.logout:
        await logout();
        break;
    }
  }

  Future<void> _openManagedClientDialog({bool isInitialSetup = false}) async {
    final geolocationContext =
        ref.read(currentGeolocationContextProvider).valueOrNull;
    final defaultLocation = geolocationContext?.regionLabel ?? '';
    final messenger = ScaffoldMessenger.of(context);
    var clientName = '';

    final newClientDraft = await showDialog<_ManagedClientDraft>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            AppStrings.t(
              isInitialSetup
                  ? 'veterinarian_first_client_dialog_title'
                  : 'veterinarian_add_client',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isInitialSetup) ...[
                Text(AppStrings.t('veterinarian_first_client_dialog_message')),
                const SizedBox(height: 16),
              ],
              TextField(
                autofocus: true,
                onChanged: (value) => clientName = value.trim(),
                onSubmitted: (value) {
                  final normalizedName = value.trim();
                  if (normalizedName.isEmpty) {
                    return;
                  }

                  FocusScope.of(dialogContext).unfocus();
                  Navigator.pop(
                    dialogContext,
                    _ManagedClientDraft(
                      name: normalizedName,
                      location: defaultLocation,
                    ),
                  );
                },
                decoration: InputDecoration(
                  labelText: AppStrings.t('veterinarian_client_name'),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  defaultLocation.isEmpty
                      ? AppStrings.t('registration_location_missing')
                      : '${AppStrings.t('veterinarian_client_location')}: $defaultLocation',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppStrings.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (clientName.isEmpty) {
                  return;
                }

                FocusScope.of(dialogContext).unfocus();
                Navigator.pop(
                  dialogContext,
                  _ManagedClientDraft(
                    name: clientName,
                    location: defaultLocation,
                  ),
                );
              },
              child: Text(AppStrings.t('veterinarian_save_client')),
            ),
          ],
        );
      },
    );

    if (newClientDraft == null || !mounted) {
      return;
    }

    try {
      await ref.read(managedClientProvider.notifier).createClient(
            name: newClientDraft.name,
            location: newClientDraft.location,
          );

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('veterinarian_client_saved')),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('${AppStrings.t('unexpected_error')}: $error'),
        ),
      );
    }
  }

  Future<void> _openEditManagedClientDialog(
    ManagedClientProfile client,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final updatedClient = await _showManagedClientEditorSheet(
      title: AppStrings.t('veterinarian_edit_client'),
      actionLabel: AppStrings.t('save_changes'),
      initialName: client.name,
      initialLocation: client.location,
    );

    if (updatedClient == null || !mounted) {
      return;
    }

    try {
      await ref.read(managedClientProvider.notifier).updateClient(
            clientId: client.id,
            name: updatedClient.name,
            location: updatedClient.location,
          );

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.t('veterinarian_client_updated'))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('${AppStrings.t('unexpected_error')}: $error'),
        ),
      );
    }
  }

  Future<_ManagedClientDraft?> _showManagedClientEditorSheet({
    required String title,
    required String actionLabel,
    required String initialName,
    required String initialLocation,
  }) async {
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;
    var draftName = initialName;
    var draftLocation = initialLocation;

    return showModalBottomSheet<_ManagedClientDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            final canSubmit = draftName.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark ? appColors.cardDark : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: appColors.darkShadow.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: appColors.mutedForeground.withValues(
                                alpha: 0.28,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.t('veterinarian_clients_subtitle'),
                          style: TextStyle(color: appColors.mutedForeground),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: initialName,
                          autofocus: true,
                          onChanged: (value) {
                            setSheetState(() => draftName = value);
                          },
                          decoration: InputDecoration(
                            labelText: AppStrings.t('veterinarian_client_name'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: initialLocation,
                          onChanged: (value) {
                            setSheetState(() => draftLocation = value);
                          },
                          decoration: InputDecoration(
                            labelText: AppStrings.t(
                              'veterinarian_client_location',
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                child: Text(AppStrings.t('cancel')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: canSubmit
                                    ? () {
                                        FocusScope.of(sheetContext).unfocus();
                                        Navigator.pop(
                                          sheetContext,
                                          _ManagedClientDraft(
                                            name: draftName.trim(),
                                            location: draftLocation.trim(),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(actionLabel),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteManagedClient(ManagedClientProfile client) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;
    final confirmDelete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? appColors.cardDark : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: appColors.darkShadow.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: appColors.mutedForeground.withValues(
                            alpha: 0.28,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: appColors.danger,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            AppStrings.t('veterinarian_delete_client'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      client.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (client.location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.t('veterinarian_client_location')}: ${client.location}',
                        style: TextStyle(color: appColors.mutedForeground),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      AppStrings.t('veterinarian_delete_client_confirm'),
                      style: TextStyle(color: appColors.mutedForeground),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext, false),
                            child: Text(AppStrings.t('cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: appColors.danger,
                            ),
                            child: Text(AppStrings.t('delete')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmDelete != true || !mounted) {
      return;
    }

    try {
      await ref.read(managedClientProvider.notifier).deleteClient(client.id);

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.t('veterinarian_client_deleted'))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('${AppStrings.t('unexpected_error')}: $error'),
        ),
      );
    }
  }

  void _promptInitialManagedClientIfNeeded(ManagedClientState managedClientState) {
    if (_hasPromptedInitialManagedClient ||
        !ref.read(profileProvider).isVeterinarian ||
        managedClientState.clients.isNotEmpty) {
      return;
    }

    _hasPromptedInitialManagedClient = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _openManagedClientDialog(isInitialSetup: true);
    });
  }

  void _onMenuTap(String key) {
    final profile = ref.read(profileProvider);
    final managedClientState = ref.read(managedClientProvider).valueOrNull;
    final requiresActiveClient = {
      'register_animal',
      'history',
      'notifications',
      'diagnosis',
    };

    if (profile.isVeterinarian &&
        requiresActiveClient.contains(key) &&
        (managedClientState == null || !managedClientState.hasActiveClient)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('veterinarian_workspace_hint')),
        ),
      );
      return;
    }

    switch (key) {
      case 'register_animal':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAnimalPage()),
        );
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnimalsPage()),
        );
        break;
      case 'notifications':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
        break;
      case 'diagnosis':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScannerScreen()),
        );
        break;
      case 'admin_panel':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminUsersPage()),
        );
        break;
      case 'vaccines':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('coming_soon_vaccines'))),
        );
        break;
    }
  }

  Future<HomeDashboardSummary> _loadDashboardSummary() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final profile = ref.read(profileProvider);
    final managedClientState = ref.read(managedClientProvider).valueOrNull;
    final medicalRepository = ref.read(medicalRepositoryProvider);
    final geolocationContext =
        ref.read(currentGeolocationContextProvider).valueOrNull;

    final allAnimals = profile.isVeterinarian
        ? await ref.read(rawAnimalsListProvider.future)
        : await ref.read(animalsListProvider.future);

    if (allAnimals.isEmpty) {
      return HomeDashboardSummary.empty();
    }

    final animalIds = allAnimals.map((animal) => animal.id).toSet();
    final notifications = await _notificationDataSource.getNotifications();
    final monthlyNotifications = notifications.where((notification) {
      return animalIds.contains(notification.animalId) &&
          !notification.createdAt.isBefore(monthStart);
    }).toList();

    final monthlyRecords = <MedicalRecordEntity>[];
    for (final animal in allAnimals) {
      final records = await medicalRepository.getRecords(animal.id);
      monthlyRecords.addAll(
        records.where((record) => !record.createdAt.isBefore(monthStart)),
      );
    }

    final weekdayCounter = <String, int>{};
    for (final animal in allAnimals.where((animal) => !animal.createdAt.isBefore(monthStart))) {
      _increaseCounter(weekdayCounter, _weekdayLabel(animal.createdAt.weekday));
    }
    for (final notification in monthlyNotifications) {
      _increaseCounter(
        weekdayCounter,
        _weekdayLabel(notification.createdAt.weekday),
      );
    }
    for (final record in monthlyRecords) {
      _increaseCounter(weekdayCounter, _weekdayLabel(record.createdAt.weekday));
    }

    final diseaseCounter = <String, int>{};
    for (final record in monthlyRecords) {
      final diseaseLabel = _normalizeDiseaseLabel(
        record.diagnosis ?? record.aiResult,
      );
      _increaseCounter(
        diseaseCounter,
        diseaseLabel.isEmpty
            ? AppStrings.t('dashboard_unknown_disease')
            : diseaseLabel,
      );
    }

    final locationCounter = <String, int>{};
    if (profile.isVeterinarian && managedClientState != null) {
      for (final record in monthlyRecords) {
        AnimalEntity? animal;
        for (final item in allAnimals) {
          if (item.id == record.animalId) {
            animal = item;
            break;
          }
        }
        if (animal == null) {
          continue;
        }

        final clientId = managedClientState.animalAssignments[animal.id];
        ManagedClientProfile? client;
        for (final item in managedClientState.clients) {
          if (item.id == clientId) {
            client = item;
            break;
          }
        }
        final locationLabel = client?.location.trim().isNotEmpty == true
            ? client!.location
            : AppStrings.t('dashboard_unknown_location');
        _increaseCounter(locationCounter, locationLabel);
      }
    } else {
      final regionLabel = geolocationContext?.regionLabel.isNotEmpty == true
          ? geolocationContext!.regionLabel
          : AppStrings.t('dashboard_current_region_fallback');
      if (monthlyRecords.isNotEmpty) {
        locationCounter[regionLabel] = monthlyRecords.length;
      }
    }

    return HomeDashboardSummary(
      busiestWeekdays: _topItems(weekdayCounter),
      topLocations: _topItems(locationCounter),
      topDiseases: _topItems(diseaseCounter),
    );
  }

  void _increaseCounter(Map<String, int> counter, String key) {
    counter.update(key, (value) => value + 1, ifAbsent: () => 1);
  }

  List<DashboardMetricItem> _topItems(Map<String, int> counter, {int limit = 4}) {
    final entries = counter.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    return entries.take(limit).map((entry) {
      return DashboardMetricItem(label: entry.key, value: entry.value);
    }).toList();
  }

  String _normalizeDiseaseLabel(String? rawValue) {
    if (rawValue == null) {
      return '';
    }

    final normalized = rawValue
        .replaceAll('\n', ' ')
        .replaceAll(':', '.')
        .trim();

    if (normalized.isEmpty) {
      return '';
    }

    final firstSentence = normalized
        .split('.')
        .map((item) => item.trim())
        .firstWhere((item) => item.isNotEmpty, orElse: () => normalized);

    return _titleCase(firstSentence);
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .where((item) => item.isNotEmpty)
        .map((item) {
          final lower = item.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return AppStrings.t('weekday_mon');
      case DateTime.tuesday:
        return AppStrings.t('weekday_tue');
      case DateTime.wednesday:
        return AppStrings.t('weekday_wed');
      case DateTime.thursday:
        return AppStrings.t('weekday_thu');
      case DateTime.friday:
        return AppStrings.t('weekday_fri');
      case DateTime.saturday:
        return AppStrings.t('weekday_sat');
      default:
        return AppStrings.t('weekday_sun');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final managedClientAsync = ref.watch(managedClientProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;
    final roleLabel = profile.isVeterinarian
        ? AppStrings.t('role_veterinarian')
        : profile.isAdmin
            ? AppStrings.t('role_admin')
            : AppStrings.t('role_farmer');

    final menuItems = [
      if (profile.isAdmin)
        _HomeMenuItem(
          keyName: 'admin_panel',
          icon: Icons.admin_panel_settings_outlined,
          foregroundColor: colorScheme.primary,
          backgroundColor: Color.lerp(
            colorScheme.primaryContainer,
            colorScheme.primary,
            0.18,
          )!,
          cardColor: Color.lerp(
            colorScheme.surface,
            colorScheme.primaryContainer,
            0.76,
          )!,
        ),
      _HomeMenuItem(
        keyName: 'register_animal',
        imagePath: 'lib/images/Taureau.webp',
        foregroundColor: appColors.success,
        backgroundColor:
            Color.lerp(appColors.selectionBackground, appColors.success, 0.18)!,
        cardColor:
            Color.lerp(colorScheme.surface, appColors.selectionBackground, 0.82)!,
      ),
      _HomeMenuItem(
        keyName: 'diagnosis',
        icon: Icons.health_and_safety,
        foregroundColor: colorScheme.secondary,
        backgroundColor:
            Color.lerp(colorScheme.secondaryContainer, colorScheme.secondary, 0.18)!,
        cardColor:
            Color.lerp(colorScheme.surface, colorScheme.secondaryContainer, 0.78)!,
      ),
      _HomeMenuItem(
        keyName: 'history',
        imagePath: AnimalConstants.livestockAssetPath,
        foregroundColor: colorScheme.tertiary,
        backgroundColor:
            Color.lerp(colorScheme.tertiaryContainer, colorScheme.tertiary, 0.2)!,
        cardColor:
            Color.lerp(colorScheme.surface, colorScheme.tertiaryContainer, 0.78)!,
      ),
      _HomeMenuItem(
        keyName: 'vaccines',
        icon: Icons.vaccines,
        foregroundColor: appColors.danger,
        backgroundColor:
            Color.lerp(colorScheme.errorContainer, appColors.danger, 0.14)!,
        cardColor:
            Color.lerp(colorScheme.surface, colorScheme.errorContainer, 0.76)!,
      ),
      _HomeMenuItem(
        keyName: 'notifications',
        icon: Icons.alarm,
        foregroundColor: appColors.warning,
        backgroundColor:
            Color.lerp(colorScheme.surfaceContainerHighest, appColors.warning, 0.22)!,
        cardColor: Color.lerp(
          colorScheme.surface,
          colorScheme.surfaceContainerHighest,
          0.64,
        )!,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('app_name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
          PopupMenuButton<_HomeAppBarAction>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
            color: isDark ? appColors.cardDark : colorScheme.surface,
            offset: const Offset(0, 56),
            onSelected: _handleAppBarAction,
            itemBuilder: (context) => [
              PopupMenuItem<_HomeAppBarAction>(
                value: _HomeAppBarAction.profile,
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: appColors.chipForeground,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.t('my_profile'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (profile.isAdmin)
                PopupMenuItem<_HomeAppBarAction>(
                  value: _HomeAppBarAction.adminUsers,
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        color: appColors.chipForeground,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.t('admin_panel'),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem<_HomeAppBarAction>(
                value: _HomeAppBarAction.logout,
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: appColors.danger,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.t('logout'),
                      style: TextStyle(
                        color: appColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? appColors.cardDark : colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                border: Border.all(
                  color: appColors.chipForeground.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: appColors.lightShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: appColors.chipForeground,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: appColors.darkShadow.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: appColors.whiteOverlay,
                            backgroundImage: profile.avatarUrl != null &&
                                    profile.avatarUrl!.isNotEmpty
                                ? NetworkImage(profile.avatarUrl!)
                                : null,
                            child: profile.avatarUrl == null ||
                                    profile.avatarUrl!.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 36,
                                    color: appColors.chipForeground,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark ? appColors.cardDark : colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: appColors.chipForeground.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 12,
                              color: appColors.chipForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t('hello'),
                          style: TextStyle(
                            color: appColors.mutedForeground,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          profile.name,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: appColors.chipForeground.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              color: appColors.chipForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),
            if (profile.isVeterinarian)
              managedClientAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (managedClientState) {
                  _promptInitialManagedClientIfNeeded(managedClientState);
                  return VeterinarianClientPanel(
                    clients: managedClientState.clients,
                    activeClientId: managedClientState.activeClientId,
                    onClientChanged: (clientId) {
                      if (clientId == null) {
                        return;
                      }
                      ref.read(managedClientProvider.notifier).setActiveClient(clientId);
                    },
                    onAddClient: _openManagedClientDialog,
                    onEditClient: _openEditManagedClientDialog,
                    onDeleteClient: _confirmDeleteManagedClient,
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                AppStrings.t('main_panel'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: menuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return _MenuCard(
                    item: item,
                    isDark: isDark,
                    onTap: () => _onMenuTap(item.keyName),
                  )
                      .animate()
                      .fadeIn(delay: (200 + index * 80).ms, duration: 400.ms)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1, 1),
                      );
                }).toList(),
              ),
            ),
            FutureBuilder<HomeDashboardSummary>(
              future: _loadDashboardSummary(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                return HomeDashboardSection(summary: snapshot.data!);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

enum _HomeAppBarAction {
  profile,
  adminUsers,
  logout,
}

class _ManagedClientDraft {
  final String name;
  final String location;

  const _ManagedClientDraft({
    required this.name,
    required this.location,
  });
}

class _HomeMenuItem {
  final String keyName;
  final IconData? icon;
  final String? imagePath;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color cardColor;

  const _HomeMenuItem({
    required this.keyName,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.cardColor,
    this.icon,
    this.imagePath,
  });
}

class _MenuCard extends StatelessWidget {
  final _HomeMenuItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final cardSurfaceColor = isDark ? appColors.cardDark : item.cardColor;
    final cardBorderColor = item.foregroundColor.withValues(
      alpha: isDark ? 0.18 : 0.14,
    );
    final cardShadowColor = item.foregroundColor.withValues(
      alpha: isDark ? 0.18 : 0.22,
    );
    final cardHighlightColor = isDark
        ? cardSurfaceColor
        : Color.lerp(item.cardColor, theme.colorScheme.surface, 0.42)!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark ? cardSurfaceColor : null,
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardHighlightColor,
                    cardSurfaceColor,
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor,
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? item.foregroundColor.withValues(alpha: 0.15)
                    : item.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: item.imagePath != null
                  ? ClipOval(
                      child: Image.asset(
                        item.imagePath!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(item.icon, size: 32, color: item.foregroundColor),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.t(item.keyName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? appColors.onSolid : appColors.subduedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
