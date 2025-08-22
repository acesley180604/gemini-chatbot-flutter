import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';

import 'ai_service.dart';
import '../models/api_config.dart';

class GeminiAPIService implements AIService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static final Logger _logger = Logger('GeminiAPIService');
  
  @override
  final APIConfig config;

  GeminiAPIService(this.config) {
    if (config.provider != AIProvider.geminiAPI) {
      throw ArgumentError('GeminiAPIService requires geminiAPI provider');
    }
  }

  @override
  String get serviceName => 'Gemini API';

  @override
  Future<bool> validateConfiguration() async {
    try {
      if (!config.isValid) {
        return false;
      }

      // Test with a simple request
      final url = '$_baseUrl/${config.model}:generateContent?key=${config.apiKey}';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': 'Hello'}]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 10,
          }
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('Configuration validation failed: $e');
      return false;
    }
  }

  @override
  Future<String> generateResponse(String prompt) async {
    if (!config.isValid) {
      throw AuthenticationException(
        'Invalid configuration. Please check your API key.',
      );
    }

    final url = '$_baseUrl/${config.model}:generateContent?key=${config.apiKey}';
    
    final requestBody = {
      'contents': [
        {
          'parts': [{'text': prompt}]
        }
      ],
      'generationConfig': {
        'temperature': config.temperature,
        'topK': 1,
        'topP': 1,
        'maxOutputTokens': config.maxOutputTokens,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    };

    try {
      _logger.info('Making request to Gemini API');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      _logger.info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          throw InvalidRequestException('Invalid response format from Gemini API');
        }
      } else {
        await _handleErrorResponse(response);
        throw AIServiceException('Request failed with status ${response.statusCode}');
      }
    } on AIServiceException {
      rethrow;
    } catch (e) {
      _logger.severe('Network error: $e');
      throw NetworkException('Network error occurred: $e', originalException: e);
    }
  }

  Future<void> _handleErrorResponse(http.Response response) async {
    String errorMessage = 'Unknown error occurred';
    String? errorCode;

    try {
      final errorData = jsonDecode(response.body);
      errorMessage = errorData['error']?['message'] ?? response.body;
      errorCode = errorData['error']?['code']?.toString();
    } catch (e) {
      errorMessage = response.body;
    }

    switch (response.statusCode) {
      case 400:
        throw InvalidRequestException(
          'Bad request: $errorMessage',
          code: errorCode,
        );
      case 401:
        throw AuthenticationException(
          'Invalid API key: $errorMessage',
          code: errorCode,
        );
      case 403:
        throw AuthenticationException(
          'Access denied: $errorMessage',
          code: errorCode,
        );
      case 429:
        throw RateLimitException(
          'Rate limit exceeded: $errorMessage',
          code: errorCode,
        );
      case 500:
      case 502:
      case 503:
        throw AIServiceException(
          'Server error: $errorMessage',
          code: errorCode,
        );
      default:
        throw AIServiceException(
          'API Error (${response.statusCode}): $errorMessage',
          code: errorCode,
        );
    }
  }

  static APIConfig createConfigFromEnv() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'your_actual_gemini_api_key_here') {
      throw AuthenticationException(
        'Please add your Gemini API key to the .env file. Get one from: https://aistudio.google.com/app/apikey'
      );
    }

    return APIConfig(
      provider: AIProvider.geminiAPI,
      authType: AuthType.apiKey,
      apiKey: apiKey,
      model: dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash-latest',
      temperature: double.tryParse(dotenv.env['TEMPERATURE'] ?? '0.9') ?? 0.9,
      maxOutputTokens: int.tryParse(dotenv.env['MAX_OUTPUT_TOKENS'] ?? '2048') ?? 2048,
    );
  }
}