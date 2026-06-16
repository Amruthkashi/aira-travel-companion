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

  ItineraryDay({
    required this.day,
    required this.theme,
    required this.activities,
  });
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
