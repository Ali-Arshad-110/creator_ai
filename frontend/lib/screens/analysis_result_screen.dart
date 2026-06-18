import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/analysis_provider.dart';
import '../config/theme.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final String? analysisId;

  const AnalysisResultScreen({super.key, this.analysisId});

  @override
  ConsumerState<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  @override
  void initState() {
    super.initState();
    _loadDataIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AnalysisResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysisId != widget.analysisId) {
      _loadDataIfNeeded();
    }
  }

  void _loadDataIfNeeded() {
    if (widget.analysisId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentAnalysis = ref.read(analysisProvider).currentAnalysis;
        if (currentAnalysis == null || currentAnalysis.id != widget.analysisId) {
          ref.read(analysisProvider.notifier).loadAnalysis(widget.analysisId!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (analysisState.isLoading && analysisState.currentAnalysis == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Analyzing...',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/'),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating your content report...'),
            ],
          ),
        ),
      );
    }

    final analysis = analysisState.currentAnalysis;

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Result'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'No analysis report found.',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (analysisState.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    analysisState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analysis Report',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score Widget Card
              Card(
                color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${analysis.hookScore}',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hook Score',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.lightTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analysis.hookScore >= 7
                                  ? 'Excellent hook! Ready to grab attention.'
                                  : 'Consider refining the first 3 seconds.',
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
              const SizedBox(height: 16),

              // Engagement and Retention Predictions
              _buildSectionTitle(context, 'Audience Analysis & Predictions'),
              _buildAnalysisCard(
                context,
                icon: Icons.auto_graph_rounded,
                title: 'Engagement Prediction',
                description: analysis.engagementPrediction,
              ),
              const SizedBox(height: 12),
              _buildAnalysisCard(
                context,
                icon: Icons.timer_rounded,
                title: 'Retention Prediction',
                description: analysis.retentionPrediction,
              ),
              const SizedBox(height: 20),

              // Strengths and Weaknesses
              _buildSectionTitle(context, 'Strengths & Weaknesses'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildBulletListCard(
                      context,
                      title: 'Strengths',
                      items: analysis.strengths,
                      color: AppTheme.successColor,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBulletListCard(
                      context,
                      title: 'Weaknesses',
                      items: analysis.weaknesses,
                      color: Colors.redAccent,
                      icon: Icons.remove_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Suggestions
              _buildSectionTitle(context, 'Actionable Suggestions'),
              _buildSuggestionsCard(
                context,
                title: 'Improvement Suggestions',
                items: analysis.improvementSuggestions,
                icon: Icons.lightbulb_outline_rounded,
              ),
              const SizedBox(height: 20),

              // Ideas for next content
              _buildSectionTitle(context, 'What to post next'),
              _buildSuggestionsCard(
                context,
                title: 'Content Ideas',
                items: analysis.contentIdeas,
                icon: Icons.add_circle_outline_rounded,
              ),
              const SizedBox(height: 20),

              // Captions suggestions
              _buildSectionTitle(context, 'Optimized Captions'),
              _buildSuggestionsCard(
                context,
                title: 'Caption Alternatives',
                items: analysis.captionSuggestions,
                icon: Icons.chat_bubble_outline_rounded,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppTheme.lightTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletListCard(
    BuildContext context, {
    required String title,
    required List<String> items,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '• $item',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.3,
                    color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(
    BuildContext context, {
    required String title,
    required List<String> items,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚡',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                        ),
                      ),
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
