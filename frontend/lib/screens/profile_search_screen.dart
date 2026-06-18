import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_dashboard_view.dart';
import 'profile_dashboard_screen.dart';
import '../config/theme.dart';

class ProfileSearchScreen extends ConsumerStatefulWidget {
  const ProfileSearchScreen({super.key});

  @override
  ConsumerState<ProfileSearchScreen> createState() => _ProfileSearchScreenState();
}

class _ProfileSearchScreenState extends ConsumerState<ProfileSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(profileProvider.notifier).fetchHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(profileProvider.notifier).fetchSuggestions(query);
    });
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

    FocusScope.of(context).unfocus();
    ref.read(profileProvider.notifier).clearSuggestions();
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
      } else {
        // Automatically switch to the Dashboard tab to display the result
        setState(() {
          _tabController.index = 0;
        });
        // Refresh history list in the background
        ref.read(profileProvider.notifier).fetchHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = state.activeProfile ?? ProfileDashboardScreen.getDemoProfile();
    final isDemo = state.activeProfile == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sticky Search Field at the Top
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
                    fillColor: isDark ? AppTheme.darkSurfaceColor : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(profileProvider.notifier).clearActiveProfile();
                              ref.read(profileProvider.notifier).clearSuggestions();
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
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

          // Autocomplete Suggestions List Overlay
          if (state.suggestions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: state.suggestions.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final suggestion = state.suggestions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundImage: suggestion.avatarUrl != null
                            ? NetworkImage(suggestion.avatarUrl!)
                            : null,
                        child: suggestion.avatarUrl == null
                            ? Text(
                                suggestion.username.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(
                        '@${suggestion.username}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: suggestion.fullName != null
                          ? Text(
                              suggestion.fullName!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                              ),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _searchController.text = suggestion.username;
                        });
                        ref.read(profileProvider.notifier).clearSuggestions();
                        _triggerSearch();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Custom Segment Tab Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.primaryColor,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Dashboard'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('History'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Dashboard View (Demo or Active Profile)
                state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                        ),
                      )
                    : ProfileDashboardView(
                        profile: profile,
                        isDemo: isDemo,
                      ),

                // Tab 1: Search History View
                state.history.isEmpty
                    ? Center(
                        child: Text(
                          'No recent searches. Search a creator profile above to audit.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                  setState(() {
                                    _searchController.text = item.username;
                                  });
                                  // Analyze/load cached profile details
                                  await ref.read(profileProvider.notifier).analyzeProfile(item.username);
                                  // Switch to dashboard tab
                                  setState(() {
                                    _tabController.index = 0;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
