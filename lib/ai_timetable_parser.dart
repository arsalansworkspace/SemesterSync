import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiTimetableParser {
  static const String _apiKey = 'AQ.Ab8RN6KyM0EhbBQhXQPg_X-Cg40uExYAXuBzFkK5WmIIW5-PoQ';

  // CHANGED: Using List<dynamic> to avoid copy-paste stripping
  static Future<List<dynamic>> extractScheduleFromImage(Uint8List imageBytes) async {
    if (_apiKey.isEmpty || _apiKey.contains('YOUR_GEMINI')) {
      debugPrint("❌ ERROR: Invalid API Key.");
      return [];
    }

    final List<String> fallbackModels = [
      'gemini-3.8-flash',
      'gemini-1.5-pro',
      'gemini-1.5-flash',
    ];

    final prompt = TextPart('''
      Analyze this university timetable image. Extract all class schedules into a raw JSON array.
      Ignore 'Break' rows.
      Ensure the JSON has exactly these keys for each object:
      "dayOfWeek" (e.g., "Monday"), "subject" (e.g., "Parallel & Distributed Computing"), 
      "instructor" (e.g., "Mr. Jawad"), "startTime" (e.g., "09:00 AM"), 
      "endTime" (e.g., "10:00 AM"), "roomNumber" (e.g., "Soft-Lab").
      Return ONLY valid JSON. Do not include markdown formatting like ```json.
    ''');

    final imagePart = DataPart('image/jpeg', imageBytes);

    for (String modelName in fallbackModels) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: _apiKey);
        final response = await model.generateContent([Content.multi([prompt, imagePart])]);

        final String rawJson = response.text?.trim() ?? '[]';
        final cleanJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();
        final List<dynamic> parsedList = jsonDecode(cleanJson);

        List<dynamic> extractedData = [];
        for (var item in parsedList) {
          extractedData.add({
            'subject': item['subject'] ?? 'Unknown Subject',
            'instructor': item['instructor'] ?? 'Unknown Instructor',
            'dayOfWeek': item['dayOfWeek'] ?? 'Monday',
            'startTime': item['startTime'] ?? '00:00',
            'endTime': item['endTime'] ?? '00:00',
            'roomNumber': item['roomNumber'] ?? 'TBA',
          });
        }

        return extractedData;

      } catch (e) {
        if (e.toString().contains('503') || e.toString().contains('404')) {
          continue;
        } else {
          break;
        }
      }
    }
    return [];
  }
}