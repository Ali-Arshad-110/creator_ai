class AnalysisModel {
  final String id;
  final int hookScore;
  final String engagementPrediction;
  final String retentionPrediction;
  final List<String> strengths;
  final List<String> weaknesses;
  final String audienceFit;
  final List<String> improvementSuggestions;
  final List<String> contentIdeas;
  final List<String> captionSuggestions;
  final DateTime createdAt;

  const AnalysisModel({
    required this.id,
    required this.hookScore,
    required this.engagementPrediction,
    required this.retentionPrediction,
    required this.strengths,
    required this.weaknesses,
    required this.audienceFit,
    required this.improvementSuggestions,
    required this.contentIdeas,
    required this.captionSuggestions,
    required this.createdAt,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      id: json['id'] as String,
      hookScore: json['hook_score'] as int,
      engagementPrediction: json['engagement_prediction'] as String,
      retentionPrediction: json['retention_prediction'] as String,
      strengths: List<String>.from(json['strengths'] as List),
      weaknesses: List<String>.from(json['weaknesses'] as List),
      audienceFit: json['audience_fit'] as String,
      improvementSuggestions: List<String>.from(json['improvement_suggestions'] as List),
      contentIdeas: List<String>.from(json['content_ideas'] as List),
      captionSuggestions: List<String>.from(json['caption_suggestions'] as List),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hook_score': hookScore,
      'engagement_prediction': engagementPrediction,
      'retention_prediction': retentionPrediction,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'audience_fit': audienceFit,
      'improvement_suggestions': improvementSuggestions,
      'content_ideas': contentIdeas,
      'caption_suggestions': captionSuggestions,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AnalysisListItemModel {
  final String id;
  final String inputType;
  final String inputContent;
  final int hookScore;
  final DateTime createdAt;

  const AnalysisListItemModel({
    required this.id,
    required this.inputType,
    required this.inputContent,
    required this.hookScore,
    required this.createdAt,
  });

  factory AnalysisListItemModel.fromJson(Map<String, dynamic> json) {
    return AnalysisListItemModel(
      id: json['id'] as String,
      inputType: json['input_type'] as String,
      inputContent: json['input_content'] as String,
      hookScore: json['hook_score'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
