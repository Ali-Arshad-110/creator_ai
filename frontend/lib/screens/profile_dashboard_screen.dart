import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/profile_provider.dart';
import '../models/profile_analysis_model.dart';
import '../widgets/profile_dashboard_view.dart';

class ProfileDashboardScreen extends ConsumerWidget {
  const ProfileDashboardScreen({super.key});

  static ProfileAnalysisModel getDemoProfile() {
    return ProfileAnalysisModel(
      id: 'demo-id',
      username: 'creator_demo',
      fullName: 'Demo Creator Account',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=creator_demo',
      followersCount: 124500,
      followingCount: 412,
      postsCount: 284,
      biography: '🚀 Digital Creator & Growth consultant\n💡 Sharing viral hooks & scripting frameworks\n📩 Work: hello@creatordemo.com',
      externalUrl: 'https://linktr.ee/creatordemo',
      metrics: ProfileMetrics(
        engagementRate: 4.85,
        averageLikes: 5800.0,
        averageComments: 240.0,
        postingFrequency: 3.5,
        audienceQualityScore: 82,
        growthEstimation: 12.4,
        isEstimated: false,
        strengths: [
          'Exceptional engagement rate of 4.85% (industry benchmark: 1.8%).',
          'Strong influencer followers-to-following ratio (302x).',
          'Consistent weekly posting frequency.'
        ],
        weaknesses: [
          'Lower comments-to-likes ratio. Encourage more conversation starters.',
          'Opportunity to expand link-in-bio traffic using custom CTA posts.'
        ],
      ),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final profile = state.activeProfile ?? getDemoProfile();
    final isDemo = state.activeProfile == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDemo ? 'Demo Dashboard' : '@${profile.username} audit',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ProfileDashboardView(
            profile: profile,
            isDemo: isDemo,
          ),
        ),
      ),
    );
  }
}
