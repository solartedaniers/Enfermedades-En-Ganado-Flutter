import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_account_status.dart';
import '../../../../core/constants/app_user_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/models/admin_managed_user.dart';
import '../providers/admin_user_management_provider.dart';
import 'admin_user_detail_page.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  AppAccountStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    if (!profile.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.t('admin_panel'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppStrings.t('admin_access_denied'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('admin_panel')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: AppStrings.t('admin_search_users'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatusFilterChip(
                  label: AppStrings.t('admin_filter_all'),
                  selected: _selectedStatus == null,
                  onTap: () => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                for (final status in AppAccountStatus.values) ...[
                  _StatusFilterChip(
                    label: AppStrings.t(status.labelKey),
                    selected: _selectedStatus == status,
                    onTap: () => setState(() => _selectedStatus = status),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final visibleUsers = _filterUsers(users);

                if (visibleUsers.isEmpty) {
                  return Center(
                    child: Text(AppStrings.t('admin_users_empty')),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => refreshAdminUsers(ref),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: visibleUsers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = visibleUsers[index];
                      return _AdminUserListCard(
                        user: user,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminUserDetailPage(userId: user.id),
                            ),
                          );

                          if (!mounted) {
                            return;
                          }

                          refreshAdminUsers(ref);
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AdminManagedUser> _filterUsers(List<AdminManagedUser> users) {
    final query = _searchController.text.trim().toLowerCase();

    return users.where((user) {
      final matchesStatus =
          _selectedStatus == null || user.accountStatus == _selectedStatus;
      final matchesQuery =
          query.isEmpty ||
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);

      return matchesStatus && matchesQuery;
    }).toList();
  }
}

class _AdminUserListCard extends StatelessWidget {
  final AdminManagedUser user;
  final VoidCallback onTap;

  const _AdminUserListCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: appColors.chipForeground.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(color: appColors.mutedForeground),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PillLabel(label: AppStrings.t(user.userType.labelKey)),
                        _StatusPill(status: user.accountStatus),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: appColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: appColors.selectionBackground,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final AppAccountStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final Color color = switch (status) {
      AppAccountStatus.active => appColors.success,
      AppAccountStatus.suspended => appColors.warning,
      AppAccountStatus.deleted => appColors.danger,
    };

    return _PillLabel(
      label: AppStrings.t(status.labelKey),
      foregroundColor: color,
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}

class _PillLabel extends StatelessWidget {
  final String label;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const _PillLabel({
    required this.label,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? appColors.selectionBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? appColors.chipForeground,
        ),
      ),
    );
  }
}
