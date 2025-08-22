import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/api_config.dart';
import '../services/ai_service.dart';
import '../services/service_factory.dart';
import '../services/config_manager.dart';

class SettingsScreen extends StatefulWidget {
  final Function(AIService) onServiceChanged;

  const SettingsScreen({
    super.key,
    required this.onServiceChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final Logger _logger = Logger('SettingsScreen');
  
  AIProvider _selectedProvider = AIProvider.geminiAPI;
  AuthType _selectedAuthType = AuthType.apiKey;
  
  final _geminiApiKeyController = TextEditingController();
  final _vertexApiKeyController = TextEditingController();
  final _vertexProjectIdController = TextEditingController();
  final _vertexLocationController = TextEditingController(text: 'us-central1');
  final _serviceAccountPathController = TextEditingController();
  final _temperatureController = TextEditingController(text: '0.9');
  final _maxTokensController = TextEditingController(text: '2048');
  
  bool _isLoading = false;
  bool _isTestingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfiguration();
  }

  @override
  void dispose() {
    _geminiApiKeyController.dispose();
    _vertexApiKeyController.dispose();
    _vertexProjectIdController.dispose();
    _vertexLocationController.dispose();
    _serviceAccountPathController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  void _loadCurrentConfiguration() async {
    try {
      final configManager = await ConfigManager.getInstance();
      final savedConfig = await configManager.loadConfig();
      
      // Try saved config first, then fall back to environment config
      APIConfig? loadedConfig = savedConfig;
      
      if (loadedConfig == null && AIServiceFactory.hasValidEnvironmentConfig) {
        try {
          final service = await AIServiceFactory.createService();
          loadedConfig = service.config;
        } catch (e) {
          _logger.warning('Could not load environment config: $e');
        }
      }
      
      final config = loadedConfig;
      if (config != null) {
        setState(() {
          _selectedProvider = config.provider;
          _selectedAuthType = config.authType;
          
          if (config.provider == AIProvider.geminiAPI && config.apiKey != null) {
            _geminiApiKeyController.text = config.apiKey!;
          }
          
          if (config.provider == AIProvider.vertexAI) {
            if (config.apiKey != null) _vertexApiKeyController.text = config.apiKey!;
            if (config.projectId != null) _vertexProjectIdController.text = config.projectId!;
            if (config.location != null) _vertexLocationController.text = config.location!;
            if (config.serviceAccountPath != null) _serviceAccountPathController.text = config.serviceAccountPath!;
          }
          
          _temperatureController.text = config.temperature.toString();
          _maxTokensController.text = config.maxOutputTokens.toString();
        });
      }
    } catch (e) {
      _logger.warning('Could not load configuration: $e');
    }
  }

  APIConfig _createConfigFromUI() {
    switch (_selectedProvider) {
      case AIProvider.geminiAPI:
        return APIConfig(
          provider: AIProvider.geminiAPI,
          authType: AuthType.apiKey,
          apiKey: _geminiApiKeyController.text.trim(),
          temperature: double.tryParse(_temperatureController.text) ?? 0.9,
          maxOutputTokens: int.tryParse(_maxTokensController.text) ?? 2048,
        );
      
      case AIProvider.vertexAI:
        return APIConfig(
          provider: AIProvider.vertexAI,
          authType: _selectedAuthType,
          apiKey: _selectedAuthType == AuthType.apiKey ? _vertexApiKeyController.text.trim() : null,
          serviceAccountPath: _selectedAuthType == AuthType.serviceAccount ? _serviceAccountPathController.text.trim() : null,
          projectId: _vertexProjectIdController.text.trim(),
          location: _vertexLocationController.text.trim().isNotEmpty ? _vertexLocationController.text.trim() : 'us-central1',
          temperature: double.tryParse(_temperatureController.text) ?? 0.9,
          maxOutputTokens: int.tryParse(_maxTokensController.text) ?? 2048,
        );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final config = _createConfigFromUI();
      final service = await AIServiceFactory.createAndValidateService(config: config);
      
      // Test with a simple message
      final response = await service.generateResponse("Hello, please respond with 'Connection test successful'");
      
      setState(() {
        _connectionStatus = "✅ Connection successful!\nResponse: ${response.substring(0, 50)}${response.length > 50 ? '...' : ''}";
      });
    } catch (e) {
      setState(() {
        _connectionStatus = "❌ Connection failed:\n${e.toString()}";
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveAndApplyConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = _createConfigFromUI();
      
      if (!config.isValid) {
        throw Exception('Invalid configuration. Please check all required fields.');
      }

      final service = await AIServiceFactory.createAndValidateService(config: config);
      
      // Save configuration to persistent storage
      final configManager = await ConfigManager.getInstance();
      await configManager.saveConfig(config);
      
      // Clear the service factory cache so it uses the new configuration
      AIServiceFactory.clearCache();
      
      widget.onServiceChanged(service);
      
      setState(() {
        _connectionStatus = "✅ Configuration saved and applied successfully!";
      });
      
      // Go back to chat screen after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      
    } catch (e) {
      setState(() {
        _connectionStatus = "❌ Failed to apply configuration:\n${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Provider Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAndApplyConfiguration,
            child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderSelection(),
            const SizedBox(height: 24),
            _buildProviderConfiguration(),
            const SizedBox(height: 24),
            _buildGenerationSettings(),
            const SizedBox(height: 24),
            _buildConnectionTest(),
            if (_connectionStatus != null) ...[
              const SizedBox(height: 16),
              _buildConnectionStatus(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Provider',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<AIProvider>(
              title: const Text('Gemini API'),
              subtitle: const Text('Direct API access, simpler setup'),
              value: AIProvider.geminiAPI,
              groupValue: _selectedProvider,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                  });
                }
              },
            ),
            RadioListTile<AIProvider>(
              title: const Text('Vertex AI'),
              subtitle: const Text('Enterprise features, more authentication options'),
              value: AIProvider.vertexAI,
              groupValue: _selectedProvider,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedProvider == AIProvider.geminiAPI ? 'Gemini API' : 'Vertex AI'} Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedProvider == AIProvider.geminiAPI) ..._buildGeminiAPIFields(),
            if (_selectedProvider == AIProvider.vertexAI) ..._buildVertexAIFields(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGeminiAPIFields() {
    return [
      TextField(
        controller: _geminiApiKeyController,
        decoration: const InputDecoration(
          labelText: 'API Key *',
          hintText: 'AIzaSy...',
          border: OutlineInputBorder(),
          helperText: 'Get from: https://aistudio.google.com/app/apikey',
        ),
        obscureText: true,
      ),
    ];
  }

  List<Widget> _buildVertexAIFields() {
    return [
      // Authentication Type Selection
      Text(
        'Authentication Method',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      RadioListTile<AuthType>(
        title: const Text('API Key'),
        subtitle: const Text('Simpler setup'),
        value: AuthType.apiKey,
        groupValue: _selectedAuthType,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedAuthType = value;
            });
          }
        },
      ),
      RadioListTile<AuthType>(
        title: const Text('Service Account'),
        subtitle: const Text('More secure, recommended for production'),
        value: AuthType.serviceAccount,
        groupValue: _selectedAuthType,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedAuthType = value;
            });
          }
        },
      ),
      const SizedBox(height: 16),
      
