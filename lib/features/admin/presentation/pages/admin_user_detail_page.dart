import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_account_status.dart';
import '../../../../core/constants/app_user_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/models/admin_managed_user.dart';
import '../providers/admin_user_management_provider.dart';

class AdminUserDetailPage extends ConsumerWidget {
  final String userId;

  const AdminUserDetailPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    if (!profile.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t('admin_user_details'))),
        body: Center(child: Text(AppStrings.t('admin_access_denied'))),
      );
    }

    final detailsAsync = ref.watch(adminUserDetailsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('admin_user_details')),
      ),
      body: detailsAsync.when(
        data: (details) => _AdminUserDetailView(details: details),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

class _AdminUserDetailView extends ConsumerWidget {
  final AdminManagedUserDetails details;

  const _AdminUserDetailView({required this.details});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = details.profile;
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final animalNamesById = {
      for (final animal in details.animals) animal.id: animal.name,
    };

    return RefreshIndicator(
      onRefresh: () async => refreshAdminUsers(ref),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: appColors.chipForeground.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage:
                          user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? const Icon(Icons.person_outline, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(color: appColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RolePill(label: AppStrings.t(user.userType.labelKey)),
                    _AccountStatusPill(status: user.accountStatus),
                  ],
                ),
                if (user.adminStatusMessage != null &&
                    user.adminStatusMessage!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: AppStrings.t('admin_status_message'),
                    child: Text(user.adminStatusMessage!),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      label: AppStrings.t('admin_animals_count'),
                      value: details.animalCount.toString(),
                    ),
                    _MetricCard(
                      label: AppStrings.t('admin_records_count'),
                      value: details.medicalRecordCount.toString(),
                    ),
                    _MetricCard(
                      label: AppStrings.t('admin_notifications_count'),
                      value: details.notificationCount.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ActionPanel(user: user),
          const SizedBox(height: 16),
          _SectionCard(
            title: AppStrings.t('admin_profile_information'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: AppStrings.t('username'),
                  value: user.username,
                ),
                _InfoRow(
                  label: AppStrings.t('first_name'),
                  value: user.firstName,
                ),
                _InfoRow(
                  label: AppStrings.t('last_name'),
                  value: user.lastName,
                ),
                _InfoRow(
                  label: AppStrings.t('phone'),
                  value: user.phone,
                ),
                _InfoRow(
                  label: AppStrings.t('location'),
                  value: user.location,
                ),
                _InfoRow(
                  label: AppStrings.t('admin_created_at'),
                  value: AppDateFormatter.shortDateTime(user.createdAt),
                ),
                _InfoRow(
                  label: AppStrings.t('admin_updated_at'),
                  value: AppDateFormatter.shortDateTime(user.updatedAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SnapshotSection<AdminAnimalSnapshot>(
            title: AppStrings.t('my_animals'),
            emptyLabel: AppStrings.t('admin_no_animals'),
            items: details.animals,
            itemBuilder: (animal) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                animal.name.isEmpty ? AppStrings.t('animal_no_name') : animal.name,
              ),
              subtitle: Text('${animal.breed} | ${animal.age}'),
              trailing: Text(AppDateFormatter.shortDate(animal.createdAt)),
            ),
          ),
          const SizedBox(height: 16),
          _SnapshotSection<AdminMedicalRecordSnapshot>(
            title: AppStrings.t('medical_history'),
            emptyLabel: AppStrings.t('admin_no_records'),
            items: details.medicalRecords,
            itemBuilder: (record) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                record.diagnosis.isEmpty
                    ? AppStrings.t('no_diagnosis')
                    : record.diagnosis,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${AppStrings.t('animal')}: '
                '${animalNamesById[record.animalId] ?? record.animalId}',
              ),
              trailing: Text(AppDateFormatter.shortDate(record.createdAt)),
            ),
          ),
          const SizedBox(height: 16),
          _SnapshotSection<AdminNotificationSnapshot>(
            title: AppStrings.t('notifications'),
            emptyLabel: AppStrings.t('admin_no_notifications'),
            items: details.notifications,
            itemBuilder: (notification) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(notification.title),
              subtitle: Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                AppDateFormatter.shortDateTime(notification.scheduledAt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends ConsumerWidget {
  final AdminManagedUser user;

  const _ActionPanel({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;

    return _SectionCard(
      title: AppStrings.t('admin_actions'),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: () => _showEditUserSheet(context, ref, user),
            icon: const Icon(Icons.edit_outlined),
            label: Text(AppStrings.t('admin_edit_user')),
          ),
          OutlinedButton.icon(
            onPressed: user.accountStatus == AppAccountStatus.active
                ? () => _showStatusDialog(
                    context,
                    ref,
                    user,
                    AppAccountStatus.suspended,
                  )
                : null,
            icon: const Icon(Icons.pause_circle_outline),
            label: Text(AppStrings.t('admin_suspend_user')),
          ),
          OutlinedButton.icon(
            onPressed: user.accountStatus == AppAccountStatus.deleted
                ? null
                : () => _showStatusDialog(
                    context,
                    ref,
                    user,
                    AppAccountStatus.deleted,
                  ),
            icon: Icon(Icons.delete_outline, color: appColors.danger),
            label: Text(
              AppStrings.t('admin_delete_user'),
              style: TextStyle(color: appColors.danger),
            ),
          ),
          if (!user.accountStatus.isActive)
            OutlinedButton.icon(
              onPressed: () => _reactivateUser(context, ref, user),
              icon: const Icon(Icons.restart_alt_outlined),
              label: Text(AppStrings.t('admin_reactivate_user')),
            ),
        ],
      ),
    );
  }

  Future<void> _showEditUserSheet(
    BuildContext context,
    WidgetRef ref,
    AdminManagedUser user,
  ) async {
    final usernameController = TextEditingController(text: user.username);
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final phoneController = TextEditingController(text: user.phone);
    final locationController = TextEditingController(text: user.location);
    var selectedRole = user.userType;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t('admin_edit_user'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('username'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('first_name'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('last_name'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('phone'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('location'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppUserType>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('role_title'),
                    ),
                    items: AppUserType.values.map((role) {
                      return DropdownMenuItem<AppUserType>(
                        value: role,
                        child: Text(AppStrings.t(role.labelKey)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setModalState(() => selectedRole = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(AppStrings.t('save_changes')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != true) {
      return;
    }

    try {
      await ref.read(adminUserManagementServiceProvider).updateUserProfile(
            userId: user.id,
            username: usernameController.text,
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            phone: phoneController.text,
            location: locationController.text,
            userType: selectedRole,
          );

      if (!context.mounted) {
        return;
      }

      refreshAdminUsers(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('admin_user_updated'))),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _showStatusDialog(
    BuildContext context,
    WidgetRef ref,
    AdminManagedUser user,
    AppAccountStatus targetStatus,
  ) async {
    final messageController = TextEditingController(
      text: user.adminStatusMessage ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppStrings.t(
              targetStatus == AppAccountStatus.deleted
                  ? 'admin_delete_user'
                  : 'admin_suspend_user',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.t('admin_status_dialog_description')),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: AppStrings.t('admin_status_message'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.t('save')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(adminUserManagementServiceProvider).updateUserStatus(
            userId: user.id,
            status: targetStatus,
            adminMessage: messageController.text,
          );

      if (!context.mounted) {
        return;
      }

      refreshAdminUsers(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('admin_status_updated'))),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _reactivateUser(
    BuildContext context,
    WidgetRef ref,
    AdminManagedUser user,
  ) async {
    try {
      await ref.read(adminUserManagementServiceProvider).updateUserStatus(
            userId: user.id,
            status: AppAccountStatus.active,
          );

      if (!context.mounted) {
        return;
      }

      refreshAdminUsers(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('admin_status_updated'))),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }
}

class _SnapshotSection<T> extends StatelessWidget {
  final String title;
  final String emptyLabel;
  final List<T> items;
  final Widget Function(T item) itemBuilder;

  const _SnapshotSection({
    required this.title,
    required this.emptyLabel,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: items.isEmpty
          ? Text(emptyLabel)
          : Column(children: items.take(6).map(itemBuilder).toList()),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: appColors.chipForeground.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appColors.selectionBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: appColors.mutedForeground),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;

  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appColors.selectionBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: appColors.chipForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AccountStatusPill extends StatelessWidget {
  final AppAccountStatus status;

  const _AccountStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final Color color = switch (status) {
      AppAccountStatus.active => appColors.success,
      AppAccountStatus.suspended => appColors.warning,
      AppAccountStatus.deleted => appColors.danger,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppStrings.t(status.labelKey),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
