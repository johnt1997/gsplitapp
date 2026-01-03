import 'dart:convert'; // Wichtig für JSON
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  // 🔑 DEIN KEY HIER:
  static const String _apiKey = '';

  Future<Map<String, dynamic>> analyzePint(String imagePath) async {
    try {
      print("🤖 AI Service: Starte Analyse für $imagePath");

      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
        safetySettings: [
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.none,
          ), // Alkohol erlauben
        ],
      );

      final imageBytes = await File(imagePath).readAsBytes();

      // Der Prompt ist entscheidend für gute Ergebnisse
      final prompt = TextPart('''
        Analyze this photo of a Guinness pint. Act as a strict master brewer.
        Rate it from 0.0 to 10.0 based on: Head size, Creaminess, Domed top, Sharp split line, Color.
        
        Return ONLY raw JSON without markdown formatting. Structure:
        {
          "score": 8.5,
          "keywords": ["Creamy", "Perfect Split", "Good Dome"],
          "is_guinness": true,
          "explanation": "Great split line but the head is slightly too large."
        }
        If it is clearly not a Guinness or beer, set "is_guinness" to false and score to 0.
      ''');

      final content = [
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await model.generateContent(content);
      String? text = response.text;

      if (text == null) throw Exception("Empty AI Response");

      // Cleanup: Falls Gemini ```json ... ``` schreibt
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();

      // JSON parsen
      final Map<String, dynamic> data = jsonDecode(text);

      print("🤖 AI Result: $data");
      return data;
    } catch (e) {
      print("❌ AI Service Error: $e");
      // Fallback Werte damit die App nicht crasht
      return {
        "score": 7.0,
        "keywords": ["Analysis Failed"],
        "is_guinness": true,
        "explanation": "Could not connect to AI master brewer.",
      };
    }
  }
}
