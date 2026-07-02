class ChatMessage {
  final String id;
  final String sender; // 'user' or 'assistant'
  final String text;
  final String timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}

class TravelExpense {
  final String id;
  final String category;
  final double amount; // In USD
  final String label;
  final String date;

  TravelExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.label,
    required this.date,
  });
}

class ActivityItem {
  String time;
  String activity;
  String description;
  String cost; // e.g., "$30" or "¥4,000" or "Free"
  bool checked;
  String locationName;
  String suggestedAttire;
  String transport;
  String ticketInfo;
  String placeDetails;

  ActivityItem({
    required this.time,
    required this.activity,
    required this.description,
    required this.cost,
    this.checked = false,
    this.locationName = "",
    this.suggestedAttire = "",
    this.transport = "",
    this.ticketInfo = "",
    this.placeDetails = "",
  });

  ActivityItem copyWith({
    String? time,
    String? activity,
    String? description,
    String? cost,
    bool? checked,
    String? locationName,
    String? suggestedAttire,
    String? transport,
    String? ticketInfo,
    String? placeDetails,
  }) {
    return ActivityItem(
      time: time ?? this.time,
      activity: activity ?? this.activity,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      checked: checked ?? this.checked,
      locationName: locationName ?? this.locationName,
      suggestedAttire: suggestedAttire ?? this.suggestedAttire,
      transport: transport ?? this.transport,
      ticketInfo: ticketInfo ?? this.ticketInfo,
      placeDetails: placeDetails ?? this.placeDetails,
    );
  }

  double get usdCost {
    final clean = cost.replaceAll(',', '').replaceAll('¥', '').replaceAll('\$', '').trim();
    final parsed = double.tryParse(clean) ?? 0.0;
    if (cost.contains('¥')) {
      return parsed / 155.0; // Assume 1 USD = 155 JPY
    }
    return parsed;
  }
}

class ItineraryDay {
  final int day;
  final String theme;
  final List<ActivityItem> activities;
  String notes;

  ItineraryDay({
    required this.day,
    required this.theme,
    required this.activities,
    this.notes = '',
  });

  ItineraryDay copyWith({
    int? day,
    String? theme,
    List<ActivityItem>? activities,
    String? notes,
  }) {
    return ItineraryDay(
      day: day ?? this.day,
      theme: theme ?? this.theme,
      activities: activities ?? this.activities,
      notes: notes ?? this.notes,
    );
  }
}

class ChecklistItem {
  final String id;
  final String text;
  bool checked;

  ChecklistItem({
    required this.id,
    required this.text,
    this.checked = false,
  });
}

class SuicaState {
  final double balance;
  final String status; // 'idle', 'scanning', 'success'

  SuicaState({
    required this.balance,
    required this.status,
  });

  SuicaState copyWith({
    double? balance,
    String? status,
  }) {
    return SuicaState(
      balance: balance ?? this.balance,
      status: status ?? this.status,
    );
  }
}

// ==========================================
// ITINERARY WIZARD MODELS
// ==========================================

class FlightBooking {
  final String id;
  final String airline;
  final String flightNumber;
  final String pnr;
  final String departureCity;
  final String arrivalCity;
  final String departureDate;
  final String arrivalDate;
  final String departureTime;
  final String arrivalTime;
  final String seatClass;
  final int passengers;
  final String flightType; // 'going', 'return', or 'other'

  FlightBooking({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.pnr,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureDate,
    required this.arrivalDate,
    this.departureTime = '',
    this.arrivalTime = '',
    this.seatClass = 'Economy',
    this.passengers = 1,
    this.flightType = 'other',
  });

  FlightBooking copyWith({
    String? airline,
    String? flightNumber,
    String? pnr,
    String? departureCity,
    String? arrivalCity,
    String? departureDate,
    String? arrivalDate,
    String? departureTime,
    String? arrivalTime,
    String? seatClass,
    int? passengers,
    String? flightType,
  }) {
    return FlightBooking(
      id: id,
      airline: airline ?? this.airline,
      flightNumber: flightNumber ?? this.flightNumber,
      pnr: pnr ?? this.pnr,
      departureCity: departureCity ?? this.departureCity,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      departureDate: departureDate ?? this.departureDate,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      seatClass: seatClass ?? this.seatClass,
      passengers: passengers ?? this.passengers,
      flightType: flightType ?? this.flightType,
    );
  }
}

class HotelBooking {
  final String id;
  final String hotelName;
  final String address;
  final String checkInDate;
  final String checkOutDate;
  final String roomType;
  final int guests;
  final String confirmationCode;
  final String checkInTime;
  final String checkOutTime;

  HotelBooking({
    required this.id,
    required this.hotelName,
    this.address = '',
    required this.checkInDate,
    required this.checkOutDate,
    this.roomType = 'Standard',
    this.guests = 1,
    this.confirmationCode = '',
    this.checkInTime = '03:00 PM',
    this.checkOutTime = '11:00 AM',
  });

