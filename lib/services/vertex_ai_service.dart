import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:logging/logging.dart';

import 'ai_service.dart';
import '../models/api_config.dart';

class VertexAIService implements AIService {
  static final Logger _logger = Logger('VertexAIService');
  
  @override
  final APIConfig config;
  
  AccessCredentials? _credentials;
  DateTime? _credentialsExpiry;

  VertexAIService(this.config) {
    if (config.provider != AIProvider.vertexAI) {
      throw ArgumentError('VertexAIService requires vertexAI provider');
    }
  }

  @override
  String get serviceName => 'Vertex AI';

  String get _baseUrl => 
      'https://${config.location}-aiplatform.googleapis.com/v1/projects/${config.projectId}/locations/${config.location}/publishers/google/models/${config.model}:generateContent';

  @override
  Future<bool> validateConfiguration() async {
    try {
      if (!config.isValid) {
        return false;
      }

      await _ensureAuthentication();
      
      // Test with a simple request
      final response = await _makeAuthenticatedRequest({
        'contents': [
          {
            'parts': [{'text': 'Hello'}]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 10,
        }
      });

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
        'Invalid configuration. Please check your authentication settings.',
      );
    }

    await _ensureAuthentication();

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
      _logger.info('Making request to Vertex AI');
      
      final response = await _makeAuthenticatedRequest(requestBody);

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
          throw InvalidRequestException('Invalid response format from Vertex AI');
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

  Future<void> _ensureAuthentication() async {
    if (_credentials != null && 
        _credentialsExpiry != null && 
        DateTime.now().isBefore(_credentialsExpiry!.subtract(const Duration(minutes: 5)))) {
      return; // Credentials are still valid
    }

    try {
      if (config.authType == AuthType.serviceAccount) {
        await _authenticateWithServiceAccount();
      } else {
        await _authenticateWithAPIKey();
      }
    } catch (e) {
      throw AuthenticationException(
        'Authentication failed: $e',
        originalException: e,
      );
    }
  }

  Future<void> _authenticateWithServiceAccount() async {
    if (config.serviceAccountPath == null) {
      throw AuthenticationException('Service account path is required');
    }

    final serviceAccountFile = File(config.serviceAccountPath!);
    if (!await serviceAccountFile.exists()) {
      throw AuthenticationException(
        'Service account file not found: ${config.serviceAccountPath}',
      );
    }

    final serviceAccountJson = await serviceAccountFile.readAsString();
    final serviceAccount = ServiceAccountCredentials.fromJson(serviceAccountJson);
    
    final client = http.Client();
    try {
      _credentials = await obtainAccessCredentialsViaServiceAccount(
        serviceAccount,
        ['https://www.googleapis.com/auth/cloud-platform'],
        client,
      );
      _credentialsExpiry = _credentials!.accessToken.expiry;
      _logger.info('Successfully authenticated with service account');
    } finally {
      client.close();
    }
  }

  Future<void> _authenticateWithAPIKey() async {
    if (config.apiKey == null) {
      throw AuthenticationException('API key is required');
    }
    
    // For API key authentication, we don't need to obtain access credentials
    // The API key will be used directly in requests
    _logger.info('Using API key authentication');
  }

  Future<http.Response> _makeAuthenticatedRequest(Map<String, dynamic> requestBody) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    String url = _baseUrl;

    if (config.authType == AuthType.serviceAccount) {
      if (_credentials?.accessToken.data == null) {
        throw AuthenticationException('No valid access token available');
      }
      headers['Authorization'] = 'Bearer ${_credentials!.accessToken.data}';
    } else {
      // Use API key
      url += '?key=${config.apiKey}';
    }

    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(requestBody),
    );
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
          'Authentication failed: $errorMessage',
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
    final authType = (dotenv.env['VERTEX_AUTH_TYPE'] ?? 'service_account').toLowerCase();
    
    if (authType == 'api_key') {
      final apiKey = dotenv.env['VERTEX_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw AuthenticationException(
          'VERTEX_API_KEY is required when using API key authentication'
        );
      }
      
      return APIConfig(
        provider: AIProvider.vertexAI,
        authType: AuthType.apiKey,
        apiKey: apiKey,
        projectId: _getRequiredEnv('VERTEX_PROJECT_ID'),
        location: dotenv.env['VERTEX_LOCATION'] ?? 'us-central1',
        model: dotenv.env['VERTEX_MODEL'] ?? 'gemini-1.5-flash',
        temperature: double.tryParse(dotenv.env['TEMPERATURE'] ?? '0.9') ?? 0.9,
        maxOutputTokens: int.tryParse(dotenv.env['MAX_OUTPUT_TOKENS'] ?? '2048') ?? 2048,
      );
    } else {
      final serviceAccountPath = dotenv.env['VERTEX_SERVICE_ACCOUNT_PATH'] ?? '';
      if (serviceAccountPath.isEmpty) {
        throw AuthenticationException(
          'VERTEX_SERVICE_ACCOUNT_PATH is required when using service account authentication'
        );
      }
      
      return APIConfig(
        provider: AIProvider.vertexAI,
        authType: AuthType.serviceAccount,
        serviceAccountPath: serviceAccountPath,
        projectId: _getRequiredEnv('VERTEX_PROJECT_ID'),
        location: dotenv.env['VERTEX_LOCATION'] ?? 'us-central1',
        model: dotenv.env['VERTEX_MODEL'] ?? 'gemini-1.5-flash',
        temperature: double.tryParse(dotenv.env['TEMPERATURE'] ?? '0.9') ?? 0.9,
        maxOutputTokens: int.tryParse(dotenv.env['MAX_OUTPUT_TOKENS'] ?? '2048') ?? 2048,
      );
    }
  }

  static String _getRequiredEnv(String key) {
    final value = dotenv.env[key] ?? '';
    if (value.isEmpty) {
      throw AuthenticationException('$key is required but not set in environment');
    }
    return value;
  }
}