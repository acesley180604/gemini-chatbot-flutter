import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/provider_indicator.dart';
import '../services/ai_service.dart';
import '../services/service_factory.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static final Logger _logger = Logger('ChatScreen');
  
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  AIService? _aiService;
  bool _isLoading = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      setState(() {
        _isLoading = true;
        _initializationError = null;
      });

      _aiService = await AIServiceFactory.createAndValidateService();
      
      setState(() {
        _isLoading = false;
        if (_messages.isEmpty) {
          _messages.add(Message(
            content: 'Hello! I\'m ready to chat using ${_aiService!.serviceName}. How can I help you today?',
            isUser: false,
          ));
        } else {
          // If messages exist, just add a service change notification
          _messages.add(Message(
            content: 'Switched to ${_aiService!.serviceName}. Ready to continue our conversation!',
            isUser: false,
          ));
        }
      });
      
      _logger.info('Service initialized successfully: ${_aiService!.serviceName}');
    } catch (e) {
      _logger.severe('Failed to initialize service: $e');
      setState(() {
        _isLoading = false;
        _initializationError = _getErrorMessage(e);
      });
    }
  }

  void _onServiceChanged(AIService newService) {
    setState(() {
      _aiService = newService;
      _initializationError = null;
      _messages.add(Message(
        content: 'Switched to ${newService.serviceName}. Ready to continue our conversation!',
        isUser: false,
      ));
    });
    _scrollToBottom();
    _logger.info('Service changed to: ${newService.serviceName}');
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onServiceChanged: _onServiceChanged,
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _aiService == null) return;

    final userMessage = Message(content: text, isUser: true);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService!.generateResponse(text);
      setState(() {
        _messages.add(Message(content: response, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      _logger.warning('Error generating response: $e');
      setState(() {
        _messages.add(Message(
          content: _getErrorMessage(e),
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthenticationException) {
      return 'Authentication Error: ${error.message}\n\nPlease check your API credentials in the .env file.';
    } else if (error is RateLimitException) {
      return 'Rate Limit Exceeded: ${error.message}\n\nPlease wait a moment before trying again.';
    } else if (error is NetworkException) {
      return 'Network Error: ${error.message}\n\nPlease check your internet connection.';
    } else if (error is InvalidRequestException) {
      return 'Invalid Request: ${error.message}\n\nPlease try rephrasing your message.';
    } else if (error is AIServiceException) {
      return 'Service Error: ${error.message}';
    } else {
      return 'Unexpected Error: ${error.toString()}\n\nPlease try again or check your configuration.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_aiService != null 
            ? '${_aiService!.serviceName} Chatbot' 
            : 'AI Chatbot'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
          if (_aiService != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initializeService,
              tooltip: 'Reconnect',
            ),
        ],
      ),
      body: _initializationError != null 
          ? _buildErrorView()
          : _buildChatView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Initialize AI Service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _initializationError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeService,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        // Provider indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Connected to: '),
              ProviderIndicator(service: _aiService),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty && !_isLoading
              ? const Center(
                  child: Text(
                    'Start a conversation!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(message: _messages[index]);
                  },
                ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 12),
                Text('Thinking...'),
              ],
            ),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: _aiService != null && !_isLoading,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _aiService != null && !_isLoading && _textController.text.trim().isNotEmpty
                ? _sendMessage
                : null,
            icon: const Icon(Icons.send),
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
}