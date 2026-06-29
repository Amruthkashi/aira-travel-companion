import 'dart:math';
import '../models/travel_models.dart';

class ValidationReport {
  bool flightsValidated;
  bool hotelsValidated;
  bool transfersValidated;
  bool attractionsValidated;
  bool timelineValidated;
  List<String> conflictsFixed;

  ValidationReport({
    this.flightsValidated = false,
    this.hotelsValidated = false,
    this.transfersValidated = false,
    this.attractionsValidated = false,
    this.timelineValidated = false,
    List<String>? conflictsFixed,
  }) : conflictsFixed = conflictsFixed ?? [];
}

class ResolvedItineraryResult {
  final List<List<ActivityItem>> resolvedDays;
  final ValidationReport report;

  ResolvedItineraryResult({
    required this.resolvedDays,
    required this.report,
  });
}

/// Helper to get base start date
DateTime getBaseStartDate(TripBookings bookings) {
  if (bookings.startDate != null && bookings.startDate!.isNotEmpty) {
    try {
      return DateTime.parse(bookings.startDate!);
    } catch (_) {}
  }
  if (bookings.hotels.isNotEmpty) {
    try {
      return DateTime.parse(bookings.hotels.first.checkInDate);
    } catch (_) {}
  }
  if (bookings.flights.isNotEmpty) {
    try {
      return DateTime.parse(bookings.flights.first.departureDate);
    } catch (_) {}
  }
  return DateTime.now();
}

/// Combines a date string and time string (e.g. '2026-06-19', '10:00 AM') into a single DateTime
DateTime? parseFlightDateTime(String dateStr, String timeStr) {
  if (dateStr.isEmpty) return null;
  try {
    final date = DateTime.parse(dateStr);
    final timeMin = parseTimeToMinutes(timeStr.isNotEmpty ? timeStr : '12:00 PM');
    return DateTime(date.year, date.month, date.day).add(Duration(minutes: timeMin));
  } catch (_) {
    return null;
  }
}

/// Utility helper to compare flight times by departure date and time
int _compareFlightTimes(FlightBooking a, FlightBooking b) {
  final dtA = parseFlightDateTime(a.departureDate, a.departureTime) ?? DateTime(1970);
  final dtB = parseFlightDateTime(b.departureDate, b.departureTime) ?? DateTime(1970);
  return dtA.compareTo(dtB);
}

/// Identifies the Going Flight (outbound):
/// Explicitly marked 'going' or chronologically earliest
FlightBooking? getGoingFlight(TripBookings bookings) {
  final explicitGoing = bookings.flights.where((f) => f.flightType == 'going').toList();
  if (explicitGoing.isNotEmpty) return explicitGoing.first;
  
  if (bookings.flights.isEmpty) return null;
  final sorted = List<FlightBooking>.from(bookings.flights)
    ..sort(_compareFlightTimes);
  
  if (bookings.flights.length == 1 && bookings.flights.first.flightType == 'return') {
    return null;
  }
  return sorted.first;
}

/// Identifies the Return Flight (inbound):
/// Explicitly marked 'return' or chronologically latest (if >=2 flights)
FlightBooking? getReturnFlight(TripBookings bookings) {
  final explicitReturn = bookings.flights.where((f) => f.flightType == 'return').toList();
  if (explicitReturn.isNotEmpty) return explicitReturn.first;
  
  if (bookings.flights.length < 2) return null;
  final sorted = List<FlightBooking>.from(bookings.flights)
    ..sort(_compareFlightTimes);
  
  if (sorted.last.flightType == 'going') {
    return null;
  }
  return sorted.last;
}

