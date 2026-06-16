import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';
import '../core/utils/sound_synthesizer.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  // Active currency selected by the traveler: 'USD', 'INR', 'JPY'
  String _selectedCurrency = 'USD';

  // Manual entry controllers
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  String _selectedCategory = 'Local Dine-Out';

  // Smart savings recommendation states
  bool _commuteOptimized = false;
  bool _attractionsOptimized = false;
  bool _dineOptimized = false;

  // Currency Converter states (lower section)
  final TextEditingController _convInputCtrl = TextEditingController(text: '100');
  String _fromCurrency = 'USD';
  bool _taxFreeReduction = false;

  final List<String> _categories = [
    'Flights & Transit',
    'Bed & Hotels',
    'Local Dine-Out',
    'Metros & Taxis',
    'Sightseeing & Shows',
    'Souvenirs & Anime'
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _convInputCtrl.dispose();
    super.dispose();
  }

  // Normalizes old/different categories to standard ones
  String _normalizeCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('flight') || c.contains('transit')) return 'Flights & Transit';
    if (c.contains('hotel') || c.contains('bed') || c.contains('lodging')) return 'Bed & Hotels';
    if (c.contains('dine') || c.contains('food') || c.contains('ramen')) return 'Local Dine-Out';
    if (c.contains('metro') || c.contains('taxi') || c.contains('commute') || c.contains('Prepaid Transit Pass')) return 'Metros & Taxis';
    if (c.contains('sightseeing') || c.contains('show') || c.contains('activity') || c.contains('ticket')) return 'Sightseeing & Shows';
    if (c.contains('souvenir') || c.contains('anime') || c.contains('shopping') || c.contains('manga')) return 'Souvenirs & Anime';
    return 'Souvenirs & Anime'; // default fallback
  }

  // Smart categorizer for itinerary activities based on titles/descriptions
  String _getActivityCategory(ActivityItem act) {
    final name = act.activity.toLowerCase();
    final transport = act.transport.toLowerCase();

    if (name.contains('flight') || name.contains('airport')) {
      return 'Flights & Transit';
    }
    if (name.contains('capsule') || name.contains('hotel') || name.contains('stay') || name.contains('check-in') || name.contains('lodging')) {
      return 'Bed & Hotels';
    }
    if (name.contains('ramen') || name.contains('food') || name.contains('dine') || name.contains('dinner') || name.contains('lunch') || name.contains('eat') || name.contains('traditional tavern')) {
      return 'Local Dine-Out';
    }
    if (name.contains('metro') || name.contains('subway') || name.contains('taxi') || name.contains('transit') || name.contains('train') || name.contains('line') || transport.contains('train') || transport.contains('subway')) {
      return 'Metros & Taxis';
    }
    if (name.contains('shop') || name.contains('souvenir') || name.contains('anime') || name.contains('broadway') || name.contains('figure') || name.contains('purchase')) {
      return 'Souvenirs & Anime';
    }
    return 'Sightseeing & Shows';
  }

  // Get spent in Category: Ledger items + Itinerary activities cost
  double _getCategorySpent(List<TravelExpense> expenses, List<ItineraryDay> itinerary, String targetCat) {
    double sum = 0.0;
    
    // 1. Sum up matching ledger expenses
    for (var exp in expenses) {
      if (_normalizeCategory(exp.category) == targetCat) {
        sum += exp.amount;
      }
    }

    // 2. Sum up matching activities cost from the itinerary
    for (var day in itinerary) {
      for (var act in day.activities) {
        if (_getActivityCategory(act) == targetCat) {
          sum += act.usdCost;
        }
      }
    }

    return sum;
  }

  // Get total limit per category (defined in spec)
  double _getCategoryLimit(String cat) {
    switch (cat) {
      case 'Flights & Transit':
        return 650.0;
      case 'Bed & Hotels':
        return 450.0;
      case 'Local Dine-Out':
        return 200.0;
      case 'Metros & Taxis':
        return 100.0;
      case 'Sightseeing & Shows':
        return 80.0;
      case 'Souvenirs & Anime':
        return 120.0;
      default:
        return 100.0;
    }
  }

  // Emoji helper for categories
  String _getCategoryEmoji(String cat) {
    switch (cat) {
      case 'Flights & Transit':
        return 'âœˆï¸';
      case 'Bed & Hotels':
        return 'ðŸ¨';
      case 'Local Dine-Out':
        return 'ðŸœ';
      case 'Metros & Taxis':
        return 'ðŸš‡';
      case 'Sightseeing & Shows':
        return 'â›©ï¸';
      case 'Souvenirs & Anime':
        return 'ðŸ›ï¸';
      default:
        return 'ðŸ’°';
    }
  }

  // Exchange rates configurations
  double get _exchangeRate {
    if (_selectedCurrency == 'INR') return 83.0;
    if (_selectedCurrency == 'JPY') return 155.0;
    return 1.0;
  }

  String get _currencySymbol {
    if (_selectedCurrency == 'INR') return 'â‚¹';
    if (_selectedCurrency == 'JPY') return 'Â¥';
    return '\$';
  }

  // Formats currency string with appropriate commas and zero decimals
  String _formatCurrency(double usdAmount) {
    final converted = usdAmount * _exchangeRate;
    final intVal = converted.round();
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$_currencySymbol$formatted';
  }

  double _getConversionRate(String from) {
    if (from == 'USD') return 155.0; // 1 USD = 155 JPY
    if (from == 'EUR') return 168.0; // 1 EUR = 168 JPY
    if (from == 'INR') return 1.86;  // 1 INR = 1.86 JPY
    if (from == 'GBP') return 198.0; // 1 GBP = 198 JPY
    return 1.0;
  }

  // Show detailed logs of matching items inside a category bottom drawer
  void _showCategoryLogs(String categoryName, List<TravelExpense> expenses, List<ItineraryDay> itinerary) {
    final matchingExpenses = expenses.where((e) => _normalizeCategory(e.category) == categoryName).toList();
    final matchingActivities = <ActivityItem>[];
    for (var day in itinerary) {
      for (var act in day.activities) {
        if (_getActivityCategory(act) == categoryName && act.usdCost > 0) {
          matchingActivities.add(act);
        }
      }
    }

    SoundSynthesizer.playTone(
      frequency: 600,
      durationSeconds: 0.1,
      name: 'drawer.wav',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Text(_getCategoryEmoji(categoryName), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Category Ledger Breakdown & Allocations',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Color(0xFF334155), height: 32),
              
              // Contents
              Expanded(
                child: (matchingExpenses.isEmpty && matchingActivities.isEmpty)
                    ? const Center(
                        child: Text(
                          'No entries recorded in this category.',
                          style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      )
                    : ListView(
                        children: [
                          if (matchingExpenses.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0, top: 4.0),
                              child: Text('MANUAL EXPENSE LEDGER', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                            ...matchingExpenses.map((exp) => _buildLogTile(
                              title: exp.label,
                              subtitle: '${exp.category} â€¢ ${exp.date}',
                              usdAmount: exp.amount,
                              isItinerary: false,
                              onDelete: () {
                                ref.read(expensesProvider.notifier).removeExpense(exp.id);
                                Navigator.pop(context);
                              },
                            )),
                            const SizedBox(height: 16),
                          ],
                          if (matchingActivities.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text('GROUNDED ITINERARY ACTIVITIES', style: TextStyle(color: Color(0xFF06D6A0), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                            ...matchingActivities.map((act) => _buildLogTile(
                              title: act.activity,
                              subtitle: '${act.locationName} â€¢ Scheduled',
                              usdAmount: act.usdCost,
                              isItinerary: true,
                            )),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              // Close
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss Ledger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogTile({
    required String title,
    required String subtitle,
    required double usdAmount,
    required bool isItinerary,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isItinerary ? const Color(0xFF065F46) : const Color(0xFF0A1628),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isItinerary ? Icons.calendar_month : Icons.receipt_long,
              color: isItinerary ? const Color(0xFF34D399) : const Color(0xFFC7D2FE),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatCurrency(usdAmount),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var spent = ref.watch(totalSpentProvider);
    final ceiling = ref.watch(budgetCeilingProvider);
    final expenses = ref.watch(expensesProvider);
    final itinerary = ref.watch(itineraryProvider);

    // Apply Smart Savings deductions dynamically to simulate savings in real-time
    double savingsOffset = 0.0;
    if (_commuteOptimized) savingsOffset += 25.0;
    if (_attractionsOptimized) savingsOffset += 35.0;
    if (_dineOptimized) savingsOffset += 15.0;

    spent = (spent - savingsOffset).clamp(0.0, double.infinity);

    final spentPercentage = ceiling > 0 ? spent / ceiling : 0.0;
    final leftover = (ceiling - spent).clamp(0.0, double.infinity);

    // Dynamic Converter values (lower card)
    final inputVal = double.tryParse(_convInputCtrl.text) ?? 0.0;
    final rawJpy = inputVal * _getConversionRate(_fromCurrency);
    final jpyOutput = _taxFreeReduction ? rawJpy * 0.9 : rawJpy;
    final taxSavings = _taxFreeReduction ? rawJpy * 0.1 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2744),
        elevation: 0,
        title: const Text(
          'Intelligent Budget Planner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header Intro
            const Text(
              'Intelligent Budget Planner',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'Dynamic currency conversions, category target checks, and localized cost suggestions personalized for your travel style.',
              style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 18),

            // 1. Display Currency Selector Card
            _buildCurrencySelectorCard(),
            const SizedBox(height: 16),

            // 2. Overall Spending Rate Circular Progress Card
            _buildOverallSpendingCard(spent, ceiling, leftover, spentPercentage),
            const SizedBox(height: 16),

            // 3. Category-wise Allocations Progress Meters
            _buildCategoryAllocationsCard(expenses, itinerary),
            const SizedBox(height: 16),

            // 4. Add Custom Entry Ledger Form
            _buildAddCustomEntryCard(),
            const SizedBox(height: 16),

            // 5. Aira Smart Savings Section
            _buildSmartSavingsCard(),
            const SizedBox(height: 16),

            // 6. Smart Currency Converter (Legacy Integration)
            _buildLegacyConverterCard(jpyOutput, taxSavings),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 1. Currency Selector
  Widget _buildCurrencySelectorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DISPLAY CURRENCY',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildCurrencyPill('USD', 'USD (\$)'),
                _buildCurrencyPill('INR', 'INR (â‚¹)'),
                _buildCurrencyPill('JPY', 'JPY (Â¥)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPill(String code, String label) {
    final isSelected = _selectedCurrency == code;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          SoundSynthesizer.playTone(
            frequency: 700,
            durationSeconds: 0.08,
            name: 'currency_click.wav',
          );
          setState(() {
            _selectedCurrency = code;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF334155) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  // 2. Overall Spending Card
  Widget _buildOverallSpendingCard(double spent, double ceiling, double leftover, double spentPercentage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OVERALL SPENDING RATE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Target Ceiling vs. Expended',
                    style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${(spentPercentage * 100).toInt()}% Spent',
                style: TextStyle(
                  color: spent > ceiling ? const Color(0xFFEF4444) : const Color(0xFF00B4D8),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Circular Indicator on Left
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: spentPercentage.clamp(0.0, 1.0),
                      strokeWidth: 9.5,
                      backgroundColor: const Color(0xFF334155),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        spent > ceiling ? const Color(0xFFEF4444) : const Color(0xFF00B4D8),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LEFTOVER',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(leftover),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(width: 24),
              // Stats on Right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL EXPENDED',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(spent),
                      style: TextStyle(
                        color: spent > ceiling ? const Color(0xFFEF4444) : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'TARGET CEILING',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(ceiling),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // 3. Category Allocations List Card
  Widget _buildCategoryAllocationsCard(List<TravelExpense> expenses, List<ItineraryDay> itinerary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATEGORY-WISE ALLOCATIONS',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          ..._categories.map((cat) {
            double catSpent = _getCategorySpent(expenses, itinerary, cat);
            // Apply simulated offsets from Smart Savings tips
            if (cat == 'Metros & Taxis' && _commuteOptimized) {
              catSpent = (catSpent - 25.0).clamp(0.0, double.infinity);
            }
            if (cat == 'Sightseeing & Shows' && _attractionsOptimized) {
              catSpent = (catSpent - 35.0).clamp(0.0, double.infinity);
            }
            if (cat == 'Local Dine-Out' && _dineOptimized) {
              catSpent = (catSpent - 15.0).clamp(0.0, double.infinity);
            }

            final limit = _getCategoryLimit(cat);
            final ratio = limit > 0 ? (catSpent / limit).clamp(0.0, 1.0) : 0.0;
            final isOver = catSpent > limit;
            final isNear = (catSpent / limit) >= 0.85 && !isOver;

            Color barColor = const Color(0xFF00B4D8); // Indigo-300 default
            if (isOver) {
              barColor = const Color(0xFFEF4444); // Red
            } else if (isNear) {
              barColor = const Color(0xFFF97316); // Orange
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showCategoryLogs(cat, expenses, itinerary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getCategoryEmoji(cat),
                              style: const TextStyle(fontSize: 14.5),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (isOver) ...[
                              const SizedBox(width: 6),
                              // Warning Siren Badge (Pulsing style)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7F1D1D),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFEF4444)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.notifications_active, color: Color(0xFFFCA5A5), size: 10),
                                    SizedBox(width: 2),
                                    Text(
                                      'OVERLIMIT',
                                      style: TextStyle(
                                        color: Color(0xFFFCA5A5),
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
                        Text(
                          '${_formatCurrency(catSpent)} / ${_formatCurrency(limit)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isOver
                                ? const Color(0xFFEF4444)
                                : (isNear ? const Color(0xFFF97316) : const Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: const Color(0xFF0A1628),
                        color: barColor,
                        minHeight: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 4. Add Custom Entry Ledger Form
  Widget _buildAddCustomEntryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADD CUSTOM ENTRY',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          
          // Form Row: Description & Amount
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _descCtrl,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Souvenir description...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                      filled: true,
                      fillColor: const Color(0xFF0A1628),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: '$_currencySymbol ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00B4D8)),
                      hintText: 'Amount',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                      filled: true,
                      fillColor: const Color(0xFF0A1628),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Category Pickers (Pills)
          const Text(
            'SELECT LEDGER CATEGORY',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0A1628),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(_getCategoryEmoji(cat), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF00B4D8),
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Add button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _executeAddExpense,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
              label: const Text(
                'Add Ledger Entry',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executeAddExpense() {
    final amt = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid expense amount.')),
      );
      return;
    }

    // Convert display currency amount back to USD base logic for ledger
    final usdAmount = amt / _exchangeRate;

    ref.read(expensesProvider.notifier).addExpense(TravelExpense(
      id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      category: _selectedCategory,
      amount: usdAmount,
      label: _descCtrl.text.isNotEmpty ? _descCtrl.text : 'Custom $_selectedCategory',
      date: '2026-06-04',
    ));

    // Sound effect: Mario coin B5 to E6 chime sweep!
    SoundSynthesizer.playTone(
      frequency: 987.77,
      endFrequency: 1318.51,
      durationSeconds: 0.15,
      name: 'coin.wav',
    );

    _descCtrl.clear();
    _amountCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added expense in category $_selectedCategory!'),
        backgroundColor: const Color(0xFF06D6A0),
      ),
    );
  }

  // 5. Aira Smart Savings Section
  Widget _buildSmartSavingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628), // Indigo 950
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF312E81)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFF4338CA), shape: BoxShape.circle),
                child: const Icon(Icons.star, color: Color(0xFFFCD34D), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Aira Smart Savings',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Because you are a Solo Traveler opting for a Mid-range scale:',
            style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Color(0xFF312E81), height: 20),

          // Tip 1: Commute
          _buildSavingTipRow(
            title: 'Alternative Commute',
            description: 'Use Tokyo local commuter trains instead of Narita Express and save up to \$25.',
            isApplied: _commuteOptimized,
            icon: Icons.subway_outlined,
            onAction: () {
              SoundSynthesizer.playUnlockChime();
              setState(() {
                _commuteOptimized = !_commuteOptimized;
              });
            },
          ),
          const Divider(color: Color(0xFF312E81), height: 16),

          // Tip 2: Attractions
          _buildSavingTipRow(
            title: 'Low-Cost Attractions',
            description: 'Visit the panoramic Metropolitan Gov Building observatory for public free access (Saves \$35 in ticket fees!).',
            isApplied: _attractionsOptimized,
            icon: Icons.apartment_outlined,
            actionLabel: 'View Map',
            onAction: () {
              SoundSynthesizer.playTone(frequency: 800, durationSeconds: 0.1, name: 'nav_click.wav');
              // Navigate to map
              ref.read(currentTabProvider.notifier).state = 2; // Route to Trips (Itinerary maps are accessed here)
              context.push('/navigation');
            },
            onOptimize: () {
              SoundSynthesizer.playUnlockChime();
              setState(() {
                _attractionsOptimized = !_attractionsOptimized;
              });
            },
          ),
          const Divider(color: Color(0xFF312E81), height: 16),

          // Tip 3: Dine
          _buildSavingTipRow(
            title: 'Dine Economy',
            description: 'Pivot to West Central Tokyo Nostalgic Food Alley street-food blocks for ramen saving up to \$15 per dine.',
            isApplied: _dineOptimized,
            icon: Icons.restaurant_outlined,
            onAction: () {
              SoundSynthesizer.playUnlockChime();
              setState(() {
                _dineOptimized = !_dineOptimized;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSavingTipRow({
    required String title,
    required String description,
    required bool isApplied,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onOptimize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00B4D8), size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            const Spacer(),
            // Optimization toggle
            GestureDetector(
              onTap: onOptimize ?? onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isApplied ? const Color(0xFF06D6A0) : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isApplied) const Icon(Icons.check, color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      isApplied ? 'Applied' : 'Optimize',
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1628),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF312E81)),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 9.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ]
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26.0),
          child: Text(
            description,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, height: 1.35),
          ),
        ),
      ],
    );
  }

  // 6. Smart Currency Converter (Legacy Card Integration)
  Widget _buildLegacyConverterCard(double jpyOutput, double taxSavings) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMART CURRENCY CONVERTER',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _convInputCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Amount',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF0A1628),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _fromCurrency,
                    dropdownColor: const Color(0xFF1A2744),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    onChanged: (v) {
                      setState(() => _fromCurrency = v!);
                    },
                    items: ['USD', 'EUR', 'INR', 'GBP'].map((str) {
                      return DropdownMenuItem(
                        value: str,
                        child: Text(str),
                      );
                    }).toList(),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          
          // Tax Free Checkbox
          CheckboxListTile(
            title: const Text(
              'Include JPY Tax-Free Shopping (10% discount)',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
            ),
            value: _taxFreeReduction,
            activeColor: const Color(0xFF2563EB),
            onChanged: (v) => setState(() => _taxFreeReduction = v!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 6),

          // Output Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JAPANESE YEN (JPY) VALUE',
                  style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Â¥${jpyOutput.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF00B4D8)),
                ),
                if (_taxFreeReduction) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF06D6A0), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Tax Savings: Â¥${taxSavings.round()} (10% saved)',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF06D6A0), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
