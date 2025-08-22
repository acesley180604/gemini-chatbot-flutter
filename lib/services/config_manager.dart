import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

import '../models/api_config.dart';

class ConfigManager {
  static final Logger _logger = Logger('ConfigManager');
  static const String _configKey = 'ai_service_config';
  
  static ConfigManager? _instance;
  late SharedPreferences _prefs;
  
  ConfigManager._();
  
  static Future<ConfigManager> getInstance() async {
    if (_instance == null) {
      _instance = ConfigManager._();
      await _instance!._init();
    }
    return _instance!;
  }
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Save configuration to persistent storage
  Future<void> saveConfig(APIConfig config) async {
    try {
      final configMap = _configToMap(config);
      final configJson = jsonEncode(configMap);
      await _prefs.setString(_configKey, configJson);
      _logger.info('Configuration saved: ${config.provider}');
    } catch (e) {
      _logger.severe('Failed to save configuration: $e');
      throw Exception('Failed to save configuration: $e');
    }
  }
  
  /// Load configuration from persistent storage
  Future<APIConfig?> loadConfig() async {
    try {
      final configJson = _prefs.getString(_configKey);
      if (configJson == null) {
        _logger.info('No saved configuration found');
        return null;
      }
      
      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      final config = _configFromMap(configMap);
      _logger.info('Configuration loaded: ${config.provider}');
      return config;
    } catch (e) {
      _logger.warning('Failed to load configuration: $e');
      return null;
    }
  }
  
  /// Clear saved configuration
  Future<void> clearConfig() async {
    try {
      await _prefs.remove(_configKey);
      _logger.info('Configuration cleared');
    } catch (e) {
      _logger.warning('Failed to clear configuration: $e');
    }
  }
  
  /// Check if configuration exists
  bool hasConfig() {
    return _prefs.containsKey(_configKey);
  }
  
  Map<String, dynamic> _configToMap(APIConfig config) {
    return {
      'provider': config.provider.toString(),
      'authType': config.authType.toString(),
      'apiKey': config.apiKey,
      'serviceAccountPath': config.serviceAccountPath,
      'projectId': config.projectId,
      'location': config.location,
      'model': config.model,
      'temperature': config.temperature,
      'maxOutputTokens': config.maxOutputTokens,
    };
  }
  
  APIConfig _configFromMap(Map<String, dynamic> map) {
    return APIConfig(
      provider: _parseProvider(map['provider']),
      authType: _parseAuthType(map['authType']),
      apiKey: map['apiKey'],
      serviceAccountPath: map['serviceAccountPath'],
      projectId: map['projectId'],
      location: map['location'] ?? 'us-central1',
      model: map['model'] ?? 'gemini-1.5-flash',
      temperature: (map['temperature'] ?? 0.9).toDouble(),
      maxOutputTokens: (map['maxOutputTokens'] ?? 2048).toInt(),
    );
  }
  
  AIProvider _parseProvider(String? provider) {
    switch (provider) {
      case 'AIProvider.vertexAI':
        return AIProvider.vertexAI;
      case 'AIProvider.geminiAPI':
      default:
        return AIProvider.geminiAPI;
    }
  }
  
  AuthType _parseAuthType(String? authType) {
    switch (authType) {
      case 'AuthType.serviceAccount':
        return AuthType.serviceAccount;
      case 'AuthType.apiKey':
      default:
        return AuthType.apiKey;
    }
  }
}