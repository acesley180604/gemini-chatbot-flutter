import '../models/api_config.dart';

abstract class AIService {
  APIConfig get config;
  
  Future<String> generateResponse(String prompt);
  Future<bool> validateConfiguration();
  String get serviceName;
}

class AIServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  const AIServiceException(
    this.message, {
    this.code,
    this.originalException,
  });

  @override
  String toString() {
    return 'AIServiceException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class AuthenticationException extends AIServiceException {
  const AuthenticationException(String message, {String? code, dynamic originalException})
      : super(message, code: code, originalException: originalException);
}

class RateLimitException extends AIServiceException {
  const RateLimitException(String message, {String? code, dynamic originalException})
      : super(message, code: code, originalException: originalException);
}

class InvalidRequestException extends AIServiceException {
  const InvalidRequestException(String message, {String? code, dynamic originalException})
      : super(message, code: code, originalException: originalException);
}

class NetworkException extends AIServiceException {
  const NetworkException(String message, {String? code, dynamic originalException})
      : super(message, code: code, originalException: originalException);
}