class Sm2Result {
  final double newInterval;
  final double newEaseFactor;
  final String newStatus;

  const Sm2Result({
    required this.newInterval,
    required this.newEaseFactor,
    required this.newStatus,
  });
}

class Sm2Algorithm {
  static const double minEaseFactor = 1.3;
  static const double defaultEaseFactor = 2.5;

  Sm2Result calculate({
    required int quality,
    required int reviewCount,
    required double easeFactor,
    required double interval,
  }) {
    double newEaseFactor = easeFactor;
    double newInterval = interval;
    String newStatus = 'review';

    if (quality >= 3) {
      if (reviewCount == 0) {
        newInterval = 1;
      } else if (reviewCount == 1) {
        newInterval = 6;
      } else {
        newInterval = interval * newEaseFactor;
      }
      newEaseFactor =
          easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (newEaseFactor < minEaseFactor) newEaseFactor = minEaseFactor;
    } else {
      newInterval = 1;
      newStatus = 'learning';
    }

    return Sm2Result(
      newInterval: newInterval,
      newEaseFactor: newEaseFactor,
      newStatus: newStatus,
    );
  }
}
