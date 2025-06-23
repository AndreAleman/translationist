import 'package:flutter/material.dart';
import 'product_tab.dart'; // Import the product tab widget

class CPQPage extends StatelessWidget {
  // Product IDs for the three tabs (replace with your actual product IDs)
  final List<int> productIds = [2890, 3651, 1914];

  CPQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: productIds.length, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configure Price Quote (CPQ)'),
          bottom: TabBar(
            tabs: [
              // Create a tab for each product
              Tab(text: 'Product 1'),
              Tab(text: 'Product 2'),
              Tab(text: 'Product 3'),
            ],
          ),
        ),
        body: TabBarView(
          children: productIds.map((id) {
            // For each product ID, create a ProductTab widget
            return ProductTab(productId: id);
          }).toList(),
        ),
      ),
    );
  }
}
