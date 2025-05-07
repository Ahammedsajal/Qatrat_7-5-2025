// currency_converter.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Returns the currency symbol for a given [code].
String currencySymbol(String code) {
  switch (code) {
    case 'QAR':
      return 'ر.ق';
    case 'SAR':
      return 'ر.س';
    case 'AED':
      return 'د.إ';
    case 'KWT':
      return 'د.ك';
    case 'OMN':
      return 'ر.ع.';
    case 'USD':
      return '\$';
    default:
      return ''; // Returns an empty string if code is not provided or unknown.
  }
}
// ░░░ 1. MANUAL-RATE SERVICE  ░░░ (keep as is, just fix codes)
class CurrencyService {
  final Map<String, double> _manualRates = const {
    'QAR': 1.0,
    'SAR': 0.98,
    'AED': 0.99,
    'KWD': 0.07,   // <- fixed ISO code
    'OMR': 0.11,   // <- fixed ISO code
    'USD': 0.27,
  };

  Future<Map<String, double>> fetchRates() async => _manualRates;
}


// ░░░ 2. OPTIONAL PROVIDER  ░░░ still declared here so old code compiles
class CurrencyProvider extends ChangeNotifier {
  final CurrencyService _service = CurrencyService();
  Map<String, double> _rates = const {'QAR': 1.0};
  String _selectedCurrency = 'QAR';

  Map<String, double> get rates              => _rates;
  String                 get selectedCurrency => _selectedCurrency;
  double                 get rate            => _rates[_selectedCurrency] ?? 1.0;

  CurrencyProvider() {
    _loadRates();
  }

  Future<void> _loadRates() async {
    // never throws
    _rates = await _service.fetchRates();
    notifyListeners();
  }

  void changeCurrency(String code) {
    _selectedCurrency = code;
    notifyListeners();
  }

  double convertPrice(double qPrice) => qPrice * rate;
}

// ░░░ 3. SAFE buildConvertedPrice  ░░░ (no null-bangs, no Provider required)
Widget buildConvertedPrice(
  BuildContext context,
  double basePrice, {
  bool isOriginal = false,
  TextStyle? style,
}) {
  CurrencyProvider? prov;
  try {
    // Try to get a provider from context; ignore if it’s not there
    prov = Provider.of<CurrencyProvider>(context, listen: false);
  } catch (_) {}

  final String code   = prov?.selectedCurrency ?? 'QAR';
  final double rate   = prov?.rates[code] ?? 1.0;
  final double price  = basePrice * rate;
  final String symbol = currencySymbol(code);

  final defaultStyle = isOriginal
      ? Theme.of(context).textTheme.labelSmall?.copyWith(
            decoration: TextDecoration.lineThrough,
          )
      : Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          );

  return Text('$symbol ${price.toStringAsFixed(2)}',
      style: style ?? defaultStyle);
}
