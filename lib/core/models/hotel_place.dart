class HotelPlace {
  const HotelPlace({
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
  });

  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;

  factory HotelPlace.fromGeoapifyFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? const [];

    final latitude = _asDouble(properties['lat']) ??
        (coordinates.length > 1 ? _asDouble(coordinates[1]) : null);
    final longitude = _asDouble(properties['lon']) ??
        (coordinates.isNotEmpty ? _asDouble(coordinates[0]) : null);

    if (latitude == null || longitude == null) {
      throw const FormatException('Geoapify result is missing coordinates.');
    }

    return HotelPlace(
      name: _firstNonEmpty([
        properties['name'],
        properties['hotel'],
        properties['address_line1'],
        properties['formatted'],
      ]),
      formattedAddress: _firstNonEmpty([
        properties['formatted'],
        properties['address_line2'],
        properties['address_line1'],
      ]),
      latitude: latitude,
      longitude: longitude,
      city: _stringOrNull(
        properties['city'] ?? properties['town'] ?? properties['village'],
      ),
      state: _stringOrNull(properties['state']),
      country: _stringOrNull(properties['country']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'formattedAddress': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
    };
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static String? _stringOrNull(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _stringOrNull(value);
      if (text != null) {
        return text;
      }
    }
    return 'Unnamed hotel';
  }
}
