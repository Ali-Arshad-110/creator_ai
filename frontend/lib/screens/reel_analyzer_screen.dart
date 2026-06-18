import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/analysis_provider.dart';
import '../config/theme.dart';

class ReelAnalyzerScreen extends ConsumerStatefulWidget {
  const ReelAnalyzerScreen({super.key});

  @override
  ConsumerState<ReelAnalyzerScreen> createState() => _ReelAnalyzerScreenState();
}

class _ReelAnalyzerScreenState extends ConsumerState<ReelAnalyzerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _triggerAnalysis() async {
    final isUrlTab = _tabController.index == 0;
    final content = isUrlTab ? _urlController.text.trim() : _textController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrlTab ? 'Please paste an Instagram Reel URL' : 'Please paste a script or text'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (isUrlTab && !content.toLowerCase().contains('instagram.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Instagram URL'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final type = isUrlTab ? 'url' : 'text';
    await ref.read(analysisProvider.notifier).analyzeContent(type, content);

    if (mounted) {
      final analysisState = ref.read(analysisProvider);
      if (analysisState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(analysisState.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (analysisState.currentAnalysis != null) {
        context.push('/analysis-result?id=${analysisState.currentAnalysis!.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Optimize Your Content',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get structured viral hooks, engagement insights and scripts suggestions in under 30 seconds.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
            ),
          ),
          const SizedBox(height: 28),
          
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
                Tab(text: 'Reel URL'),
                Tab(text: 'Reel Script'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _urlController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'https://www.instagram.com/reel/C3z...',
                        prefixIcon: const Icon(Icons.link_rounded),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Paste any public Reel link. CreatorAI will automatically download caption and script details.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                      ),
                    ),
                  ],
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _textController,
                        maxLines: 8,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Paste your draft script here...\n\nExample:\n"If you want to scale to \$10k, stop doing this..."',
                          filled: true,
                          fillColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: analysisState.isLoading ? null : _triggerAnalysis,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: analysisState.isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Analyzing Content...'),
                    ],
                  )
                : const Text('Analyze Content'),
          ),
        ],
      ),
    );
  }
}
