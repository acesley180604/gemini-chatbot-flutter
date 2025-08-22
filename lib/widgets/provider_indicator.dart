import 'package:flutter/material.dart';
import '../models/api_config.dart';
import '../services/ai_service.dart';

class ProviderIndicator extends StatelessWidget {
  final AIService? service;

  const ProviderIndicator({
    super.key,
    this.service,
  });

  @override
  Widget build(BuildContext context) {
    if (service == null) {
      return const Chip(
        label: Text('Not Connected'),
        backgroundColor: Colors.grey,
      );
    }

    final config = service!.config;
    final isGemini = config.provider == AIProvider.geminiAPI;
    
    return Chip(
      avatar: Icon(
        isGemini ? Icons.auto_awesome : Icons.cloud,
        color: Colors.white,
        size: 16,
      ),
      label: Text(
        service!.serviceName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isGemini 
          ? Colors.blue[600] 
          : Colors.green[600],
    );
  }
}