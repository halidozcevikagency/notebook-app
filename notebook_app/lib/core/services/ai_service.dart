/// AI Servisi
/// OpenAI API ile not özetleme, yazım düzeltme, dil çevirisi
/// Emergent Universal LLM Key kullanır
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

class AiService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-4o-mini';

  static AiService? _instance;
  AiService._();
  factory AiService() {
    _instance ??= AiService._();
    return _instance!;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SupabaseConfig.emergentLlmKey}',
      };

  /// Not içeriğini özetle
  Future<String> summarizeNote(String content) async {
    return await _chat(
      systemPrompt: 'You are a helpful assistant that summarizes notes concisely. '
          'Provide a clear, concise summary in 2-3 sentences.',
      userMessage: 'Please summarize the following note:\n\n$content',
    );
  }

  /// Yazım ve dilbilgisi kontrolü
  Future<String> spellCheck(String content) async {
    return await _chat(
      systemPrompt: 'You are a writing assistant. Fix spelling, grammar, and punctuation errors. '
          'Return ONLY the corrected text without any explanations.',
      userMessage: content,
    );
  }

  /// Metin çevirisi
  Future<String> translateText(String content, String targetLanguage) async {
    return await _chat(
      systemPrompt: 'You are a professional translator. Translate the given text accurately. '
          'Return ONLY the translated text without any explanations.',
      userMessage: 'Translate the following text to $targetLanguage:\n\n$content',
    );
  }

  /// Devam ettirme / AI yazma yardımı
  Future<String> continueWriting(String content) async {
    return await _chat(
      systemPrompt: 'You are a creative writing assistant. Continue the text naturally, '
          'matching the tone and style. Add 1-2 paragraphs.',
      userMessage: content,
    );
  }

  /// OpenAI Chat API çağrısı
  Future<String> _chat({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: _headers,
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 1024,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI service error: ${response.statusCode} - ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>;
    final message = choices.first['message'] as Map<String, dynamic>;
    return message['content'] as String;
  }
}
