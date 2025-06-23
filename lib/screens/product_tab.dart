import 'package:flutter/material.dart';
import '../services/woocommerce_service.dart';
import 'quote_screen.dart';
import 'purchase_screen.dart';



class ProductTab extends StatefulWidget {
  final int productId;

  const ProductTab({super.key, required this.productId});

  @override
  State<ProductTab> createState() => _ProductTabState();
}

class _ProductTabState extends State<ProductTab> {
  late Future<Map<String, dynamic>> _productFuture;

  // State for selected attributes and custom length
  String? selectedFittingA;
  String? selectedFittingB;
  String? selectedLength;
  String? selectedAlloy;
  String? customLengthInput;

  // State for inventory and selected variation
  Map<String, dynamic>? selectedVariation;
  bool? inStock;
  int? stockQuantity;
  bool checked = false; // Whether the user pressed "Update"

  @override
  void initState() {
    super.initState();
    _productFuture = WooCommerceService().fetchProductWithVariations(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No product data found.'));
        }

        final product = snapshot.data!['product'];
        final variations = snapshot.data!['variations'];

        // Extract unique options for each attribute from variations
        List<String> fittingAOptions = _extractAttributeOptions(variations, 'Fitting A');
        List<String> fittingBOptions = _extractAttributeOptions(variations, 'Fitting B');
        List<String> lengthOptions = _extractAttributeOptions(variations, 'Overall Length');
        List<String> alloyOptions = _extractAttributeOptions(variations, 'Alloy');

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(product['name'] ?? 'Product', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Fitting A dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Fitting A'),
                value: selectedFittingA,
                items: fittingAOptions.map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                )).toList(),
                onChanged: (val) => setState(() => selectedFittingA = val),
              ),
              const SizedBox(height: 8),

              // Fitting B dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Fitting B'),
                value: selectedFittingB,
                items: fittingBOptions.map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                )).toList(),
                onChanged: (val) => setState(() => selectedFittingB = val),
              ),
              const SizedBox(height: 8),

              // Overall Length dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Overall Length'),
                value: selectedLength,
                items: lengthOptions.map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                )).toList(),
                onChanged: (val) => setState(() {
                  selectedLength = val;
                  if (val != 'CUSTOM') customLengthInput = null;
                }),
              ),
              const SizedBox(height: 8),

              // Show custom length input if "CUSTOM" is selected
              if (selectedLength == 'CUSTOM')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Enter Custom Length'),
                  onChanged: (val) => setState(() => customLengthInput = val),
                ),
              const SizedBox(height: 8),

              // Alloy dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Alloy'),
                value: selectedAlloy,
                items: alloyOptions.map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                )).toList(),
                onChanged: (val) => setState(() => selectedAlloy = val),
              ),
              const SizedBox(height: 24),

              // Update button
              ElevatedButton(
                child: const Text('Update'),
                onPressed: () {
                  // When pressed, find the matching variation and update state
                  final variation = _findMatchingVariation(
                    variations,
                    selectedFittingA,
                    selectedFittingB,
                    selectedLength,
                    selectedAlloy,
                    customLengthInput,
                  );
                  setState(() {
                    selectedVariation = variation;
                    checked = true;
                    if (variation != null && variation['stock_status'] == 'instock') {
                      inStock = true;
                      stockQuantity = int.tryParse(variation['stock_quantity']?.toString() ?? '0');
                    } else {
                      inStock = false;
                      stockQuantity = 0;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Show result after pressing Update
              if (checked)
                selectedLength == 'CUSTOM'
                  ? _buildQuoteSection(context)
                  : (selectedVariation != null
                      ? (inStock == true
                          ? _buildPurchaseSection(context, stockQuantity)
                          : _buildQuoteSection(context))
                      : const Text('No matching product variation found.')),
            ],
          ),
        );
      },
    );
  }

  // Helper to extract unique options for a given attribute from variations
  List<String> _extractAttributeOptions(List<dynamic> variations, String attributeName) {
    final options = <String>{};
    for (final variation in variations) {
      for (final attr in variation['attributes']) {
        if (attr['name'] == attributeName && attr['option'] != null) {
          options.add(attr['option']);
        }
      }
    }
    // Add "CUSTOM" for Overall Length if not already present
    if (attributeName == 'Overall Length') {
      options.add('CUSTOM');
    }
    return options.toList();
  }

  // Helper to find the matching variation based on selected attributes
  Map<String, dynamic>? _findMatchingVariation(
    List<dynamic> variations,
    String? fittingA,
    String? fittingB,
    String? length,
    String? alloy,
    String? customLength,
  ) {
    for (final variation in variations) {
      bool match = true;
      for (final attr in variation['attributes']) {
        if (attr['name'] == 'Fitting A' && attr['option'] != fittingA) match = false;
        if (attr['name'] == 'Fitting B' && attr['option'] != fittingB) match = false;
        if (attr['name'] == 'Overall Length') {
          if (length == 'CUSTOM') {
            match = false; // Custom length is not a standard variation
          } else if (attr['option'] != length) {
            match = false;
          }
        }
        if (attr['name'] == 'Alloy' && attr['option'] != alloy) match = false;
      }
      if (match) return variation;
    }
    return null;
  }

  // UI for quote section
  Widget _buildQuoteSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('This configuration requires a quote.'),
        const SizedBox(height: 8),
        ElevatedButton(
          child: const Text('Add to Quote'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuoteScreen()),
            );
          },
        ),
      ],
    );
  }

  // UI for purchase section
  Widget _buildPurchaseSection(BuildContext context, int? stock) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('In stock: ${stock ?? 0}'),
        const SizedBox(height: 8),
        ElevatedButton(
          child: const Text('Purchase'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PurchaseScreen()),
            );
          },
        ),
      ],
    );
  }
}

// Dummy QuoteScreen and PurchaseScreen for navigation
class QuoteScreen extends StatelessWidget {
  const QuoteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote')),
      body: const Center(child: Text('Quote requested!')),
    );
  }
}

class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase')),
      body: const Center(child: Text('Proceed to purchase!')),
    );
  }
}