  HotelBooking copyWith({
    String? hotelName,
    String? address,
    String? checkInDate,
    String? checkOutDate,
    String? roomType,
    int? guests,
    String? confirmationCode,
    String? checkInTime,
    String? checkOutTime,
  }) {
    return HotelBooking(
      id: id,
      hotelName: hotelName ?? this.hotelName,
      address: address ?? this.address,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      roomType: roomType ?? this.roomType,
      guests: guests ?? this.guests,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }
}

class OtherBooking {
  final String id;
  final String title;
  final String type; // tour, pass, activity, transport
  final String date;
  final String confirmationCode;
  final String notes;

  OtherBooking({
    required this.id,
    required this.title,
    this.type = 'activity',
    this.date = '',
    this.confirmationCode = '',
    this.notes = '',
  });
}

class TripBookings {
  final List<FlightBooking> flights;
  final List<HotelBooking> hotels;
  final List<OtherBooking> others;
  final String destination;
  final String? startDate;
  final String? endDate;
  final bool isManualDates;

  TripBookings({
    this.flights = const [],
    this.hotels = const [],
    this.others = const [],
    this.destination = '',
    this.startDate,
    this.endDate,
    this.isManualDates = false,
  });

  int get tripDays {
    if (startDate != null && endDate != null && startDate!.isNotEmpty && endDate!.isNotEmpty) {
      try {
        final start = DateTime.parse(startDate!);
        final end = DateTime.parse(endDate!);
        final days = end.difference(start).inDays + 1;
        return days > 0 ? days : 1;
      } catch (_) {}
    }
    // Compute from hotel check-in to check-out, or flight dates
    if (hotels.isNotEmpty) {
      try {
        final checkIn = DateTime.parse(hotels.first.checkInDate);
        final checkOut = DateTime.parse(hotels.first.checkOutDate);
        final days = checkOut.difference(checkIn).inDays;
        return days > 0 ? days : 1;
      } catch (_) {}
    }
    if (flights.isNotEmpty) {
      try {
        final dep = DateTime.parse(flights.first.departureDate);
        final arr = DateTime.parse(flights.last.arrivalDate.isNotEmpty ? flights.last.arrivalDate : flights.first.departureDate);
        final days = arr.difference(dep).inDays + 1;
        return days > 0 ? days : 1;
      } catch (_) {}
    }
    return 3; // Default
  }

  TripBookings copyWith({
    List<FlightBooking>? flights,
    List<HotelBooking>? hotels,
    List<OtherBooking>? others,
    String? destination,
    String? startDate,
    String? endDate,
    bool? isManualDates,
  }) {
    return TripBookings(
      flights: flights ?? this.flights,
      hotels: hotels ?? this.hotels,
      others: others ?? this.others,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isManualDates: isManualDates ?? this.isManualDates,
    );
  }
}

class ExplorePlaceItem {
  final String id;
  final String name;
  final String genre;
  final String imageUrl;
  final String description;
  final double rating;
  final String estimatedDuration;
  final String estimatedCost;
  final String address;
  final int durationMinutes; // precise duration for time-blocking
  bool isSelected;

  ExplorePlaceItem({
    required this.id,
    required this.name,
    required this.genre,
    required this.imageUrl,
    this.description = '',
    this.rating = 4.5,
    String estimatedDuration = '1 hr',
    this.estimatedCost = 'Free',
    this.address = '',
    int durationMinutes = 60,
    this.isSelected = false,
  }) : durationMinutes = _calculateDuration(genre, name),
       estimatedDuration = _calculateDurationStr(genre, name);

  static int _calculateDuration(String genre, String name) {
    final g = genre.toLowerCase();
    final n = name.toLowerCase();

    if (g.contains('beach') || g.contains('summer')) {
      return 120; // Beaches -> 2 Hours
    }
    if (g.contains('kids') || g.contains('family')) {
      return 60; // Kids & Family / Family -> 1 Hour
    }
    if (g.contains('relig') || n.contains('temple') || n.contains('church') || n.contains('mosque') || n.contains('monastery') || n.contains('shrine')) {
      return 60; // Religious Places -> 1 Hour
    }
    if (g.contains('food') || g.contains('culinary') || g.contains('dining') || g.contains('dine') || n.contains('restaurant') || n.contains('cafe') || n.contains('food stop') || n.contains('lunch') || n.contains('dinner')) {
      return 60; // Food & Dining -> 1 Hour
    }
    if (g.contains('shop') || n.contains('market') || n.contains('mall') || n.contains('shopping street')) {
      return 60; // Shopping -> 1 Hour
    }
    if (g.contains('adventure') || n.contains('zipline') || n.contains('trekking') || n.contains('rafting') || n.contains('skydiving') || n.contains('safari') || n.contains('adventure park')) {
      return 90; // Adventure Activities -> 1 Hour 30 Minutes
    }
    if (g.contains('nightlife') || g.contains('night')) {
      return 120; // Nightlife -> 2 Hours (11:00 PM to 1:00 AM)
    }
    return 60; // Default: 1 Hour
  }

