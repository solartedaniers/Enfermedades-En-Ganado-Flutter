import 'package:flutter/material.dart';

import '../../../../../core/services/managed_client_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/app_strings.dart';

class VeterinarianClientPanel extends StatelessWidget {
  final List<ManagedClientProfile> clients;
  final String? activeClientId;
  final ValueChanged<String?> onClientChanged;
  final VoidCallback onAddClient;
  final ValueChanged<ManagedClientProfile> onEditClient;
  final ValueChanged<ManagedClientProfile> onDeleteClient;

  const VeterinarianClientPanel({
    super.key,
    required this.clients,
    required this.activeClientId,
    required this.onClientChanged,
    required this.onAddClient,
    required this.onEditClient,
    required this.onDeleteClient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;
    ManagedClientProfile? activeClient;
    for (final client in clients) {
      if (client.id == activeClientId) {
        activeClient = client;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? appColors.cardDark : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: appColors.lightShadow,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t('veterinarian_clients_title'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.t('veterinarian_clients_subtitle'),
                        style: TextStyle(
                          color: appColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appColors.chipForeground,
                        appColors.success,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: appColors.chipForeground.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: onAddClient,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: appColors.onSolid,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(AppStrings.t('veterinarian_add_client')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (clients.isEmpty)
              Text(
                AppStrings.t('veterinarian_clients_empty'),
                style: TextStyle(color: appColors.mutedForeground),
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: activeClientId,
                decoration: InputDecoration(
                  labelText: AppStrings.t('veterinarian_active_client'),
                ),
                items: clients
                    .map(
                      (client) => DropdownMenuItem<String>(
                        value: client.id,
                        child: Text(client.name),
                      ),
                    )
                    .toList(),
                onChanged: onClientChanged,
              ),
              if (activeClient != null) ...[
                Builder(
                  builder: (context) {
                    final selectedClient = activeClient!;
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.surface,
                                appColors.selectionBackground,
                              ],
                            ),
                            border: Border.all(
                              color: appColors.chipForeground.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedClient.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: appColors.whiteOverlay,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      AppStrings.t(
                                        'veterinarian_active_client_badge',
                                      ),
                                      style: TextStyle(
                                        color: appColors.chipForeground,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedClient.location.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${AppStrings.t('veterinarian_client_location')}: ${selectedClient.location}',
                                  style: TextStyle(
                                    color: appColors.mutedForeground,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _ClientActionButton(
                                    tooltip: AppStrings.t(
                                      'veterinarian_edit_client',
                                    ),
                                    icon: Icons.edit_outlined,
                                    foregroundColor: appColors.chipForeground,
                                    backgroundColor: Color.lerp(
                                      appColors.selectionBackground,
                                      appColors.chipForeground,
                                      0.08,
                                    )!,
                                    onPressed: () =>
                                        onEditClient(selectedClient),
                                  ),
                                  const SizedBox(width: 12),
                                  _ClientActionButton(
                                    tooltip: AppStrings.t(
                                      'veterinarian_delete_client',
                                    ),
                                    icon: Icons.delete_outline_rounded,
                                    foregroundColor: appColors.danger,
                                    backgroundColor: Color.lerp(
                                      theme.colorScheme.errorContainer,
                                      appColors.danger,
                                      0.05,
                                    )!,
                                    onPressed: () =>
                                        onDeleteClient(selectedClient),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ClientActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _ClientActionButton({
    required this.tooltip,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: foregroundColor.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: foregroundColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}
