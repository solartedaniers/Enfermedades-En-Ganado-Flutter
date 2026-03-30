import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_section_card.dart';
import '../widgets/profile_select_tile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nameController;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final isOnline = await ConnectivityService.checkAndNotify(
      context,
      message: AppStrings.t("profile_need_internet_avatar"),
    );
    if (!isOnline) return;

    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final storageService = ref.read(storageServiceProvider);
      final avatarUrl = await storageService.uploadUserAvatar(
        File(pickedImage.path),
        currentUser.id,
      );

      ref.read(profileProvider.notifier).changeAvatar(avatarUrl);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${AppStrings.t("upload_avatar_error")}: $error"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t("my_profile"))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(
              name: profile.name,
              avatarUrl: profile.avatarUrl,
              isUploadingAvatar: _isUploadingAvatar,
              onAvatarTap: _pickAndUploadAvatar,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: context.appColors.chipForeground,
                      ),
                    ).copyWith(labelText: AppStrings.t("name")),
                    onChanged: (value) =>
                        ref.read(profileProvider.notifier).changeName(value),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 20),
                  ProfileSectionCard(
                    title: AppStrings.t("app_theme"),
                    icon: Icons.palette_outlined,
                    children: [
                      ProfileSelectTile(
                        icon: Icons.brightness_auto,
                        label: AppStrings.t("theme_system"),
                        selected: profile.themeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(profileProvider.notifier)
                            .changeTheme(ThemeMode.system),
                      ),
                      ProfileSelectTile(
                        icon: Icons.light_mode,
                        label: AppStrings.t("theme_light"),
                        selected: profile.themeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(profileProvider.notifier)
                            .changeTheme(ThemeMode.light),
                      ),
                      ProfileSelectTile(
                        icon: Icons.dark_mode,
                        label: AppStrings.t("theme_dark"),
                        selected: profile.themeMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(profileProvider.notifier)
                            .changeTheme(ThemeMode.dark),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),
                  ProfileSectionCard(
                    title: AppStrings.t("language"),
                    icon: Icons.language,
                    children: [
                      ProfileSelectTile(
                        icon: Icons.language,
                        label: AppStrings.t("profile_language_spanish"),
                        selected: profile.language == "es",
                        onTap: () => ref
                            .read(profileProvider.notifier)
                            .changeLanguage("es"),
                      ),
                      ProfileSelectTile(
                        icon: Icons.language,
                        label: AppStrings.t("profile_language_english"),
                        selected: profile.language == "en",
                        onTap: () => ref
                            .read(profileProvider.notifier)
                            .changeLanguage("en"),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
