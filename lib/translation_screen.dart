import 'package:flutter/material.dart';
import 'languages.dart'; // This imports your supportedLanguages map from a separate file
import 'api_key.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';


// The main widget for your translation screen.
// StatefulWidget is used because the UI will change as the user interacts.
class TranslationScreen extends StatefulWidget {
  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

// The state class holds the data and logic for the screen.
class _TranslationScreenState extends State<TranslationScreen> {
  // The currently selected base language (e.g., "English")
  String? _baseLanguage;
  Map<String, String> _translations = {};
  final FlutterTts _flutterTts = FlutterTts();

  // The list of target languages the user wants to translate into (e.g., ["French", "German"])
  List<String> _selectedTargetLanguages = [];

  // Controller for the text field where the user enters the word to translate
  final TextEditingController _wordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set the default base language to the first language in your map
    _baseLanguage = supportedLanguages.keys.first;
  }


  Future<void> _speak(String text, String languageCode) async {
  await _flutterTts.setLanguage(languageCode); // Set the TTS language
  await _flutterTts.speak(text);               // Speak the text
  }

    // Calls Google Translate API and returns the translated text
  Future<String> translateWithGoogle(String text, String from, String to) async {
    // Build the API URL with query parameters
    final url = Uri.https(
      'translation.googleapis.com', // API host
      '/language/translate/v2',     // API path
      {
        'q': text,                  // The text to translate
        'source': from,             // Source language code (e.g., 'en')
        'target': to,               // Target language code (e.g., 'es')
        'format': 'text',           // Format of the input text
        'key': googleTranslateApiKey, // Your API key
      },
    );

    // Send a POST request to the API
    final response = await http.post(url);

    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      final data = json.decode(response.body); // Parse the JSON response
      // Extract the translated text from the response
      return data['data']['translations'][0]['translatedText'];
    } else {
      // If there was an error, return the error code
      return 'Error: ${response.statusCode}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The app bar at the top of the screen
      appBar: AppBar(
        title: Text('Translator'), // Title shown in the app bar
      ),
      // The main content of the screen
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add space around the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
          children: [
            // --- BASE LANGUAGE DROPDOWN ---
            Text('Select base language:'), // Label for the dropdown
            DropdownButton<String>(
              value: _baseLanguage, // Currently selected language
              items: supportedLanguages.keys.map((lang) {
                // Create a dropdown item for each language in your map
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (value) {
                // When the user selects a new base language
                setState(() {
                  _baseLanguage = value;
                  // Optionally, you could clear the selected target languages here
                });
              },
            ),
            SizedBox(height: 16), // Add vertical space

            // --- TARGET LANGUAGES MULTI-SELECT ---
            Text('Select target languages:'), // Label for the multi-select
            Wrap(
              spacing: 8.0, // Space between chips
              children: supportedLanguages.keys
                  .where((lang) => lang != _baseLanguage) // Don't allow base language as a target
                  .map((lang) => FilterChip(
                        label: Text(lang), // Show language name on the chip
                        selected: _selectedTargetLanguages.contains(lang), // Is this chip selected?
                        onSelected: (selected) {
                          // When the user taps the chip
                          setState(() {
                            if (selected) {
                              _selectedTargetLanguages.add(lang); // Add to selected list
                            } else {
                              _selectedTargetLanguages.remove(lang); // Remove from selected list
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
            SizedBox(height: 16),



            // --- PLACEHOLDER FOR TRANSLATION RESULTS ---
            // ... (existing widgets above)

              SizedBox(height: 16),

              // --- WORD INPUT FIELD ---
              TextField(
                controller: _wordController,
                decoration: InputDecoration(
                  labelText: 'Enter word to translate',
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 16),

              // --- TRANSLATE BUTTON ---
              ElevatedButton(
                onPressed: () async {
                  // Get the language codes for the selected target languages
                  List<String> targetLangCodes = _selectedTargetLanguages
                      .map((lang) => supportedLanguages[lang]!) // Get code for each selected language
                      .toList();

                  // Get the code for the base language
                  String baseLangCode = supportedLanguages[_baseLanguage!]!;
                  String word = _wordController.text; // The word to translate

                  Map<String, String> newTranslations = {}; // Map to store translations

                  // For each target language, call the translation API
                  for (String targetCode in targetLangCodes) {
                    if (targetCode == baseLangCode) continue; // Skip if target is same as base
                    String translated = await translateWithGoogle(word, baseLangCode, targetCode); // Call API
                    newTranslations[targetCode] = translated; // Add result to the map
                  }

                  // Update the UI with the new translations
                  setState(() {
                    _translations = newTranslations;
                  });
                },


                child: Text('Translate'),
              ),

              SizedBox(height: 16),

              // --- PLACEHOLDER FOR TRANSLATION RESULTS ---
              _translations.isEmpty
                  ? Text(
                      'Translations will appear here.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _translations.entries.map((entry) {
                        String langName = supportedLanguages.entries
                            .firstWhere((e) => e.value == entry.key)
                            .key;
                        return InkWell(
                          onTap: () {
                            _speak(entry.value, entry.key); // entry.key is the language code
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '$langName: ${entry.value}',
                              style: TextStyle(
                                color: Colors.blue, // Makes it look tappable
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        );

                      }).toList(),
                    ),
          ], //children
        ),
      ),
    );
  }
}
