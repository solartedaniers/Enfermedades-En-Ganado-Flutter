import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final _supabase = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('notifications')
        .select('*, animals(name)')
        .eq('user_id', user.id)
        .order('scheduled_at', ascending: true);

    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  Future<void> insertNotification(NotificationModel n) async {
    await _supabase.from('notifications').insert(n.toJson());
  }

  Future<void> deleteNotification(String id) async {
    await _supabase.from('notifications').delete().eq('id', id);
  }
}