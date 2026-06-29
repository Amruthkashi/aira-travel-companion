import 'dart:async';

import 'package:flutter/material.dart';

import '../models/hotel_place.dart';
import '../services/geoapify_service.dart';

class HotelSearchField extends StatefulWidget {
  const HotelSearchField({
    super.key,
    required this.controller,
    required this.onHotelSelected,
    this.label = 'Hotel Name',
  });

  final TextEditingController controller;
  final ValueChanged<HotelPlace> onHotelSelected;
  final String label;

  @override
  State<HotelSearchField> createState() => _HotelSearchFieldState();
}

class _HotelSearchFieldState extends State<HotelSearchField> {
  final GeoapifyService _geoapifyService = GeoapifyService();
  Timer? _debounce;
  List<HotelPlace> _suggestions = const [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _geoapifyService.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(value);
    });
  }

  Future<void> _search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _isLoading = false;
        _errorMessage = null;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results = await _geoapifyService.searchHotels(trimmedQuery);
      if (!mounted || widget.controller.text.trim() != trimmedQuery) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _isLoading = false;
        _errorMessage = error is GeoapifyException
            ? error.message
            : 'Unable to search hotels. Please try again.';
      });
    }
  }

  void _selectHotel(HotelPlace hotel) {
    _debounce?.cancel();
    widget.controller.text = hotel.name;
    setState(() {
      _suggestions = const [];
      _errorMessage = null;
      _hasSearched = false;
    });
    widget.onHotelSelected(hotel);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
              fontSize: 9.5,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.controller,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'e.g. Park Hyatt Tokyo',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    )
                  : widget.controller.text.isEmpty
                      ? const Icon(Icons.search, color: Color(0xFF2563EB), size: 16)
                      : IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                          onPressed: () {
                            widget.controller.clear();
                            _onQueryChanged('');
                            setState(() {});
                          },
                        ),
              filled: true,
              fillColor: const Color(0xFF1A2744),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
            onChanged: (value) {
              setState(() {});
              _onQueryChanged(value);
            },
          ),
          _HotelSearchResults(
            isLoading: _isLoading,
            hasSearched: _hasSearched,
            errorMessage: _errorMessage,
            suggestions: _suggestions,
            onSelected: _selectHotel,
          ),
        ],
      ),
    );
  }
}

class _HotelSearchResults extends StatelessWidget {
  const _HotelSearchResults({
    required this.isLoading,
    required this.hasSearched,
    required this.errorMessage,
    required this.suggestions,
    required this.onSelected,
  });

  final bool isLoading;
  final bool hasSearched;
  final String? errorMessage;
  final List<HotelPlace> suggestions;
  final ValueChanged<HotelPlace> onSelected;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return _SearchStateMessage(
        icon: Icons.error_outline,
        message: errorMessage!,
      );
    }

    if (!isLoading && hasSearched && suggestions.isEmpty) {
      return const _SearchStateMessage(
        icon: Icons.search_off_outlined,
        message: 'No hotels found.',
      );
    }

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF334155)),
          itemBuilder: (context, index) {
            final hotel = suggestions[index];
            return Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.place, color: Color(0xFFA78BFA), size: 16),
                title: Text(
                  hotel.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  hotel.formattedAddress,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onSelected(hotel),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchStateMessage extends StatelessWidget {
  const _SearchStateMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        border: Border.all(color: const Color(0xFF334155)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
