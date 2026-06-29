class AviationFlight {
  final String flightNumber;
  final String airlineName;
  final String flightStatus;
  final String departureCity;
  final String arrivalCity;
  final String departureAirport;
  final String departureIata;
  final String arrivalAirport;
  final String arrivalIata;
  final String departureTime;
  final String departureDate;
  final String arrivalTime;
  final String arrivalDate;

  AviationFlight({
    required this.flightNumber,
    required this.airlineName,
    required this.flightStatus,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureAirport,
    required this.departureIata,
    required this.arrivalAirport,
    required this.arrivalIata,
    required this.departureTime,
    required this.departureDate,
    required this.arrivalTime,
    required this.arrivalDate,
  });

  static const Map<String, String> _iataToCity = {
    // UK & Europe
    'LHR': 'London',
    'LGW': 'London',
    'STN': 'London',
    'LTN': 'London',
    'LCY': 'London',
    'CDG': 'Paris',
    'ORY': 'Paris',
    'BVA': 'Paris',
    'AMS': 'Amsterdam',
    'FRA': 'Frankfurt',
    'MUC': 'Munich',
    'FCO': 'Rome',
    'MXP': 'Milan',
    'BCN': 'Barcelona',
    'MAD': 'Madrid',
    'DUB': 'Dublin',
    'ZRH': 'Zurich',
    'VIE': 'Vienna',
    'CPH': 'Copenhagen',
    'ATH': 'Athens',
    // Asia
    'SIN': 'Singapore',
    'NRT': 'Tokyo',
    'HND': 'Tokyo',
    'KIX': 'Osaka',
    'ITM': 'Osaka',
    'ICN': 'Seoul',
    'GMP': 'Seoul',
    'HKG': 'Hong Kong',
    'TPE': 'Taipei',
    'BKK': 'Bangkok',
    'DMK': 'Bangkok',
    'KUL': 'Kuala Lumpur',
    'CGK': 'Jakarta',
    'DPS': 'Bali',
    'MNL': 'Manila',
    'PEK': 'Beijing',
    'PKX': 'Beijing',
    'PVG': 'Shanghai',
    'SHA': 'Shanghai',
    'CAN': 'Guangzhou',
    'SZX': 'Shenzhen',
    'DEL': 'Delhi',
    'BOM': 'Mumbai',
    'BLR': 'Bangalore',
    'MAA': 'Chennai',
    'HYD': 'Hyderabad',
    'CCU': 'Kolkata',
    'COK': 'Kochi',
    'AMD': 'Ahmedabad',
    'PNQ': 'Pune',
    // Americas
    'JFK': 'New York',
    'LGA': 'New York',
    'EWR': 'New York',
    'LAX': 'Los Angeles',
    'SFO': 'San Francisco',
    'ORD': 'Chicago',
    'DFW': 'Dallas',
    'MIA': 'Miami',
    'ATL': 'Atlanta',
    'SEA': 'Seattle',
    'BOS': 'Boston',
    'IAD': 'Washington D.C.',
    'DCA': 'Washington D.C.',
    'PHL': 'Philadelphia',
    'DEN': 'Denver',
    'LAS': 'Las Vegas',
    'PHX': 'Phoenix',
    'IAH': 'Houston',
    'HOU': 'Houston',
    'YVR': 'Vancouver',
    'YYZ': 'Toronto',
    'YUL': 'Montreal',
    'MEX': 'Mexico City',
    'GRU': 'Sao Paulo',
    'GIG': 'Rio de Janeiro',
    'EZE': 'Buenos Aires',
    // Middle East & Africa
    'DXB': 'Dubai',
    'AUH': 'Abu Dhabi',
    'DOH': 'Doha',
    'MCT': 'Muscat',
    'RUH': 'Riyadh',
    'JED': 'Jeddah',
    'CAI': 'Cairo',
    'CPT': 'Cape Town',
    'JNB': 'Johannesburg',
    'NBO': 'Nairobi',
    // Oceania
    'SYD': 'Sydney',
    'MEL': 'Melbourne',
    'BNE': 'Brisbane',
    'PER': 'Perth',
    'AKL': 'Auckland',
    'CHC': 'Christchurch',
  };

  static String _extractCity(Map<String, dynamic> locationObj) {
    final iata = (locationObj['iata']?.toString() ?? '').toUpperCase();
    if (_iataToCity.containsKey(iata)) {
      return _iataToCity[iata]!;
    }

    // Fallback 1: Parse from timezone (e.g. Asia/Kolkata -> Kolkata)
    final timezone = locationObj['timezone']?.toString() ?? '';
    if (timezone.isNotEmpty && timezone.contains('/')) {
      final parts = timezone.split('/');
      final lastPart = parts.last.replaceAll('_', ' ');
      return _capitalize(lastPart);
    }

    // Fallback 2: Clean the airport name
    final airport = locationObj['airport']?.toString() ?? '';
    if (airport.isNotEmpty) {
      String cleaned = airport;
      if (cleaned.contains(' - ')) {
        cleaned = cleaned.split(' - ').first;
      }
      if (cleaned.contains(',')) {
        cleaned = cleaned.split(',').first;
      }
      final keywords = [
        ' International Airport',
        ' National Airport',
        ' Regional Airport',
        ' Municipal Airport',
        ' Airport',
        ' Intl',
        ' Arpt'
      ];
      for (final kw in keywords) {
        cleaned = cleaned.replaceAll(kw, '');
      }
      cleaned = cleaned.trim();
      if (cleaned.isNotEmpty) {
        return _capitalize(cleaned);
      }
    }

    return 'Unknown City';
  }

  factory AviationFlight.fromJson(Map<String, dynamic> json) {
    final flightObj = json['flight'] as Map<String, dynamic>? ?? {};
    final airlineObj = json['airline'] as Map<String, dynamic>? ?? {};
    final departureObj = json['departure'] as Map<String, dynamic>? ?? {};
    final arrivalObj = json['arrival'] as Map<String, dynamic>? ?? {};

    // Flight number IATA or fallback
    final flightIata = flightObj['iata']?.toString() ?? '';
    final flightNum = flightObj['number']?.toString() ?? '';
    final displayFlightNumber = flightIata.isNotEmpty ? flightIata : flightNum;

    // Airline Name extraction
    String airlineName = airlineObj['name']?.toString() ?? '';
    if (airlineName.isEmpty) {
      final codeshared = flightObj['codeshared'] as Map<String, dynamic>?;
      if (codeshared != null) {
        airlineName = codeshared['airline_name']?.toString() ?? '';
      }
    }
    if (airlineName.isEmpty) {
      airlineName = airlineObj['iata']?.toString() ?? 'Unknown Airline';
    }

    // Departure DateTime
    final depScheduledStr = departureObj['scheduled']?.toString() ?? '';
    final depEstimatedStr = departureObj['estimated']?.toString() ?? '';
    final depTimeStr = depScheduledStr.isNotEmpty ? depScheduledStr : depEstimatedStr;
    DateTime? depDateTime;
    if (depTimeStr.isNotEmpty) {
      try {
        depDateTime = DateTime.parse(depTimeStr).toLocal();
      } catch (_) {}
    }

    // Arrival DateTime
    final arrScheduledStr = arrivalObj['scheduled']?.toString() ?? '';
    final arrEstimatedStr = arrivalObj['estimated']?.toString() ?? '';
    final arrTimeStr = arrScheduledStr.isNotEmpty ? arrScheduledStr : arrEstimatedStr;
    DateTime? arrDateTime;
    if (arrTimeStr.isNotEmpty) {
      try {
        arrDateTime = DateTime.parse(arrTimeStr).toLocal();
      } catch (_) {}
    }

    final today = DateTime.now();
    final finalDepDateTime = depDateTime ?? today;
    final finalArrDateTime = arrDateTime ?? today.add(const Duration(hours: 4));

    return AviationFlight(
      flightNumber: displayFlightNumber,
      airlineName: _capitalize(airlineName),
      flightStatus: json['flight_status']?.toString() ?? 'scheduled',
      departureCity: _extractCity(departureObj),
      arrivalCity: _extractCity(arrivalObj),
      departureAirport: departureObj['airport']?.toString() ?? 'Unknown Airport',
      departureIata: departureObj['iata']?.toString() ?? '',
      arrivalAirport: arrivalObj['airport']?.toString() ?? 'Unknown Airport',
      arrivalIata: arrivalObj['iata']?.toString() ?? '',
      departureDate: _formatDate(finalDepDateTime),
      departureTime: _formatTime(finalDepDateTime),
      arrivalDate: _formatDate(finalArrDateTime),
      arrivalTime: _formatTime(finalArrDateTime),
    );
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime dt) {
    int hour = dt.hour;
    int minute = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
