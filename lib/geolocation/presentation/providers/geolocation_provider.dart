import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/device_geolocation_datasource.dart';
import '../../data/datasources/region_disease_profile_datasource.dart';
import '../../data/repositories/geolocation_repository_impl.dart';
import '../../domain/entities/geolocation_context_entity.dart';
import '../../domain/usecases/get_current_geolocation_context.dart';

final deviceGeolocationDatasourceProvider =
    Provider<DeviceGeolocationDatasource>((ref) {
  return const DeviceGeolocationDatasource();
});

final regionDiseaseProfileDatasourceProvider =
    Provider<RegionDiseaseProfileDatasource>((ref) {
  return const RegionDiseaseProfileDatasource();
});

final geolocationRepositoryProvider = Provider<GeolocationRepositoryImpl>((ref) {
  return GeolocationRepositoryImpl(
    deviceDatasource: ref.watch(deviceGeolocationDatasourceProvider),
    regionProfileDatasource: ref.watch(regionDiseaseProfileDatasourceProvider),
  );
});

final getCurrentGeolocationContextProvider =
    Provider<GetCurrentGeolocationContext>((ref) {
  return GetCurrentGeolocationContext(ref.watch(geolocationRepositoryProvider));
});

final currentGeolocationContextProvider = AsyncNotifierProvider<
    CurrentGeolocationContextController, GeolocationContextEntity?>(
  CurrentGeolocationContextController.new,
);

class CurrentGeolocationContextController
    extends AsyncNotifier<GeolocationContextEntity?> {
  @override
  Future<GeolocationContextEntity?> build() async {
    return null;
  }

  Future<void> loadCurrentContext() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(getCurrentGeolocationContextProvider).call(),
    );
  }
}
