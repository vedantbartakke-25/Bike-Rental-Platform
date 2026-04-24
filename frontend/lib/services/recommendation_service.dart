class RecommendationService {
  static String? getTip(Map<String, dynamic> bike) {
    final String? type = bike['bike_type']?.toString().toLowerCase();
    final String? model = bike['model']?.toString().toLowerCase();
    
    int cc = 0;
    if (bike['engine_cc'] != null) {
      cc = int.tryParse(bike['engine_cc'].toString()) ?? 0;
    }

    if (type != null && (type.contains('scooter') || type.contains('moped'))) {
      return 'Great for city commutes and easy traffic navigation.';
    } else if (type != null && type.contains('cruiser')) {
      return 'Perfect for long comfortable rides and highway cruising.';
    } else if (type != null && type.contains('sports') || cc >= 250) {
      return 'Exciting performance and acceleration. Recommended for experienced riders.';
    } else if (type != null && type.contains('commuter')) {
      return 'Excellent fuel efficiency for everyday use.';
    } else if (model != null && (model.contains('activa') || model.contains('jupiter') || model.contains('ntorq'))) {
      return 'Great for city commutes and easy traffic navigation.';
    } else if (model != null && (model.contains('bullet') || model.contains('classic') || model.contains('meteor'))) {
      return 'Perfect for long comfortable rides and highway cruising.';
    }
    
    return 'A solid choice for your riding needs.';
  }
}
