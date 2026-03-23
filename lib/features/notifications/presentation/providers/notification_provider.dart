import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/notification_remote_datasource.dart';

final notificationDataSourceProvider = Provider((ref) {
  return NotificationRemoteDataSource();
});