import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/auth_user.dart';
import '../../core/themes/themes.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  static const double _avatarSize = 64;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final user = context.watch<AuthRepository>().currentUser;

    final displayName = (user?.displayName ?? '').trim();
    final email = user?.email.trim() ?? '';
    final fallbackName = displayName.isEmpty
        ? (email.isNotEmpty ? email.split('@').first : '—')
        : displayName;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDim),
      ),
      child: Row(
        children: [
          _Avatar(user: user),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fallbackName,
                  style: text.titleLarge?.copyWith(color: colors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style:
                        text.bodyMedium?.copyWith(color: colors.textDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final photo = user?.photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Container(
      width: ProfileHeader._avatarSize,
      height: ProfileHeader._avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface2,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initials(user: user),
            )
          : _Initials(user: user),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Center(
      child: Text(
        _initialsFor(user),
        style: text.titleLarge?.copyWith(
          color: colors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _initialsFor(AuthUser? user) {
    if (user == null) return '?';
    final name = (user.displayName ?? '').trim();
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length == 1) return parts.first[0].toUpperCase();
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    final email = user.email.trim();
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
}
