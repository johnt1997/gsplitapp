import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AiService {
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';

  Future<Map<String, dynamic>> analyzePint(XFile photo) async {
    try {
      print("AI Service: Starte Analyse für ${photo.name}");

      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("OPENAI_API_KEY fehlt in .env");
      }

      // XFile.readAsBytes funktioniert auf Mobile UND Web
      final imageBytes = await photo.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = '''
Analyze this photo of a Guinness pint. Act as a strict master brewer.
Rate it from 0.0 to 10.0 based on: Head size, Creaminess, Domed top, Sharp split line, Color.

Return ONLY a JSON object with this exact shape:
{
  "score": 8.5,
  "keywords": ["Creamy", "Perfect Split", "Good Dome"],
  "is_guinness": true,
  "explanation": "Great split line but the head is slightly too large."
}
If it is clearly not a Guinness or beer, set "is_guinness" to false and score to 0.
''';

      final body = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                  'detail': 'low',
                },
              },
            ],
          },
        ],
        'response_format': {'type': 'json_object'},
        'max_tokens': 400,
        'temperature': 0.4,
      });

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception("OpenAI HTTP ${response.statusCode}: ${response.body}");
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final content = decoded['choices']?[0]?['message']?['content'];
      if (content == null) throw Exception("Empty AI Response");

      final Map<String, dynamic> data = jsonDecode(content);
      print("AI Result: $data");
      return data;
    } catch (e) {
      print("AI Service Error: $e");
      return {
        "score": 7.0,
        "keywords": ["Analysis Failed"],
        "is_guinness": true,
        "explanation": "Could not connect to AI master brewer.",
      };
    }
  }
}
