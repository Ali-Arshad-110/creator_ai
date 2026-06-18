import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../config/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // User profile section
            if (authState.user != null) ...[
              Card(
                color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: authState.user!.avatarUrl != null &&
                                authState.user!.avatarUrl!.isNotEmpty
                            ? NetworkImage(authState.user!.avatarUrl!)
                            : null,
                        child: authState.user!.avatarUrl != null &&
                                authState.user!.avatarUrl!.isNotEmpty
                            ? null
                            : Text(
                                (authState.user!.fullName ?? authState.user!.email)
                                    .trim()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState.user!.fullName ?? 'Creator',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.lightTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authState.user!.email,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // App Settings Section
            Text(
              'Preferences',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, color: AppTheme.primaryColor),
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Section
            Text(
              'About',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
                    title: Text('Version'),
                    trailing: Text('1.0.0'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.security_outlined, color: AppTheme.primaryColor),
                    title: Text('Privacy Policy'),
                    trailing: Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
