import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const CoinToCoinsApp());
}

class CoinToCoinsApp extends StatelessWidget {
  const CoinToCoinsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coin to Coins',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF16213E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6366F1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF444567), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          hintStyle: const TextStyle(color: Color(0xFF888899)),
          prefixIconColor: const Color(0xFF6366F1),
        ),
      ),
      home: const CurrencyConverterScreen(),
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({Key? key}) : super(key: key);

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  String fromCurrency = 'USD';
  String toCurrency = 'EUR';
  double amount = 1.0;
  double convertedAmount = 0.0;
  bool isLoading = false;
  String errorMessage = '';
  Map<String, double> exchangeRates = {};

  final List<String> currencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'INR', 'AUD', 'CAD', 'CHF', 
    'CNY', 'SEK', 'NZD', 'SGD', 'HKD', 'MXN', 'BRL', 'ZAR', 
    'KRW', 'TRY', 'RUB', 'AED'
  ];

  @override
  void initState() {
    super.initState();
    fetchExchangeRates();
  }

  Future<void> fetchExchangeRates() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final url = Uri.parse('https://open.er-api.com/v6/latest/$fromCurrency');
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Network timeout. Please try again.'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        
        if (rates != null) {
          setState(() {
            exchangeRates = rates.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            );
            convertCurrency();
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch rates (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString().replaceFirst('Exception: ', '')}';
        isLoading = false;
        convertedAmount = 0.0;
      });
    }
  }

  void convertCurrency() {
    if (exchangeRates.isEmpty || !exchangeRates.containsKey(toCurrency)) {
      return;
    }
    
    final rate = exchangeRates[toCurrency] ?? 1.0;
    setState(() {
      convertedAmount = amount * rate;
    });
  }

  void onFromCurrencyChanged(String? value) {
    if (value != null && value != fromCurrency) {
      setState(() => fromCurrency = value);
      fetchExchangeRates();
    }
  }

  void onToCurrencyChanged(String? value) {
    if (value != null && value != toCurrency) {
      setState(() => toCurrency = value);
      convertCurrency();
    }
  }

  void onAmountChanged(String value) {
    final parsedAmount = double.tryParse(value) ?? 0.0;
    setState(() {
      amount = parsedAmount;
    });
    convertCurrency();
  }

  void swapCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
    });
    fetchExchangeRates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin to Coins'),
        elevation: 0,
      ),
      body: isLoading && exchangeRates.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.currency_exchange,
                            size: 50,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Currency Converter',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: const Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Error Message
                    if (errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Amount Input
                    Text(
                      'Enter Amount',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF6366F1),
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: onAmountChanged,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter amount to convert',
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // From Currency
                    Text(
                      'From Currency',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF6366F1),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        border: Border.all(
                          color: const Color(0xFF444567),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: fromCurrency,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          onChanged: onFromCurrencyChanged,
                          items: currencies
                              .map((currency) => DropdownMenuItem<String>(
                                    value: currency,
                                    child: Text(currency),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Swap Button
                    Center(
                      child: FloatingActionButton(
                        onPressed: swapCurrencies,
                        backgroundColor: const Color(0xFF6366F1),
                        child: const Icon(Icons.swap_vert),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // To Currency
                    Text(
                      'To Currency',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF6366F1),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        border: Border.all(
                          color: const Color(0xFF444567),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: toCurrency,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          onChanged: onToCurrencyChanged,
                          items: currencies
                              .map((currency) => DropdownMenuItem<String>(
                                    value: currency,
                                    child: Text(currency),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Result Display
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF4F46E5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$amount $fromCurrency',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(Icons.arrow_downward,
                              color: Colors.white54, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            '${convertedAmount.toStringAsFixed(2)} $toCurrency',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Refresh Button
                    ElevatedButton.icon(
                      onPressed: fetchExchangeRates,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Rates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Footer
                    Center(
                      child: Text(
                        'Real-time rates • ER-API',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white38,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
