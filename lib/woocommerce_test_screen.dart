import 'package:flutter/material.dart';
import 'services/woocommerce_service.dart';

class WooCommerceTestScreen extends StatefulWidget {
  @override
  _WooCommerceTestScreenState createState() => _WooCommerceTestScreenState();
}

class _WooCommerceTestScreenState extends State<WooCommerceTestScreen> {
  final WooCommerceService wooService = WooCommerceService();

  late Future<List<dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = wooService.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WooCommerce Products Test'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No products found.'));
          } else {
            final products = snapshot.data!;
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product['name']),
                  subtitle: Text('\$${product['price']}'),
                  leading: product['images'] != null && product['images'].isNotEmpty
                      ? Image.network(product['images'][0]['src'])
                      : null,
                );
              },
            );
          }
        },
      ),
    );
  }
}
