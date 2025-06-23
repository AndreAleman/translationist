import 'package:flutter/material.dart';
import 'translation_screen.dart'; // Import your new screen
import 'api_key.dart';
import 'woocommerce_test_screen.dart';
import 'package:flutter/material.dart';
import 'screens/cpq_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CPQ POC',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CPQPage(),
    );
  }
}
