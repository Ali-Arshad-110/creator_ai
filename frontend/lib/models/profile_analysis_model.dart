class ProfileMetrics {
  final double engagementRate;
  final double averageLikes;
  final double averageComments;
  final double postingFrequency;
  final int audienceQualityScore;
  final double growthEstimation;
  final bool isEstimated;
  final List<String> strengths;
  final List<String> weaknesses;

  ProfileMetrics({
    required this.engagementRate,
    required this.averageLikes,
    required this.averageComments,
    required this.postingFrequency,
    required this.audienceQualityScore,
    required this.growthEstimation,
    required this.isEstimated,
    required this.strengths,
    required this.weaknesses,
  });

  factory ProfileMetrics.fromJson(Map<String, dynamic> json) {
    return ProfileMetrics(
      engagementRate: (json['engagement_rate'] as num).toDouble(),
      averageLikes: (json['average_likes'] as num).toDouble(),
      averageComments: (json['average_comments'] as num).toDouble(),
      postingFrequency: (json['posting_frequency'] as num).toDouble(),
      audienceQualityScore: json['audience_quality_score'] as int,
      growthEstimation: (json['growth_estimation'] as num).toDouble(),
      isEstimated: json['is_estimated'] as bool? ?? false,
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
    );
  }
}

class ProfileAnalysisModel {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String? biography;
  final String? externalUrl;
  final ProfileMetrics metrics;
  final DateTime updatedAt;

  ProfileAnalysisModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.biography,
    required this.externalUrl,
    required this.metrics,
    required this.updatedAt,
  });

  factory ProfileAnalysisModel.fromJson(Map<String, dynamic> json) {
    return ProfileAnalysisModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      followersCount: json['followers_count'] as int,
      followingCount: json['following_count'] as int,
      postsCount: json['posts_count'] as int,
      biography: json['biography'] as String?,
      externalUrl: json['external_url'] as String?,
      metrics: ProfileMetrics.fromJson(json['metrics'] ?? {}),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class ProfileHistoryItem {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final int followersCount;
  final double engagementRate;
  final DateTime createdAt;

  ProfileHistoryItem({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.followersCount,
    required this.engagementRate,
    required this.createdAt,
  });

  factory ProfileHistoryItem.fromJson(Map<String, dynamic> json) {
    return ProfileHistoryItem(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      followersCount: json['followers_count'] as int? ?? 0,
      engagementRate: (json['engagement_rate'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
