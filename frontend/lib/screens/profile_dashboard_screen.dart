import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/profile_provider.dart';
import '../config/theme.dart';

class ProfileDashboardScreen extends ConsumerWidget {
  const ProfileDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = state.activeProfile;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Analytics')),
        body: Center(
          child: Text(
            'No active profile audit report found.',
            style: GoogleFonts.inter(),
          ),
        ),
      );
    }

    final numberFormatter = NumberFormat.compact();
    final followers = numberFormatter.format(profile.followersCount);
    final following = numberFormatter.format(profile.followingCount);
    final posts = numberFormatter.format(profile.postsCount);

    // Project growth data points for line chart based on followers count & growth estimation
    final growthEstPercent = profile.metrics.growthEstimation;
    final baseFollowers = profile.followersCount.toDouble();
    
    // Create 7 data points representing weekly steps backwards in time
    final List<FlSpot> spots = List.generate(7, (i) {
      final weekIndex = 6 - i; // i goes 0 to 6, weekIndex goes 6 to 0 (oldest to newest)
      // Estimate growth rate backwards (divide by 52 weeks in a year)
      final estimatedVal = baseFollowers * (1.0 - (weekIndex * (growthEstPercent / 100.0 / 52.0)));
      return FlSpot(i.toDouble(), estimatedVal);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '@${profile.username} audit',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fallback/Estimation Warning Banner (if applicable)
              if (profile.metrics.isEstimated)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Estimated values: Live Instagram connection is currently rate-limited. Analytics have been statistically modeled.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: profile.avatarUrl == null
                              ? Text(
                                  profile.username.substring(0, 2).toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName ?? profile.username,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.lightTextColor,
                              ),
                            ),
                            Text(
                              '@${profile.username}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (profile.externalUrl != null && profile.externalUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  profile.externalUrl!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (profile.biography != null && profile.biography!.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          profile.biography!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white.withOpacity(0.9) : AppTheme.lightTextColor,
                          ),
                        ),
                      ),
                    const Divider(height: 32),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProfileStatCard('Followers', followers, isDark),
                        _buildProfileStatCard('Following', following, isDark),
                        _buildProfileStatCard('Posts', posts, isDark),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Overview Metrics Grid
              Text(
                'Key Metrics',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.lightTextColor,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _buildMetricGridCard(
                    'Engagement Rate',
                    '${profile.metrics.engagementRate}%',
                    profile.metrics.engagementRate >= 2.5 ? 'Healthy' : 'Below average',
                    profile.metrics.engagementRate >= 2.5 ? AppTheme.successColor : Colors.orange,
                    isDark,
                  ),
                  _buildMetricGridCard(
                    'Audience Score',
                    '${profile.metrics.audienceQualityScore}/100',
                    profile.metrics.audienceQualityScore >= 75 ? 'Excellent' : 'Moderate',
                    profile.metrics.audienceQualityScore >= 75 ? AppTheme.successColor : Colors.orange,
                    isDark,
                  ),
                  _buildMetricGridCard(
                    'Avg. Interactions',
                    numberFormatter.format(profile.metrics.averageLikes),
                    '${numberFormatter.format(profile.metrics.averageComments)} comments',
                    AppTheme.primaryColor,
                    isDark,
                  ),
                  _buildMetricGridCard(
                    'Post Frequency',
                    '${profile.metrics.postingFrequency}/wk',
                    'Based on last 12 posts',
                    Colors.purpleAccent,
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Follower Growth Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Followers Growth Timeline',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estimated growth trend over the last 6 weeks (${profile.metrics.growthEstimation}% annualized)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final weekIndex = 6 - value.toInt();
                                  if (weekIndex == 6) return const Text('6w ago', style: TextStyle(fontSize: 10, color: Colors.grey));
                                  if (weekIndex == 3) return const Text('3w ago', style: TextStyle(fontSize: 10, color: Colors.grey));
                                  if (weekIndex == 0) return const Text('Now', style: TextStyle(fontSize: 10, color: Colors.grey));
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: AppTheme.primaryColor,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.primaryColor.withOpacity(0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Audit lists
              _buildAuditSection('Audits & Recommendations', profile.metrics.strengths, profile.metrics.weaknesses, isDark),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatCard(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.lightTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricGridCard(String label, String value, String subLabel, Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextColor,
            ),
          ),
          Text(
            subLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSection(String title, List<String> strengths, List<String> weaknesses, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 16),
          // Strengths
          if (strengths.isNotEmpty) ...[
            Text(
              'STRENGTHS',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successColor, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            ...strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s,
                          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.9) : AppTheme.lightTextColor),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (strengths.isNotEmpty && weaknesses.isNotEmpty) const SizedBox(height: 16),
          // Weaknesses
          if (weaknesses.isNotEmpty) ...[
            Text(
              'AREAS OF IMPROVEMENT',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            ...weaknesses.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w,
                          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.9) : AppTheme.lightTextColor),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
