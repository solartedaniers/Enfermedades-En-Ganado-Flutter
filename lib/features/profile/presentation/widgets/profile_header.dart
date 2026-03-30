import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isUploadingAvatar;
  final VoidCallback onAvatarTap;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.heroGradientStart, appColors.heroGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
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
                    backgroundColor: appColors.whiteOverlay,
                    backgroundImage:
                        avatarUrl != null && avatarUrl!.isNotEmpty
                            ? NetworkImage(avatarUrl!)
                            : null,
                    child: avatarUrl == null || avatarUrl!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                if (isUploadingAvatar)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: appColors.chipForeground,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
