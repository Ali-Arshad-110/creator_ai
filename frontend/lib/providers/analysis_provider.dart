import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AnalysisState {
  final List<AnalysisListItemModel> history;
  final AnalysisModel? currentAnalysis;
  final bool isLoading;
  final String? errorMessage;

  const AnalysisState({
    this.history = const [],
    this.currentAnalysis,
    this.isLoading = false,
    this.errorMessage,
  });

  AnalysisState copyWith({
    List<AnalysisListItemModel>? history,
    AnalysisModel? currentAnalysis,
    bool? isLoading,
    String? errorMessage,
    bool clearCurrent = false,
    bool clearError = false,
  }) {
    return AnalysisState(
      history: history ?? this.history,
      currentAnalysis: clearCurrent ? null : (currentAnalysis ?? this.currentAnalysis),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final ApiService _apiService;

  AnalysisNotifier(this._apiService) : super(const AnalysisState());

  /// Submit content for AI analysis via the backend API.
  Future<void> analyzeContent(String type, String content) async {
    state = state.copyWith(isLoading: true, clearError: true, clearCurrent: true);
    try {
      final response = await _apiService.post(
        AppConstants.analyzeEndpoint,
        {
          'input_type': type,
          'content': content,
        },
      );

      final analysis = AnalysisModel.fromJson(response);
      state = state.copyWith(
        isLoading: false,
        currentAnalysis: analysis,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Fetch paginated analysis history from the backend API.
  Future<void> fetchHistory({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.get(
        AppConstants.analysesEndpoint,
        queryParams: {
          'page': page.toString(),
          'limit': AppConstants.defaultPageSize.toString(),
        },
      );

      final items = (response['items'] as List?)
              ?.map((item) => AnalysisListItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      state = state.copyWith(
        isLoading: false,
        history: page == 1 ? items : [...state.history, ...items],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Load a single analysis detail by ID.
  Future<void> loadAnalysis(String analysisId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.get(
        '${AppConstants.analysesEndpoint}/$analysisId',
      );

      final analysis = AnalysisModel.fromJson(response);
      state = state.copyWith(
        isLoading: false,
        currentAnalysis: analysis,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Delete an analysis by ID.
  Future<void> deleteAnalysis(String analysisId) async {
    try {
      await _apiService.delete('${AppConstants.analysesEndpoint}/$analysisId');
      state = state.copyWith(
        history: state.history.where((item) => item.id != analysisId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: _parseError(e),
      );
    }
  }

  /// Clear current analysis result.
  void clearCurrent() {
    state = state.copyWith(clearCurrent: true);
  }

  String _parseError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('Rate limit')) {
      return 'You\'re analyzing too fast! Please wait a moment.';
    }
    if (msg.contains('Network')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    // Extract the detail message from "Exception: ..." format
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return 'Analysis failed. Please try again.';
  }
}

final analysisProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  final apiService = ApiService();
  return AnalysisNotifier(apiService);
});
