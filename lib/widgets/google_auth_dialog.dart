import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/providers.dart';
import '../services/firebase_sync_service.dart';
import '../services/gcal_service.dart';

Future<void> showGoogleAuthDialog(BuildContext context, WidgetRef ref) async {
  SystemSound.play(SystemSoundType.click);
  HapticFeedback.mediumImpact();

  return showDialog<void>(
    context: context,
    builder: (ctx) => const _GoogleAuthModal(),
  );
}

class _GoogleAuthModal extends ConsumerStatefulWidget {
  const _GoogleAuthModal();

  @override
  ConsumerState<_GoogleAuthModal> createState() => _GoogleAuthModalState();
}

class _GoogleAuthModalState extends ConsumerState<_GoogleAuthModal> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final syncService = ref.read(firebaseSyncServiceProvider);
      final cred = await syncService.signInWithGoogle();
      final user = cred?.user ?? syncService.currentUser;

      if (user != null) {
        final email = user.email ?? '';
        ref.read(gcalSignedInProvider.notifier).state = true;
        final gcalSvc = ref.read(gcalServiceProvider);
        await gcalSvc.signIn(fallbackEmail: email);

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF34A853),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🎉 Terhubung: $email\nSinkronisasi Cloud Firebase & Google Calendar Aktif!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      await ref.read(firebaseSyncServiceProvider).signOut();
      await ref.read(gcalServiceProvider).signOut();
      ref.read(gcalSignedInProvider.notifier).state = false;

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun Google berhasil terputus.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).valueOrNull ?? ref.watch(firebaseSyncServiceProvider).currentUser;
    final signedIn = user != null && (user.email?.isNotEmpty ?? false);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Google Brand Multi-Color Top Accent Bar
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Row(
                  children: [
                    Expanded(child: Container(height: 5, color: const Color(0xFF4285F4))), // Blue
                    Expanded(child: Container(height: 5, color: const Color(0xFFEA4335))), // Red
                    Expanded(child: Container(height: 5, color: const Color(0xFFFBBC05))), // Yellow
                    Expanded(child: Container(height: 5, color: const Color(0xFF34A853))), // Green
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Google Brand Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.text,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Focus Clock Cloud & Calendar Sync',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppPalette.textDim,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppPalette.textDim),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (signedIn) ...[
                      // Signed In Status Card with Real Profile Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF34A853).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            if (user.photoURL != null && user.photoURL!.isNotEmpty)
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage(user.photoURL!),
                              )
                            else
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34A853),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    (user.displayName?.isNotEmpty == true)
                                        ? user.displayName![0].toUpperCase()
                                        : (user.email?.isNotEmpty == true ? user.email![0].toUpperCase() : 'U'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF34A853), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.displayName?.isNotEmpty == true ? user.displayName! : 'Google Account Connected',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF34A853),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppPalette.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aktivitas Focus Clock tersinkronisasi otomatis secara real-time ke Cloud Firestore & Google Calendar.',
                        style: TextStyle(fontSize: 12, color: AppPalette.textDim, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppPalette.danger,
                              side: const BorderSide(color: AppPalette.danger),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: _isLoading ? null : _handleSignOut,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Disconnect Account'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Hubungkan akun Google resmi untuk sinkronisasi aktivitas, preset, dan kalender di seluruh perangkat:',
                        style: TextStyle(fontSize: 13, color: AppPalette.text, height: 1.4),
                      ),
                      const SizedBox(height: 16),

                      // OAuth Scopes Authorization List
                      const Text(
                        'IZIN AKSES RESMI GOOGLE (SCOPES):',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.textDim,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _ScopeItem(title: 'Firebase Authentication & Cloud Storage'),
                      const _ScopeItem(title: 'Google Calendar API v3 (Read/Write)'),
                      const _ScopeItem(title: 'Sinkronisasi Otomatis Seluruh Perangkat (Web, Android & Desktop)'),
                      
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppPalette.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppPalette.danger.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppPalette.danger, fontSize: 11),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Official Google Sign-In Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                        label: Text(
                          _isLoading ? 'Membuka Google OAuth...' : 'Lanjutkan dengan Google',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeItem extends StatelessWidget {
  const _ScopeItem({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF34A853)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppPalette.text, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
