import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_managed_user.dart';
import '../../data/services/admin_user_management_service.dart';

final adminUserManagementServiceProvider = Provider<AdminUserManagementService>(
  (ref) => AdminUserManagementService(),
);

final adminUsersRefreshSignalProvider = StateProvider<int>((ref) => 0);

final adminUsersProvider =
    FutureProvider.autoDispose<List<AdminManagedUser>>((ref) async {
      ref.watch(adminUsersRefreshSignalProvider);
      return ref.read(adminUserManagementServiceProvider).fetchUsers();
    });

final adminUserDetailsProvider =
    FutureProvider.autoDispose.family<AdminManagedUserDetails, String>((
      ref,
      userId,
    ) async {
      ref.watch(adminUsersRefreshSignalProvider);
      return ref.read(adminUserManagementServiceProvider).fetchUserDetails(userId);
    });

void refreshAdminUsers(WidgetRef ref) {
  ref.read(adminUsersRefreshSignalProvider.notifier).state++;
}