/// Dynamic Timeline Validation and Conflict Resolution Engine
ResolvedItineraryResult validateAndResolveItinerary(DraftItinerary draft) {
  final bookings = draft.bookings;
  final report = ValidationReport(
    flightsValidated: true,
    hotelsValidated: true,
    transfersValidated: true,
    attractionsValidated: true,
    timelineValidated: true,
  );

  final List<List<ActivityItem>> resolvedDays = [];
  final baseStart = getBaseStartDate(bookings);

  // Check for hotel overlap stays across multiple hotels
  if (bookings.hotels.length > 1) {
    for (int i = 0; i < bookings.hotels.length; i++) {
      for (int j = i + 1; j < bookings.hotels.length; j++) {
        final hA = bookings.hotels[i];
        final hB = bookings.hotels[j];
        try {
          final inA = DateTime.parse(hA.checkInDate);
          final outA = DateTime.parse(hA.checkOutDate);
          final inB = DateTime.parse(hB.checkInDate);
          final outB = DateTime.parse(hB.checkOutDate);
          if (inA.isBefore(outB) && inB.isBefore(outA)) {
            report.conflictsFixed.add("Warning: Overlapping stays detected between ${hA.hotelName} and ${hB.hotelName}. Check dates!");
          }
        } catch (_) {}
      }
    }
  }

  final goingFlight = getGoingFlight(bookings);
  final returnFlight = getReturnFlight(bookings);

  final goingLanding = goingFlight != null
      ? parseFlightDateTime(goingFlight.arrivalDate.isNotEmpty ? goingFlight.arrivalDate : goingFlight.departureDate, goingFlight.arrivalTime.isNotEmpty ? goingFlight.arrivalTime : '10:00 AM')
      : null;
  final returnDeparture = returnFlight != null
      ? parseFlightDateTime(returnFlight.departureDate, returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM')
      : null;

  for (int dayIdx = 0; dayIdx < draft.daySchedules.length; dayIdx++) {
    final dayItems = draft.daySchedules[dayIdx];
    final dayDate = baseStart.add(Duration(days: dayIdx));
    final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

    final isGoingLandingDay = goingLanding != null &&
        dayDate.year == goingLanding.year &&
        dayDate.month == goingLanding.month &&
        dayDate.day == goingLanding.day;

    final isReturnDepartureDay = returnDeparture != null &&
        dayDate.year == returnDeparture.year &&
        dayDate.month == returnDeparture.month &&
        dayDate.day == returnDeparture.day;

    final isBeforeGoingFlight = goingLanding != null &&
        DateTime(dayDate.year, dayDate.month, dayDate.day).isBefore(DateTime(goingLanding.year, goingLanding.month, goingLanding.day));

    final isAfterReturnFlight = returnDeparture != null &&
        DateTime(dayDate.year, dayDate.month, dayDate.day).isAfter(DateTime(returnDeparture.year, returnDeparture.month, returnDeparture.day));


    final checkingInHotels = bookings.hotels.where((h) => h.checkInDate == dateStr).toList();
    final checkingOutHotels = bookings.hotels.where((h) => h.checkOutDate == dateStr).toList();

    final activeHotelsForNight = bookings.hotels.where((h) {
      try {
        final checkIn = DateTime.parse(h.checkInDate);
        final checkOut = DateTime.parse(h.checkOutDate);
        final dDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
        final ci = DateTime(checkIn.year, checkIn.month, checkIn.day);
        final co = DateTime(checkOut.year, checkOut.month, checkOut.day);
        return (dDate.isAtSameMomentAs(ci) || dDate.isAfter(ci)) && dDate.isBefore(co);
      } catch (_) {
        return false;
      }
    }).toList();

    final prevDayDate = dayDate.subtract(const Duration(days: 1));
    final activeHotelsForPrevNight = bookings.hotels.where((h) {
      try {
        final checkIn = DateTime.parse(h.checkInDate);
        final checkOut = DateTime.parse(h.checkOutDate);
        final dDate = DateTime(prevDayDate.year, prevDayDate.month, prevDayDate.day);
        final ci = DateTime(checkIn.year, checkIn.month, checkIn.day);
        final co = DateTime(checkOut.year, checkOut.month, checkOut.day);
        return (dDate.isAtSameMomentAs(ci) || dDate.isAfter(ci)) && dDate.isBefore(co);
      } catch (_) {
        return false;
      }
    }).toList();

    // Create a time allocation grid for 1500 minutes in a day
    // 0 = free, 1 = occupied by logistics/flight, 2 = occupied by attractions
    final List<int> timeGrid = List.filled(1500, 0);
    final List<ActivityItem> dayActivities = [];

    // Helper to block time intervals
    void markGridBusy(int start, int end, int val) {
      final s = start.clamp(0, 1499);
      final e = end.clamp(0, 1499);
      for (int i = s; i < e; i++) {
        timeGrid[i] = val;
      }
    }

    // Helper to check if grid is free
    bool isGridIntervalFree(int start, int end) {
      final s = start.clamp(0, 1499);
      final e = end.clamp(0, 1499);
      for (int i = s; i < e; i++) {
        if (timeGrid[i] != 0) return false;
      }
      return true;
    }

    // Block whole days before going landing or after return departure
    if (isBeforeGoingFlight && goingFlight != null) {
      markGridBusy(0, 1500, 1);
      dayActivities.add(ActivityItem(
        time: '09:00 AM',
        activity: '🛄 Awaiting Departure',
        description: 'No activities scheduled. Going flight lands on ${goingFlight.arrivalDate} at ${goingFlight.arrivalTime}.',
        cost: '-',
        locationName: goingFlight.departureCity,
        transport: '-',
        placeDetails: 'Trip starts on ${goingFlight.arrivalDate}',
      ));
      dayActivities.sort((a, b) => parseTimeToMinutes(a.time).compareTo(parseTimeToMinutes(b.time)));
      resolvedDays.add(dayActivities);
      continue;
    }

    if (isAfterReturnFlight && returnFlight != null) {
      markGridBusy(0, 1500, 1);
      dayActivities.add(ActivityItem(
        time: '09:00 AM',
        activity: '🛫 Trip Completed',
        description: 'Returned home. Flight departed on ${returnFlight.departureDate} at ${returnFlight.departureTime}.',
        cost: '-',
        locationName: returnFlight.arrivalCity,
        transport: '-',
        placeDetails: 'Trip ended on ${returnFlight.departureDate}',
      ));
      dayActivities.sort((a, b) => parseTimeToMinutes(a.time).compareTo(parseTimeToMinutes(b.time)));
      resolvedDays.add(dayActivities);
      continue;
    }

    int timelineStartMin = 480; // 08:00 AM default start

    // Day Flight Arrival Start Constraint
    if (isGoingLandingDay && goingFlight != null) {
      final arrivalTimeStr = goingFlight.arrivalTime.isNotEmpty ? goingFlight.arrivalTime : '10:00 AM';
      final arrMin = parseTimeToMinutes(arrivalTimeStr);

      // Block all time before flight arrival
      markGridBusy(0, arrMin, 1);
      timelineStartMin = arrMin;

      // Add Flight Arrival Item
      dayActivities.add(ActivityItem(
        time: arrivalTimeStr,
        activity: '✈️ Arrive at Airport',
        description: '${goingFlight.airline} lands at ${goingFlight.arrivalCity}',
        cost: '-',
        locationName: '${goingFlight.arrivalCity} Airport',
        transport: 'Flight',
        ticketInfo: goingFlight.pnr.isNotEmpty ? 'PNR: ${goingFlight.pnr}' : '',
        placeDetails: '${goingFlight.seatClass} Class • ${goingFlight.passengers} pax',
      ));

      // Add Airport processing time (60 mins)
      final procEnd = arrMin + 60;
      dayActivities.add(ActivityItem(
        time: minutesToTimeString(arrMin),
        activity: '✈️ Airport Processing & Customs',
        description: 'Baggage collection, customs clearance, and terminal egress.',
        cost: '-',
        locationName: '${goingFlight.arrivalCity} Airport',
        transport: '-',
        placeDetails: '60-min airport processing buffer',
      ));
      markGridBusy(arrMin, procEnd, 1);

      // Add Travel time to hotel (45 mins)
      final transferEnd = procEnd + 45;
      final destinationHotel = checkingInHotels.isNotEmpty 
          ? checkingInHotels.first 
          : (activeHotelsForNight.isNotEmpty ? activeHotelsForNight.first : null);

      if (destinationHotel != null) {
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(procEnd),
          activity: '🚕 Airport → Hotel Transfer',
          description: 'Transfer to ${destinationHotel.hotelName}. Enjoy scenic city entrance.',
          cost: '\$25-40',
          locationName: destinationHotel.address,
          transport: 'Airport Shuttle / Taxi',
          placeDetails: '45-min transit time',
        ));
        markGridBusy(procEnd, transferEnd, 1);

        // Check if arriving before hotel check-in time
        final hotelCheckInMin = parseTimeToMinutes(destinationHotel.checkInTime.isNotEmpty ? destinationHotel.checkInTime : '03:00 PM');
        if (transferEnd < hotelCheckInMin) {
          // Luggage Storage Drop (30 mins)
          final luggageEnd = transferEnd + 30;
          dayActivities.add(ActivityItem(
            time: minutesToTimeString(transferEnd),
            activity: '💼 Luggage Drop at Hotel',
            description: 'Arrived early before official check-in. Drop luggage at front desk of ${destinationHotel.hotelName}.',
            cost: '-',
            locationName: destinationHotel.address,
            placeDetails: 'Luggage drop settlement',
          ));
          markGridBusy(transferEnd, luggageEnd, 1);
          timelineStartMin = luggageEnd;
          report.conflictsFixed.add("Day ${dayIdx + 1}: Arrived early before check-in. Scheduled luggage storage drop at ${destinationHotel.hotelName}.");

          // Schedule official check-in later
          dayActivities.add(ActivityItem(
            time: minutesToTimeString(hotelCheckInMin),
            activity: '🏨 Hotel Check-in',
            description: '${destinationHotel.hotelName} room key pickup. Room: ${destinationHotel.roomType}',
            cost: '-',
            locationName: destinationHotel.address,
            ticketInfo: destinationHotel.confirmationCode.isNotEmpty ? 'Ref: ${destinationHotel.confirmationCode}' : '',
            placeDetails: 'Check-in processed',
          ));
          markGridBusy(hotelCheckInMin, hotelCheckInMin + 30, 1);
        } else {
          // Check-in immediately
          final checkInEnd = transferEnd + 30;
          dayActivities.add(ActivityItem(
            time: minutesToTimeString(transferEnd),
            activity: '🏨 Hotel Check-in',
            description: '${destinationHotel.hotelName} check-in. Room: ${destinationHotel.roomType}',
            cost: '-',
            locationName: destinationHotel.address,
            ticketInfo: destinationHotel.confirmationCode.isNotEmpty ? 'Ref: ${destinationHotel.confirmationCode}' : '',
            placeDetails: '30-min check-in process',
          ));
          markGridBusy(transferEnd, checkInEnd, 1);
          timelineStartMin = checkInEnd;
        }
      } else {
        // No hotel stay, transfer to city center
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(procEnd),
          activity: '🚕 Airport → City Transfer',
          description: 'Transfer to downtown ${goingFlight.arrivalCity}',
          cost: '\$15-30',
          locationName: goingFlight.arrivalCity,
          transport: 'Metro / Taxi',
          placeDetails: '45-min transit time',
        ));
        markGridBusy(procEnd, transferEnd, 1);
        timelineStartMin = transferEnd;
      }
    } else {
      // Normal start at Hotel or Morning Preparation
      if (dayIdx > 0) {
        if (activeHotelsForPrevNight.isNotEmpty) {
          final prevHotel = activeHotelsForPrevNight.first;
          dayActivities.add(ActivityItem(
            time: '08:00 AM',
            activity: '🌅 Morning at ${prevHotel.hotelName}',
            description: 'Enjoy breakfast and prepare for the day',
            cost: '-',
            locationName: prevHotel.address,
            transport: '-',
            placeDetails: 'Hotel breakfast',
          ));
        } else {
          dayActivities.add(ActivityItem(
            time: '08:00 AM',
            activity: '🌅 Morning Preparation',
            description: 'Prepare for the day ahead',
            cost: '-',
            locationName: '',
            transport: '-',
            placeDetails: 'General start',
          ));
        }
        markGridBusy(480, 540, 1); // block 8 AM to 9 AM for morning prep
        timelineStartMin = 540; // 9:00 AM
      }
    }

    // Hotel Check-out Logistics (e.g. 11:00 AM checkout)
    for (final hotel in checkingOutHotels) {
      final coTimeStr = hotel.checkOutTime.isNotEmpty ? hotel.checkOutTime : '11:00 AM';
      final coMin = parseTimeToMinutes(coTimeStr);

      // Check if there is a hotel change today (both checkout A and checkin B)
      if (checkingInHotels.isNotEmpty) {
        final hotelB = checkingInHotels.first;
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(coMin),
          activity: '🏨 Hotel Check-out',
          description: 'Checkout from ${hotel.hotelName}. Settle final bills.',
          cost: '-',
          locationName: hotel.address,
          placeDetails: '30-min check-out process',
        ));
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(coMin + 30),
          activity: '💼 Packing & Luggage Handling',
          description: 'Organize bags and prepare for transfer to new accommodation.',
          cost: '-',
          placeDetails: 'Packing transition buffer',
        ));
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(coMin + 60),
          activity: '🚕 Hotel-to-Hotel Transfer',
          description: 'Transfer from ${hotel.hotelName} to ${hotelB.hotelName}.',
          cost: '\$15-25',
          locationName: hotelB.address,
          transport: 'Taxi / Metro',
          placeDetails: '30-min travel time',
        ));
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(coMin + 90),
          activity: '💼 Luggage Drop at ${hotelB.hotelName}',
          description: 'Drop bags at front desk of new hotel before check-in.',
          cost: '-',
          locationName: hotelB.address,
          placeDetails: 'Luggage storage drop',
        ));
        markGridBusy(coMin, coMin + 120, 1);
        report.conflictsFixed.add("Day ${dayIdx + 1}: Managed hotel transition from ${hotel.hotelName} to ${hotelB.hotelName}. Reserved 2-hour buffer.");

        // Check-in B is scheduled at its check-in time
        final ciMinB = parseTimeToMinutes(hotelB.checkInTime.isNotEmpty ? hotelB.checkInTime : '03:00 PM');
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(ciMinB),
          activity: '🏨 Hotel Check-in',
          description: '${hotelB.hotelName} check-in. Room: ${hotelB.roomType}',
          cost: '-',
          locationName: hotelB.address,
          ticketInfo: hotelB.confirmationCode.isNotEmpty ? 'Ref: ${hotelB.confirmationCode}' : '',
          placeDetails: 'Check-in process',
        ));
        markGridBusy(ciMinB, ciMinB + 30, 1);
      } else {
        // Simple Checkout (30 mins)
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(coMin),
          activity: '🏨 Hotel Check-out',
          description: 'Checkout from ${hotel.hotelName}. Settle final bills.',
          cost: '-',
          locationName: hotel.address,
          placeDetails: 'Checkout process',
        ));
        markGridBusy(coMin, coMin + 30, 1);
      }
    }

    // Normal Hotel Check-in process if not covered by flight arrival and no hotel change
    if (dayIdx == 0 && !isGoingLandingDay && checkingInHotels.isNotEmpty) {
      for (final hotel in checkingInHotels) {
        final ciTimeStr = hotel.checkInTime.isNotEmpty ? hotel.checkInTime : '03:00 PM';
        final ciMin = parseTimeToMinutes(ciTimeStr);
        dayActivities.add(ActivityItem(
          time: ciTimeStr,
          activity: '🏨 Hotel Check-in',
          description: '${hotel.hotelName} check-in. Room: ${hotel.roomType}',
          cost: '-',
          locationName: hotel.address,
          ticketInfo: hotel.confirmationCode.isNotEmpty ? 'Ref: ${hotel.confirmationCode}' : '',
          placeDetails: '30-min check-in process',
        ));
        markGridBusy(ciMin, ciMin + 30, 1);
      }
    }

    // Departing Flight Logistics (Ensure airport arrival 2.5 hours/165 mins prior)
    int latestDepartureStartMin = 1500;
    if (isReturnDepartureDay && returnFlight != null) {
      final depTimeStr = returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM';
      final depMin = parseTimeToMinutes(depTimeStr);

      latestDepartureStartMin = depMin - 165;

      // Transfer to Airport (45 mins)
      dayActivities.add(ActivityItem(
        time: minutesToTimeString(depMin - 165),
        activity: '🚕 Transfer to Airport',
        description: 'Depart for ${returnFlight.departureCity} Airport (recommended 2 hours prior to flight)',
        cost: '\$25-40',
        locationName: '${returnFlight.departureCity} Airport',
        transport: 'Airport Shuttle / Taxi',
        placeDetails: '45-min airport transfer time',
      ));

      // Check-in & Security (120 mins)
      dayActivities.add(ActivityItem(
        time: minutesToTimeString(depMin - 120),
        activity: '✈️ Airport Check-in & Security',
        description: 'Flight check-in, bag drop, security checks, and gate boarding procedures.',
        cost: '-',
        locationName: '${returnFlight.departureCity} Airport',
        placeDetails: '120-min departure safety buffer',
      ));

      // Flight Departure
      dayActivities.add(ActivityItem(
        time: depTimeStr,
        activity: '✈️ Depart from Airport',
        description: '${returnFlight.airline} departs from ${returnFlight.departureCity}',
        cost: '-',
        locationName: '${returnFlight.departureCity} Airport',
        transport: 'Flight',
        ticketInfo: returnFlight.pnr.isNotEmpty ? 'PNR: ${returnFlight.pnr}' : '',
        placeDetails: '${returnFlight.seatClass} Class',
      ));

      markGridBusy(depMin - 165, 1500, 1);
    }

    // Now, schedule the attractions sequentially in the free slots of the day
    int currentPointerMin = timelineStartMin;
    String lastLocationName = activeHotelsForPrevNight.isNotEmpty 
        ? activeHotelsForPrevNight.first.hotelName 
        : (checkingInHotels.isNotEmpty ? checkingInHotels.first.hotelName : 'Hotel');

    for (final item in dayItems) {
      final duration = item.place.durationMinutes;
      final openMin = item.place.openMinutes;
      final closeMin = item.place.closeMinutes;

      // Desired start time from step 3 scheduling
      final desiredStart = item.startMinutes;

      // Need 30 min transfer buffer to get to the attraction
      int earliestStart = currentPointerMin + 30;
      earliestStart = max(earliestStart, openMin);

      // Search for the first valid timing slot that fits operating hours and avoids conflicts
      int startMin = desiredStart;
      if (startMin < earliestStart) {
        startMin = earliestStart;
      }

      // Check if it fits without overlapping any logistics/flights and stays before departure
      bool slotFound = false;
      final int dayLimit = (item.place.genre == 'Nightlife') ? 1500 : 1380;
      while (startMin + duration <= latestDepartureStartMin && startMin + duration <= dayLimit) {
        // Check if the entire interval [startMin - 30, startMin + duration] is free on the grid
        if (isGridIntervalFree(startMin - 30, startMin + duration) &&
            startMin >= openMin &&
            startMin + duration <= closeMin) {
          slotFound = true;
          break;
        }
        startMin += 15; // check next 15-minute slot
      }

      if (slotFound) {
        // Record conflicts fixed if the time changed
        if (startMin != desiredStart) {
          final oldTimeStr = minutesToTimeString(desiredStart);
          final newTimeStr = minutesToTimeString(startMin);
          report.conflictsFixed.add("Day ${dayIdx + 1}: Shifted '${item.place.name}' from $oldTimeStr to $newTimeStr due to operating hours/logistic overlaps.");
        }

        // Add Transfer Activity (30 mins)
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(startMin - 30),
          activity: '🚕 Transfer to ${item.place.name}',
          description: 'Commute from $lastLocationName to ${item.place.name}.',
          cost: '\$2-10',
          locationName: item.place.address,
          transport: 'Metro / Walking',
          placeDetails: '30-min travel transfer',
        ));
        markGridBusy(startMin - 30, startMin, 2);

        // Add Attraction Activity
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(startMin),
          activity: item.place.name,
          description: item.place.description,
          cost: item.place.estimatedCost,
          locationName: item.place.address,
          suggestedAttire: _suggestAttire(item.place.genre),
          transport: 'Metro / Walking',
          ticketInfo: item.place.estimatedCost == 'Free' ? 'Free Entry' : 'Ticket Required',
          placeDetails: '${item.place.genre} • ${duration}min (${minutesToTimeString(startMin)} – ${minutesToTimeString(startMin + duration)})',
          checked: false,
        ));
        markGridBusy(startMin, startMin + duration, 2);

        currentPointerMin = startMin + duration;
        lastLocationName = item.place.name;
      } else {
        // Could not fit activity, suggest alternative
        report.conflictsFixed.add("Day ${dayIdx + 1}: Skipping '${item.place.name}' due to timeline constraint (moved to Alternative Options).");
      }
    }

    // Return to Hotel / Evening rest if no departing flight
    if (!isReturnDepartureDay) {
      final activeHotel = activeHotelsForNight.isNotEmpty 
          ? activeHotelsForNight.first 
          : (checkingInHotels.isNotEmpty ? checkingInHotels.first : null);

      if (activeHotel != null) {
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(currentPointerMin),
          activity: '🚕 Transfer to Hotel',
          description: 'Commute back to ${activeHotel.hotelName} after a full day of sightseeing.',
          cost: '\$2-8',
          locationName: activeHotel.address,
          transport: 'Taxi / Metro',
          placeDetails: '30-min return transfer',
        ));

        dayActivities.add(ActivityItem(
          time: minutesToTimeString(currentPointerMin + 30),
          activity: '🏨 Return to ${activeHotel.hotelName}',
          description: 'Evening wind-down and dinner nearby accommodation.',
          cost: '-',
          locationName: activeHotel.address,
          placeDetails: 'Evening rest',
        ));
      } else {
        // No hotel stay, show warning block
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(currentPointerMin),
          activity: '⚠️ No hotel booked for tonight',
          description: 'No active stay registered for this night. Tap to search accommodations.',
          cost: 'Urgent',
          locationName: 'Action Required',
          transport: '-',
          placeDetails: 'Missing Booking',
        ));
      }
      // Block the rest of the day from scheduling gaps
      markGridBusy(currentPointerMin, 1500, 1);
    }

    // Scan for free slots
    int freeStart = -1;
    for (int m = timelineStartMin; m < latestDepartureStartMin && m < 1500; m++) {
      if (timeGrid[m] == 0) {
        if (freeStart == -1) {
          freeStart = m;
        }
      } else {
        if (freeStart != -1) {
          final duration = m - freeStart;
          if (duration >= 15) {
            dayActivities.add(ActivityItem(
              time: minutesToTimeString(freeStart),
              activity: '✨ Free Time Available',
              description: 'You have some open hours here. Go to Step 3 Day Planner to schedule a place.',
              cost: 'free-slot', // marker
              placeDetails: 'Duration: $duration mins (${minutesToTimeString(freeStart)} – ${minutesToTimeString(m)})',
            ));
          }
          freeStart = -1;
        }
      }
    }
    if (freeStart != -1) {
      final endBound = min(latestDepartureStartMin, 1500);
      final duration = endBound - freeStart;
      if (duration >= 15) {
        dayActivities.add(ActivityItem(
          time: minutesToTimeString(freeStart),
          activity: '✨ Free Time Available',
          description: 'You have some open hours here. Go to Step 3 Day Planner to schedule a place.',
          cost: 'free-slot', // marker
          placeDetails: 'Duration: $duration mins (${minutesToTimeString(freeStart)} – ${minutesToTimeString(endBound)})',
        ));
      }
    }

    // Sort all day activities chronologically
    dayActivities.sort((a, b) => parseTimeToMinutes(a.time).compareTo(parseTimeToMinutes(b.time)));
    resolvedDays.add(dayActivities);
  }

  return ResolvedItineraryResult(
    resolvedDays: resolvedDays,
    report: report,
  );
}

