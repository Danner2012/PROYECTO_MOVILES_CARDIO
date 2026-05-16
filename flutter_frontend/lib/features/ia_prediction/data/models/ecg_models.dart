class EcgPredictionRequest {
  final double bpm;
  final double bpmAverage;
  final double rrInterval;
  final double hrv;
  final int electrodesConnected;
  final double signalQuality;
  final double amplitude;
  final int loPlus;
  final int loMinus;

  EcgPredictionRequest({
    required this.bpm,
    required this.bpmAverage,
    required this.rrInterval,
    required this.hrv,
    required this.electrodesConnected,
    required this.signalQuality,
    required this.amplitude,
    required this.loPlus,
    required this.loMinus,
  });

  Map<String, dynamic> toJson() => {
    "bpm": bpm,
    "bpm_average": bpmAverage,
    "rr_interval": rrInterval,
    "hrv": hrv,
    "electrodes_connected": electrodesConnected,
    "signal_quality": signalQuality,
    "amplitude": amplitude,
    "lo_plus": loPlus,
    "lo_minus": loMinus,
  };
}

class EcgPredictionResponse {
  final String prediction;
  final double confidence;
  final bool success;

  EcgPredictionResponse({
    required this.prediction,
    required this.confidence,
    required this.success,
  });

  factory EcgPredictionResponse.fromJson(Map<String, dynamic> json) => EcgPredictionResponse(
    prediction: json["prediction"] ?? "Error",
    confidence: (json["confidence"] as num?)?.toDouble() ?? 0.0,
    success: json["success"] ?? false,
  );
}

class EcgGraphResponse {
  final List<double> time;
  final List<double> signal;

  EcgGraphResponse({
    required this.time,
    required this.signal,
  });

  factory EcgGraphResponse.fromJson(Map<String, dynamic> json) => EcgGraphResponse(
    time: List<double>.from(json["time"].map((x) => x.toDouble())),
    signal: List<double>.from(json["signal"].map((x) => x.toDouble())),
  );
}
