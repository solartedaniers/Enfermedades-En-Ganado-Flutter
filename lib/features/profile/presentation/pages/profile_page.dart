import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../animals/presentation/providers/animal_provider.dart';
import '../providers/profile_provider.dart';

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${AppStrings.t("upload_avatar_error")}: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t("my_profile"))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white24,
                            backgroundImage: profile.avatarUrl != null &&
                                    profile.avatarUrl!.isNotEmpty
                                ? NetworkImage(profile.avatarUrl!)
                                : null,
                            child: profile.avatarUrl == null ||
                                    profile.avatarUrl!.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 55,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        if (_isUploadingAvatar)
                          const CircularProgressIndicator(color: Colors.white)
                        else
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      prefixIcon:
                          Icon(Icons.person_outline, color: primaryColor),
                    ).copyWith(labelText: AppStrings.t("name")),
                    onChanged: (value) =>
                        ref.read(profileProvider.notifier).changeName(value),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: AppStrings.t("app_theme"),
                    icon: Icons.palette_outlined,
                    isDark: isDark,
                    children: [
                      _SelectTile(
                        icon: Icons.brightness_auto,
                        label: AppStrings.t("theme_system"),
                        selected: profile.themeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(profileProvider.notifier)
                            .changeTheme(ThemeMode.system),
                      ),
                      _SelectTile(
                        icon: Icons.light_mode,
                        label: AppStrings.t("theme_light"),
                        selected: profile.themeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(profileProvider.notifier)
                            .changeTheme(ThemeMode.light),
                      ),
                      _SelectTile(
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
                  _sectionCard(
                    title: AppStrings.t("language"),
                    icon: Icons.language,
                    isDark: isDark,
                    children: [
                      _SelectTile(
                        icon: Icons.language,
                        label: AppStrings.t("profile_language_spanish"),
                        selected: profile.language == "es",
                        onTap: () => ref
                            .read(profileProvider.notifier)
                            .changeLanguage("es"),
                      ),
                      _SelectTile(
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? primaryColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
