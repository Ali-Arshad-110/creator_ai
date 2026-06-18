import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_analysis_model.dart';
import '../services/api_service.dart';

class ProfileState {
  final List<ProfileHistoryItem> history;
  final ProfileAnalysisModel? activeProfile;
  final bool isLoading;
  final String? errorMessage;

  const ProfileState({
    this.history = const [],
    this.activeProfile,
    this.isLoading = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    List<ProfileHistoryItem>? history,
    ProfileAnalysisModel? activeProfile,
    bool? isLoading,
    String? errorMessage,
    bool clearActive = false,
    bool clearError = false,
  }) {
    return ProfileState(
      history: history ?? this.history,
      activeProfile: clearActive ? null : (activeProfile ?? this.activeProfile),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiService _apiService;

  ProfileNotifier(this._apiService) : super(const ProfileState());

  /// Request profile analysis from backend API.
  Future<void> analyzeProfile(String username) async {
    state = state.copyWith(isLoading: true, clearError: true, clearActive: true);
    try {
      final cleanUsername = username.trim().replaceAll('@', '');
      final response = await _apiService.post(
        '/profile/analyze',
        {'username': cleanUsername},
      );

      final analysis = ProfileAnalysisModel.fromJson(response);
      state = state.copyWith(
        isLoading: false,
        activeProfile: analysis,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Load profile search history from backend API.
  Future<void> fetchHistory({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiService.get(
        '/profile/history',
        queryParams: {
          'page': page.toString(),
          'limit': '20',
        },
      );

      final items = (response['items'] as List?)
              ?.map((item) => ProfileHistoryItem.fromJson(item as Map<String, dynamic>))
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

  /// Remove a search history record from the list.
  Future<void> deleteHistoryItem(String reportId) async {
    try {
      await _apiService.delete('/profile/history/$reportId');
      state = state.copyWith(
        history: state.history.where((item) => item.id != reportId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: _parseError(e),
      );
    }
  }

  /// Clear the active profile dashboard detail.
  void clearActiveProfile() {
    state = state.copyWith(clearActive: true);
  }

  String _parseError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('Rate limit')) {
      return 'Rate limit exceeded. Please wait a moment before searching again.';
    }
    if (msg.contains('Network')) {
      return 'Network error. Please check your internet connection.';
    }
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return 'Failed to analyze profile. Please try again.';
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final apiService = ApiService();
  return ProfileNotifier(apiService);
});
