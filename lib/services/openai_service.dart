import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

final apiKey = dotenv.env['SUPABASE_ANON_KEY'];

class OpenAIService {
  static const _url = 'https://api.openai.com/v1/chat/completions';
  final _apiKey = apiKey;

  /// 일반 채팅
  Future<String> sendMessage(List<Message> messages) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': messages.map((m) => m.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      return '⚠️ Error: ${response.body}';
    }
  }

  Future<String> translateText(
    String text,
    String fromLang,
    String toLang,
  ) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            "role": "system",
            "content":
                "You are a translator. Translate from $fromLang to $toLang only. Keep meaning natural and conversational.",
          },
          {"role": "user", "content": text},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      return '⚠️ Error: ${response.body}';
    }
  }
}
