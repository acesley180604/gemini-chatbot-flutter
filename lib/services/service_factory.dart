import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';

import 'ai_service.dart';
import 'gemini_api_service.dart';
import 'vertex_ai_service.dart';
import 'config_manager.dart';
import '../models/api_config.dart';

class AIServiceFactory {
  static final Logger _logger = Logger('AIServiceFactory');
  static AIService? _cachedService;

  static Future<AIService> createService({APIConfig? config}) async {
    if (_cachedService != null && config == null) {
      return _cachedService!;
    }

    APIConfig serviceConfig;
    if (config != null) {
      serviceConfig = config;
    } else {
      // Try to load from saved configuration first
      try {
        final configManager = await ConfigManager.getInstance();
        final savedConfig = await configManager.loadConfig();
        serviceConfig = savedConfig ?? _createConfigFromEnvironment();
      } catch (e) {
        _logger.warning('Failed to load saved config, using environment: $e');
        serviceConfig = _createConfigFromEnvironment();
      }
    }
    
    final service = switch (serviceConfig.provider) {
      AIProvider.geminiAPI => GeminiAPIService(serviceConfig),
      AIProvider.vertexAI => VertexAIService(serviceConfig),
    };

    _logger.info('Created ${service.serviceName} service');
    
    if (config == null) {
      _cachedService = service;
    }
    
    return service;
  }

  // Legacy synchronous method for backward compatibility
  static AIService createServiceSync({APIConfig? config}) {
    final serviceConfig = config ?? _createConfigFromEnvironment();
    
    final service = switch (serviceConfig.provider) {
      AIProvider.geminiAPI => GeminiAPIService(serviceConfig),
      AIProvider.vertexAI => VertexAIService(serviceConfig),
    };

    _logger.info('Created ${service.serviceName} service (sync)');
    return service;
  }

  static Future<AIService> createAndValidateService({APIConfig? config}) async {
    final service = await createService(config: config);
    
    _logger.info('Validating ${service.serviceName} configuration...');
    
    final isValid = await service.validateConfiguration();
    if (!isValid) {
      throw AIServiceException(
        'Service configuration validation failed for ${service.serviceName}. '
        'Please check your authentication credentials and settings.',
      );
    }
    
    _logger.info('${service.serviceName} configuration validated successfully');
    return service;
  }

  static APIConfig _createConfigFromEnvironment() {
    final providerName = dotenv.env['AI_PROVIDER']?.toLowerCase() ?? 'gemini_api';
    
    switch (providerName) {
      case 'vertex_ai':
      case 'vertex':
        return VertexAIService.createConfigFromEnv();
      case 'gemini_api':
      case 'gemini':
      default:
        return GeminiAPIService.createConfigFromEnv();
    }
  }

  static AIProvider getProviderFromEnvironment() {
    final providerName = dotenv.env['AI_PROVIDER']?.toLowerCase() ?? 'gemini_api';
    
    switch (providerName) {
      case 'vertex_ai':
      case 'vertex':
        return AIProvider.vertexAI;
      case 'gemini_api':
      case 'gemini':
      default:
        return AIProvider.geminiAPI;
    }
  }

  static void clearCache() {
    _cachedService = null;
    _logger.info('Service cache cleared');
  }

  static bool get hasValidEnvironmentConfig {
    try {
      _createConfigFromEnvironment();
      return true;
    } catch (e) {
      _logger.warning('Invalid environment configuration: $e');
      return false;
    }
  }

  static List<String> getRequiredEnvironmentVariables() {
    final provider = getProviderFromEnvironment();
    
    switch (provider) {
      case AIProvider.geminiAPI:
        return ['GEMINI_API_KEY'];
      
      case AIProvider.vertexAI:
        final authType = dotenv.env['VERTEX_AUTH_TYPE']?.toLowerCase() ?? 'service_account';
        if (authType == 'api_key') {
          return ['VERTEX_API_KEY', 'VERTEX_PROJECT_ID'];
        } else {
          return ['VERTEX_SERVICE_ACCOUNT_PATH', 'VERTEX_PROJECT_ID'];
        }
    }
  }

  static Map<String, String> getOptionalEnvironmentVariables() {
    return {
      'AI_PROVIDER': 'gemini_api or vertex_ai',
      'VERTEX_AUTH_TYPE': 'api_key or service_account (for Vertex AI)',
      'VERTEX_LOCATION': 'us-central1 (for Vertex AI)',
      'GEMINI_MODEL': 'gemini-1.5-flash-latest (for Gemini API)',
      'VERTEX_MODEL': 'gemini-1.5-flash (for Vertex AI)',
      'TEMPERATURE': '0.9',
      'MAX_OUTPUT_TOKENS': '2048',
    };
  }
}