enum AIProvider {
  geminiAPI,
  vertexAI,
}

enum AuthType {
  apiKey,
  serviceAccount,
}

class APIConfig {
  final AIProvider provider;
  final AuthType authType;
  final String? apiKey;
  final String? serviceAccountPath;
  final String? projectId;
  final String? location;
  final String model;
  final double temperature;
  final int maxOutputTokens;

  const APIConfig({
    required this.provider,
    required this.authType,
    this.apiKey,
    this.serviceAccountPath,
    this.projectId,
    this.location = 'us-central1',
    this.model = 'gemini-1.5-flash',
    this.temperature = 0.9,
    this.maxOutputTokens = 2048,
  });

  static APIConfig fromEnvironment() {
    final provider = _getProviderFromEnv();
    
    switch (provider) {
      case AIProvider.geminiAPI:
        return APIConfig(
          provider: AIProvider.geminiAPI,
          authType: AuthType.apiKey,
          apiKey: _getRequiredEnv('GEMINI_API_KEY'),
          model: _getEnvOrDefault('GEMINI_MODEL', 'gemini-1.5-flash-latest'),
          temperature: double.tryParse(_getEnvOrDefault('TEMPERATURE', '0.9')) ?? 0.9,
          maxOutputTokens: int.tryParse(_getEnvOrDefault('MAX_OUTPUT_TOKENS', '2048')) ?? 2048,
        );
      
      case AIProvider.vertexAI:
        final authType = _getEnvOrDefault('VERTEX_AUTH_TYPE', 'service_account') == 'api_key'
            ? AuthType.apiKey
            : AuthType.serviceAccount;
        
        return APIConfig(
          provider: AIProvider.vertexAI,
          authType: authType,
          apiKey: authType == AuthType.apiKey ? _getRequiredEnv('VERTEX_API_KEY') : null,
          serviceAccountPath: authType == AuthType.serviceAccount ? _getRequiredEnv('VERTEX_SERVICE_ACCOUNT_PATH') : null,
          projectId: _getRequiredEnv('VERTEX_PROJECT_ID'),
          location: _getEnvOrDefault('VERTEX_LOCATION', 'us-central1'),
          model: _getEnvOrDefault('VERTEX_MODEL', 'gemini-1.5-flash'),
          temperature: double.tryParse(_getEnvOrDefault('TEMPERATURE', '0.9')) ?? 0.9,
          maxOutputTokens: int.tryParse(_getEnvOrDefault('MAX_OUTPUT_TOKENS', '2048')) ?? 2048,
        );
    }
  }

  static AIProvider _getProviderFromEnv() {
    final provider = _getEnvOrDefault('AI_PROVIDER', 'gemini_api').toLowerCase();
    switch (provider) {
      case 'vertex_ai':
      case 'vertex':
        return AIProvider.vertexAI;
      case 'gemini_api':
      case 'gemini':
      default:
        return AIProvider.geminiAPI;
    }
  }

  static String _getRequiredEnv(String key) {
    final value = _getEnvOrDefault(key, '');
    if (value.isEmpty || value == 'your_actual_${key.toLowerCase()}_here') {
      throw Exception('$key is required but not set in environment');
    }
    return value;
  }

  static String _getEnvOrDefault(String key, String defaultValue) {
    // This would typically use flutter_dotenv, but we'll implement it in the service
    return defaultValue;
  }

  bool get isValid {
    switch (provider) {
      case AIProvider.geminiAPI:
        return authType == AuthType.apiKey && 
               apiKey != null && 
               apiKey!.isNotEmpty;
      
      case AIProvider.vertexAI:
        final hasValidAuth = authType == AuthType.apiKey 
            ? (apiKey != null && apiKey!.isNotEmpty)
            : (serviceAccountPath != null && serviceAccountPath!.isNotEmpty);
        return hasValidAuth && 
               projectId != null && 
               projectId!.isNotEmpty;
    }
  }

  @override
  String toString() {
    return 'APIConfig(provider: $provider, authType: $authType, model: $model)';
  }
}