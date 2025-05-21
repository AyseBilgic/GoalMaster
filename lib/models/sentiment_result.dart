// c:\src\flutter_application1\lib\models\sentiment_result.dart

class SentimentScoreDetails {
  final double positive;
  final double negative;
  final double neutral;
  // İsteğe bağlı olarak 'mixed' gibi başka duygu durumları için skorlar eklenebilir.

  SentimentScoreDetails({
    required this.positive,
    required this.negative,
    required this.neutral,
  });

  factory SentimentScoreDetails.fromJson(Map<String, dynamic> json) {
    return SentimentScoreDetails(
      positive: (json['positive'] as num?)?.toDouble() ?? 0.0,
      negative: (json['negative'] as num?)?.toDouble() ?? 0.0,
      neutral: (json['neutral'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'positive': positive,
      'negative': negative,
      'neutral': neutral,
    };
  }
}

class SentimentResult {
  final String overallSentiment; // Örn: "positive", "negative", "neutral", "mixed"
  final double confidenceScore;  // 'overallSentiment' için genel güven skoru
  final SentimentScoreDetails? detailedScores; // Ayrıntılı duygu skorları

  SentimentResult({
    required this.overallSentiment,
    required this.confidenceScore,
    this.detailedScores,
  });

  factory SentimentResult.fromJson(Map<String, dynamic> json) {
    return SentimentResult(
      overallSentiment: json['overall_sentiment'] as String? ?? 'neutral',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      detailedScores: json.containsKey('detailed_scores') && json['detailed_scores'] != null
          ? SentimentScoreDetails.fromJson(json['detailed_scores'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_sentiment': overallSentiment,
      'confidence_score': confidenceScore,
      'detailed_scores': detailedScores?.toJson(),
    };
  }
}