      // API Key or Service Account fields
      if (_selectedAuthType == AuthType.apiKey) ...[
        TextField(
          controller: _vertexApiKeyController,
          decoration: const InputDecoration(
            labelText: 'Vertex AI API Key *',
            border: OutlineInputBorder(),
            helperText: 'Get from Google Cloud Console > API Credentials',
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
      ],
      
      if (_selectedAuthType == AuthType.serviceAccount) ...[
        TextField(
          controller: _serviceAccountPathController,
          decoration: const InputDecoration(
            labelText: 'Service Account JSON Path *',
            hintText: '/path/to/service-account.json',
            border: OutlineInputBorder(),
            helperText: 'Full path to your service account key file',
          ),
        ),
        const SizedBox(height: 16),
      ],
      
      // Common Vertex AI fields
      TextField(
        controller: _vertexProjectIdController,
        decoration: const InputDecoration(
          labelText: 'Google Cloud Project ID *',
          hintText: 'my-project-123456',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _vertexLocationController,
        decoration: const InputDecoration(
          labelText: 'Location',
          hintText: 'us-central1',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }

  Widget _buildGenerationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generation Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _temperatureController,
                    decoration: const InputDecoration(
                      labelText: 'Temperature',
                      hintText: '0.9',
                      border: OutlineInputBorder(),
                      helperText: 'Creativity (0.0 - 1.0)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxTokensController,
                    decoration: const InputDecoration(
                      labelText: 'Max Tokens',
                      hintText: '2048',
                      border: OutlineInputBorder(),
                      helperText: 'Response length limit',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTest() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isTestingConnection ? null : _testConnection,
        icon: _isTestingConnection
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.wifi_protected_setup),
        label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final status = _connectionStatus;
    if (status == null) return const SizedBox.shrink();
    
    final isSuccess = status.startsWith('✅');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isSuccess 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isSuccess ? Colors.green[700] : Colors.red[700],
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}