  static String _calculateDurationStr(String genre, String name) {
    final dur = _calculateDuration(genre, name);
    if (dur == 60) return '1 hr';
    if (dur == 90) return '1.5 hrs';
    if (dur == 120) return '2 hrs';
    return '${dur ~/ 60} hrs';
  }

  int get openMinutes {
    switch (genre) {
      case 'Summer & Beach':
        return 360; // 06:00 AM
      case 'Kids & Family':
        return 540; // 09:00 AM
      case 'Religious':
        return 480; // 08:00 AM
      case 'Adventure':
        return 540; // 09:00 AM
      case 'Food & Culinary':
        return 660; // 11:00 AM
      case 'Culture & History':
        return 540; // 09:00 AM
      case 'Shopping':
        return 600; // 10:00 AM
      case 'Nightlife':
        return 1380; // 11:00 PM
      default:
        return 540; // 09:00 AM
    }
  }

  int get closeMinutes {
    switch (genre) {
      case 'Summer & Beach':
        return 1200; // 08:00 PM
      case 'Kids & Family':
        return 1200; // 08:00 PM
      case 'Religious':
        return 1020; // 05:00 PM
      case 'Adventure':
        return 1080; // 06:00 PM
      case 'Food & Culinary':
        return 1320; // 10:00 PM
      case 'Culture & History':
        return 1020; // 05:00 PM
      case 'Shopping':
        return 1260; // 09:00 PM
      case 'Nightlife':
        return 1500; // 01:00 AM next day
      default:
        return 1260; // 09:00 PM
    }
  }

  ExplorePlaceItem copyWith({
    String? name,
    String? genre,
    String? imageUrl,
    String? description,
    double? rating,
    String? estimatedDuration,
    String? estimatedCost,
    String? address,
    int? durationMinutes,
    bool? isSelected,
  }) {
    return ExplorePlaceItem(
      id: id,
      name: name ?? this.name,
      genre: genre ?? this.genre,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      address: address ?? this.address,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// ==========================================
// TIME HELPERS
// ==========================================

/// Parse "09:00 AM" or "14:30" → total minutes from midnight
int parseTimeToMinutes(String time) {
  time = time.trim().toUpperCase();
  final isPM = time.contains('PM');
  final isAM = time.contains('AM');
  final cleaned = time.replaceAll(RegExp(r'[APM\s]'), '');
  final parts = cleaned.split(':');
  int hours = int.tryParse(parts[0]) ?? 9;
  int minutes = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  if (isPM && hours != 12) hours += 12;
  if (isAM && hours == 12) hours = 0;
  return hours * 60 + minutes;
}

/// Total minutes from midnight → "09:00 AM" (handles wrap-around past midnight)
String minutesToTimeString(int totalMinutes) {
  final wrappedMinutes = totalMinutes % (24 * 60);
  int hours = wrappedMinutes ~/ 60;
  int minutes = wrappedMinutes % 60;
  final period = hours >= 12 ? 'PM' : 'AM';
  if (hours == 0) hours = 12;
  if (hours > 12) hours -= 12;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';
}

class DayScheduleItem {
  final ExplorePlaceItem place;
  String scheduledTime;
  int dayNumber;
  int sortOrder;

  DayScheduleItem({
    required this.place,
    this.scheduledTime = '09:00 AM',
    required this.dayNumber,
    this.sortOrder = 0,
  });

  /// End time computed from scheduledTime + place.durationMinutes
  String get endTime {
    final startMin = parseTimeToMinutes(scheduledTime);
    final endMin = startMin + place.durationMinutes;
    return minutesToTimeString(endMin);
  }

  /// Start in total minutes from midnight
  int get startMinutes => parseTimeToMinutes(scheduledTime);

  /// End in total minutes from midnight
  int get endMinutes => startMinutes + place.durationMinutes;

  DayScheduleItem copyWith({
    ExplorePlaceItem? place,
    String? scheduledTime,
    int? dayNumber,
    int? sortOrder,
  }) {
    return DayScheduleItem(
      place: place ?? this.place,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      dayNumber: dayNumber ?? this.dayNumber,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class DraftItinerary {
  final TripBookings bookings;
  final List<List<DayScheduleItem>> daySchedules;
  final String status; // 'draft', 'accepted'
  final DateTime createdAt;

  DraftItinerary({
    required this.bookings,
    required this.daySchedules,
    this.status = 'draft',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