String _suggestAttire(String genre) {
  switch (genre) {
    case 'Religious':
      return 'Modest clothing, shoulders covered';
    case 'Adventure':
      return 'Comfortable activewear, sturdy shoes';
    case 'Summer & Beach':
      return 'Swimwear, sunscreen, hat';
    case 'Nightlife':
      return 'Smart casual, comfortable shoes';
    case 'Culture & History':
      return 'Smart casual, comfortable walking shoes';
    case 'Shopping':
      return 'Comfortable walking shoes, layered clothing';
    default:
      return 'Casual comfortable clothing';
  }
}

/// Calculates the earliest start time of the day for activities (considering flights/customs/transfers/luggage drops)
int getDayEarliestStart(int dayIdx, TripBookings bookings) {
  final baseStart = getBaseStartDate(bookings);
  final dayDate = baseStart.add(Duration(days: dayIdx));
  final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

  final goingFlight = getGoingFlight(bookings);
  final returnFlight = getReturnFlight(bookings);

  final goingLanding = goingFlight != null 
      ? parseFlightDateTime(goingFlight.arrivalDate.isNotEmpty ? goingFlight.arrivalDate : goingFlight.departureDate, goingFlight.arrivalTime.isNotEmpty ? goingFlight.arrivalTime : '10:00 AM')
      : null;
  final returnDeparture = returnFlight != null
      ? parseFlightDateTime(returnFlight.departureDate, returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM')
      : null;

  final isBeforeGoing = goingLanding != null &&
      DateTime(dayDate.year, dayDate.month, dayDate.day).isBefore(DateTime(goingLanding.year, goingLanding.month, goingLanding.day));

  final isAfterReturn = returnDeparture != null &&
      DateTime(dayDate.year, dayDate.month, dayDate.day).isAfter(DateTime(returnDeparture.year, returnDeparture.month, returnDeparture.day));

  if (isBeforeGoing || isAfterReturn) {
    return 1500; // Blocked day
  }

  final isGoingLandingDay = goingLanding != null &&
      dayDate.year == goingLanding.year &&
      dayDate.month == goingLanding.month &&
      dayDate.day == goingLanding.day;

  if (isGoingLandingDay && goingFlight != null) {
    final arrivalTimeStr = goingFlight.arrivalTime.isNotEmpty ? goingFlight.arrivalTime : '10:00 AM';
    final arrMin = parseTimeToMinutes(arrivalTimeStr);
    
    // Arrival timeline: lands at arrMin.
    // 60-min processing + 45-min transit = 105 mins.
    int earliestStartMin = arrMin + 105;
    
    final checkingInHotels = bookings.hotels.where((h) => h.checkInDate == dateStr).toList();
    final activeHotelsForNight = bookings.hotels.where((h) {
      try {
        final checkIn = DateTime.parse(h.checkInDate);
        final checkOut = DateTime.parse(h.checkOutDate);
        final dDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
        final ci = DateTime(checkIn.year, checkIn.month, checkIn.day);
        final co = DateTime(checkOut.year, checkOut.month, checkOut.day);
        return (dDate.isAtSameMomentAs(ci) || dDate.isAfter(ci)) && dDate.isBefore(co);
      } catch (_) {
        return false;
      }
    }).toList();

    final destinationHotel = checkingInHotels.isNotEmpty 
        ? checkingInHotels.first 
        : (activeHotelsForNight.isNotEmpty ? activeHotelsForNight.first : null);
        
    if (destinationHotel != null) {
      final hotelCheckInMin = parseTimeToMinutes(destinationHotel.checkInTime.isNotEmpty ? destinationHotel.checkInTime : '03:00 PM');
      if (arrMin + 105 < hotelCheckInMin) {
        // Needs 30-min luggage drop, earliest start is arrMin + 135 mins
        earliestStartMin = arrMin + 135;
      }
    }
    return earliestStartMin;
  }
  
  return 540; // 09:00 AM default start for normal days
}

/// Checks a raw list of DayScheduleItems for conflicts against bookings and returns a map of placeId -> List of warnings
Map<String, List<String>> validateDayScheduleItems(int dayIdx, List<DayScheduleItem> dayItems, TripBookings bookings) {
  final Map<String, List<String>> warnings = {};
  
  if (dayItems.isEmpty) return warnings;

  // Sort items by scheduled time just in case
  final sortedItems = List<DayScheduleItem>.from(dayItems)
    ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  final baseStart = getBaseStartDate(bookings);
  final dayDate = baseStart.add(Duration(days: dayIdx));
  final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

  final checkingInHotels = bookings.hotels.where((h) => h.checkInDate == dateStr).toList();
  final checkingOutHotels = bookings.hotels.where((h) => h.checkOutDate == dateStr).toList();

  // Active hotels for the night
  final activeHotelsForNight = bookings.hotels.where((h) {
    try {
      final checkIn = DateTime.parse(h.checkInDate);
      final checkOut = DateTime.parse(h.checkOutDate);
      final dDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final ci = DateTime(checkIn.year, checkIn.month, checkIn.day);
      final co = DateTime(checkOut.year, checkOut.month, checkOut.day);
      return (dDate.isAtSameMomentAs(ci) || dDate.isAfter(ci)) && dDate.isBefore(co);
    } catch (_) {
      return false;
    }
  }).toList();

  final goingFlight = getGoingFlight(bookings);
  final returnFlight = getReturnFlight(bookings);

  final goingLanding = goingFlight != null 
      ? parseFlightDateTime(goingFlight.arrivalDate.isNotEmpty ? goingFlight.arrivalDate : goingFlight.departureDate, goingFlight.arrivalTime.isNotEmpty ? goingFlight.arrivalTime : '10:00 AM')
      : null;
  final returnDeparture = returnFlight != null
      ? parseFlightDateTime(returnFlight.departureDate, returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM')
      : null;

  final isBeforeGoingDay = goingLanding != null &&
      DateTime(dayDate.year, dayDate.month, dayDate.day).isBefore(DateTime(goingLanding.year, goingLanding.month, goingLanding.day));

  final isAfterReturnDay = returnDeparture != null &&
      DateTime(dayDate.year, dayDate.month, dayDate.day).isAfter(DateTime(returnDeparture.year, returnDeparture.month, returnDeparture.day));

  // If the day is completely outside flight dates:
  if (isBeforeGoingDay && goingFlight != null) {
    for (final item in sortedItems) {
      warnings.putIfAbsent(item.place.id, () => []).add(
        'Starts before going flight lands (Going flight lands on ${goingFlight.arrivalDate} at ${goingFlight.arrivalTime})'
      );
    }
  }

  if (isAfterReturnDay && returnFlight != null) {
    for (final item in sortedItems) {
      warnings.putIfAbsent(item.place.id, () => []).add(
        'Scheduled after return flight departs (Return flight departed on ${returnFlight.departureDate} at ${returnFlight.departureTime})'
      );
    }
  }

  // 1. Check flight arrival on landing day
  final isGoingLandingDay = goingLanding != null &&
      dayDate.year == goingLanding.year &&
      dayDate.month == goingLanding.month &&
      dayDate.day == goingLanding.day;

  if (isGoingLandingDay && goingFlight != null) {
    final arrivalTimeStr = goingFlight.arrivalTime.isNotEmpty ? goingFlight.arrivalTime : '10:00 AM';
    final arrMin = parseTimeToMinutes(arrivalTimeStr);
    
    // Arrival timeline: lands at arrMin.
    // 60-min processing + 45-min transit = 105 mins.
    int earliestStartMin = arrMin + 105;
    
    final destinationHotel = checkingInHotels.isNotEmpty 
        ? checkingInHotels.first 
        : (activeHotelsForNight.isNotEmpty ? activeHotelsForNight.first : null);
        
    if (destinationHotel != null) {
      final hotelCheckInMin = parseTimeToMinutes(destinationHotel.checkInTime.isNotEmpty ? destinationHotel.checkInTime : '03:00 PM');
      if (arrMin + 105 < hotelCheckInMin) {
        // Needs 30-min luggage drop, earliest start is arrMin + 135 mins
        earliestStartMin = arrMin + 135;
      }
    }
    
    for (final item in sortedItems) {
      if (item.startMinutes < earliestStartMin) {
        warnings.putIfAbsent(item.place.id, () => []).add(
          'Starts before going flight lands & clears customs (Lands: ${goingFlight.arrivalTime})'
        );
      }
    }
  }

  // 2. Check hotel checkout transition
  for (final hotel in checkingOutHotels) {
    final coTimeStr = hotel.checkOutTime.isNotEmpty ? hotel.checkOutTime : '11:00 AM';
    final coMin = parseTimeToMinutes(coTimeStr);
    
    final isHotelChange = checkingInHotels.isNotEmpty;
    final transitionStart = coMin;
    final transitionEnd = isHotelChange ? coMin + 120 : coMin + 30;
    
    for (final item in sortedItems) {
      if (item.startMinutes < transitionEnd && item.endMinutes > transitionStart) {
        final label = isHotelChange 
            ? 'Overlaps with hotel change window (${minutesToTimeString(transitionStart)} - ${minutesToTimeString(transitionEnd)})'
            : 'Overlaps with checkout process (${minutesToTimeString(transitionStart)} - ${minutesToTimeString(transitionEnd)})';
        warnings.putIfAbsent(item.place.id, () => []).add(label);
      }
    }
  }

  // 3. Check flight departure on return day
  final isReturnDepartureDay = returnDeparture != null &&
      dayDate.year == returnDeparture.year &&
      dayDate.month == returnDeparture.month &&
      dayDate.day == returnDeparture.day;

  if (isReturnDepartureDay && returnFlight != null) {
    final depTimeStr = returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM';
    final depMin = parseTimeToMinutes(depTimeStr);
    final bufferStartMin = depMin - 165; // 45-min transit + 120-min processing

    for (final item in sortedItems) {
      if (item.endMinutes > bufferStartMin) {
        warnings.putIfAbsent(item.place.id, () => []).add(
          'Overlaps with return airport departure buffer (Must leave by ${minutesToTimeString(bufferStartMin)})'
        );
      }
    }
  }

  // 4. Check attraction operating hours
  for (final item in sortedItems) {
    final openMin = item.place.openMinutes;
    final closeMin = item.place.closeMinutes;
    
    if (item.startMinutes < openMin) {
      warnings.putIfAbsent(item.place.id, () => []).add(
        'Attraction is closed. Opens at ${minutesToTimeString(openMin)}'
      );
    }
    if (item.endMinutes > closeMin) {
      warnings.putIfAbsent(item.place.id, () => []).add(
        'Attraction is closed. Closes at ${minutesToTimeString(closeMin)}'
      );
    }
  }

  // 5. Check overlaps and mutual travel buffer (30 mins)
  for (int i = 0; i < sortedItems.length; i++) {
    final current = sortedItems[i];
    
    // Check overlap with next items
    for (int j = i + 1; j < sortedItems.length; j++) {
      final next = sortedItems[j];
      if (current.startMinutes < next.endMinutes && next.startMinutes < current.endMinutes) {
        warnings.putIfAbsent(current.place.id, () => []).add('Overlaps with ${next.place.name}');
        warnings.putIfAbsent(next.place.id, () => []).add('Overlaps with ${current.place.name}');
      }
    }
    
    // Check travel buffer (30 mins)
    if (i > 0) {
      final prev = sortedItems[i - 1];
      if (current.startMinutes < prev.endMinutes + 30) {
        warnings.putIfAbsent(current.place.id, () => []).add(
          'Less than 30 mins travel buffer from ${prev.place.name}'
        );
      }
    }
  }

  return warnings;
}

