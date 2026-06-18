import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/profile_provider.dart';
import '../config/theme.dart';

class ProfileSearchScreen extends ConsumerStatefulWidget {
  const ProfileSearchScreen({super.key});

  @override
  ConsumerState<ProfileSearchScreen> createState() => _ProfileSearchScreenState();
}

class _ProfileSearchScreenState extends ConsumerState<ProfileSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).fetchHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an Instagram username'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Call analyze
    await ref.read(profileProvider.notifier).analyzeProfile(query);

    if (mounted) {
      final state = ref.read(profileProvider);
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (state.activeProfile != null) {
        context.push('/profile-dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Audits & Analytics',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search any public Instagram creator to view engagement rates, reach trends, and profile health.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
            ),
          ),
          const SizedBox(height: 24),

          // Search Field
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Enter Instagram username (e.g. mrbeast)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onFieldSubmitted: (_) => _triggerSearch(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: state.isLoading ? null : _triggerSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // History Section Header
          Text(
            'Recent Searches',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 12),

          // Search History list
          Expanded(
            child: state.history.isEmpty
                ? Center(
                    child: Text(
                      'No recent searches. Search a creator profile to begin.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.history.length,
                    itemBuilder: (context, index) {
                      final item = state.history[index];
                      final formatter = NumberFormat.compact();
                      final followers = formatter.format(item.followersCount);

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(profileProvider.notifier).deleteHistoryItem(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Removed @${item.username} audit report')),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: item.avatarUrl == null
                                  ? Text(
                                      item.username.substring(0, 2).toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              '@${item.username}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.lightTextColor,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '$followers followers  •  ER: ${item.engagementRate}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                                ),
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                            onTap: () async {
                              // Trigger analyze again to load/refresh
                              await ref.read(profileProvider.notifier).analyzeProfile(item.username);
                              if (context.mounted) {
                                context.push('/profile-dashboard');
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
