import 'package:uuid/uuid.dart';

class StoragePathBuilder {
  final Uuid uuid;

  const StoragePathBuilder({
    this.uuid = const Uuid(),
  });

  String buildAnimalImagePath(String userId) {
    return '$userId/${uuid.v4()}.jpg';
  }

  String buildUserAvatarPath(String userId) {
    return '$userId/${uuid.v4()}.jpg';
  }
}
