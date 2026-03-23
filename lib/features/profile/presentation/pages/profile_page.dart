import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/storage_service.dart';
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
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final file = File(picked.path);
      final storageService = StorageService();
      final url = await storageService.uploadAnimalImage(file, user.id);
      ref.read(profileProvider.notifier).changeAvatar(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error subiendo avatar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- Avatar ---
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.green)
                      : null,
                ),
                if (_isUploadingAvatar)
                  const CircularProgressIndicator()
                else
                  GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Nombre ---
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (v) =>
                  ref.read(profileProvider.notifier).changeName(v),
            ),
            const SizedBox(height: 20),

            // --- Tema ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tema de la app",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _SelectTile(
                      icon: Icons.brightness_auto,
                      label: "Sistema (por defecto)",
                      selected: profile.themeMode == ThemeMode.system,
                      onTap: () => ref
                          .read(profileProvider.notifier)
                          .changeTheme(ThemeMode.system),
                    ),
                    _SelectTile(
                      icon: Icons.light_mode,
                      label: "Claro",
                      selected: profile.themeMode == ThemeMode.light,
                      onTap: () => ref
                          .read(profileProvider.notifier)
                          .changeTheme(ThemeMode.light),
                    ),
                    _SelectTile(
                      icon: Icons.dark_mode,
                      label: "Oscuro",
                      selected: profile.themeMode == ThemeMode.dark,
                      onTap: () => ref
                          .read(profileProvider.notifier)
                          .changeTheme(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Idioma ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Idioma",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _SelectTile(
                      icon: Icons.language,
                      label: "🇪🇸  Español",
                      selected: profile.language == "es",
                      onTap: () => ref
                          .read(profileProvider.notifier)
                          .changeLanguage("es"),
                    ),
                    _SelectTile(
                      icon: Icons.language,
                      label: "🇺🇸  English",
                      selected: profile.language == "en",
                      onTap: () => ref
                          .read(profileProvider.notifier)
                          .changeLanguage("en"),
                    ),
                  ],
                ),
              ),
            ),
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
    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? color : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}