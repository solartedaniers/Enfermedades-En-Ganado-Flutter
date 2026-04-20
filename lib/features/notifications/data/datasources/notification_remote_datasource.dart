import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final _supabaseClient = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) return [];

    final response = await _supabaseClient
        .from('notifications')
        .select('*, animals(name)')
        .eq('user_id', currentUser.id)
        .order('scheduled_at', ascending: true);

    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  Future<void> insertNotification(NotificationModel notification) async {
    await _supabaseClient.from('notifications').insert(notification.toJson());
  }

  Future<void> deleteNotification(String id) async {
    await _supabaseClient.from('notifications').delete().eq('id', id);
  }
}
