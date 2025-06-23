// lib/woocommerce_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_key.dart'; // Import your WooCommerce keys

class WooCommerceService {
  // Base URL for your local WordPress WooCommerce REST API
  final String baseUrl = 'https://sanitube.us/wp-json/wc/v3';

  // Fetches a list of products from WooCommerce
  Future<List<dynamic>> fetchProducts() async {
    final url = Uri.parse(
      '$baseUrl/products?consumer_key=$wooConsumerKey&consumer_secret=$wooConsumerSecret',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  // ADD THIS METHOD BELOW:
  // Fetch product and its variations by product ID
  Future<Map<String, dynamic>> fetchProductWithVariations(int productId) async {
    // Fetch the main product
    final productUrl = Uri.parse(
      '$baseUrl/products/$productId?consumer_key=$wooConsumerKey&consumer_secret=$wooConsumerSecret',
    );
    final productResponse = await http.get(productUrl);

    if (productResponse.statusCode != 200) {
      throw Exception('Failed to load product');
    }
    final product = json.decode(productResponse.body);

    // Fetch all variations for this product
    final variationsUrl = Uri.parse(
      '$baseUrl/products/$productId/variations?consumer_key=$wooConsumerKey&consumer_secret=$wooConsumerSecret&per_page=100',
    );
    final variationsResponse = await http.get(variationsUrl);

    if (variationsResponse.statusCode != 200) {
      throw Exception('Failed to load variations');
    }
    final variations = json.decode(variationsResponse.body);

    // Return both as a map
    return {
      'product': product,
      'variations': variations,
    };
  }
}
