# Gemini Chatbot Flutter

A Flutter chatbot application with dual AI provider support: **Google Gemini API** and **Google Vertex AI**.

## ✨ Features

- 🤖 **Dual AI Provider Support** - Switch between Gemini API and Vertex AI
- 🔐 **Multiple Authentication Methods** - API keys and Service Account authentication
- 💬 **Modern Material Design UI** - Clean, responsive interface
- 📱 **Mobile & Web Ready** - iOS, Android, and Web support
- 🛡️ **Enterprise-Ready** - Production logging, error handling, and validation
- ⚡ **Fast and Responsive** - Optimized for performance
- 🔄 **Auto-Recovery** - Smart retry mechanisms and connection management

## 🏗️ Architecture

```
lib/
├── main.dart                     # App entry point with logging setup
├── models/
│   ├── api_config.dart          # Configuration model for both providers
│   └── message.dart             # Message data model
├── screens/
│   └── chat_screen.dart         # Enhanced chat interface
├── services/
│   ├── ai_service.dart          # Abstract service interface
│   ├── gemini_api_service.dart  # Gemini API implementation
│   ├── vertex_ai_service.dart   # Vertex AI implementation
│   ├── service_factory.dart     # Dynamic service creation
│   └── gemini_service.dart      # Legacy compatibility layer
└── widgets/
    └── message_bubble.dart      # Chat bubble UI component
```

## 🚀 Quick Start

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10.0+)
- [Dart SDK](https://dart.dev/get-dart) (3.0.0+)
- Google Cloud Project (for Vertex AI) or Gemini API key

### Installation

1. **Clone and setup:**
   ```bash
   git clone https://github.com/acesley180604/gemini-chatbot-flutter.git
   cd gemini-chatbot-flutter
   flutter pub get
   ```

2. **Choose your configuration:**

   **Option A: Gemini API (Simplest)**
   ```bash
   cp .env.gemini.example .env
   # Edit .env and add your Gemini API key
   ```

   **Option B: Vertex AI (Enterprise)**
   ```bash
   cp .env.vertex.example .env
   # Edit .env and configure Vertex AI settings
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## ⚙️ Configuration

### 🔑 Gemini API Setup

1. Get your API key from [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create `.env` file:
   ```env
   AI_PROVIDER=gemini_api
   GEMINI_API_KEY=your_api_key_here
   GEMINI_MODEL=gemini-1.5-flash-latest
   TEMPERATURE=0.9
   MAX_OUTPUT_TOKENS=2048
   ```

### 🏢 Vertex AI Setup

#### Service Account Authentication (Recommended)

1. Create a Google Cloud Project
2. Enable the Vertex AI API
3. Create a service account with Vertex AI permissions
4. Download the service account JSON file
5. Configure `.env`:
   ```env
   AI_PROVIDER=vertex_ai
   VERTEX_AUTH_TYPE=service_account
   VERTEX_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
   VERTEX_PROJECT_ID=your-project-id
   VERTEX_LOCATION=us-central1
   VERTEX_MODEL=gemini-1.5-flash
   TEMPERATURE=0.9
   MAX_OUTPUT_TOKENS=2048
   ```

#### API Key Authentication (Alternative)

```env
AI_PROVIDER=vertex_ai
VERTEX_AUTH_TYPE=api_key
VERTEX_API_KEY=your_vertex_api_key
VERTEX_PROJECT_ID=your-project-id
VERTEX_LOCATION=us-central1
VERTEX_MODEL=gemini-1.5-flash
```

## 🔧 Environment Variables Reference

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `AI_PROVIDER` | Service provider (`gemini_api` or `vertex_ai`) | No | `gemini_api` |
| `GEMINI_API_KEY` | Gemini API key | Yes (Gemini) | - |
| `GEMINI_MODEL` | Gemini model name | No | `gemini-1.5-flash-latest` |
| `VERTEX_AUTH_TYPE` | Vertex auth type (`api_key` or `service_account`) | No | `service_account` |
| `VERTEX_API_KEY` | Vertex AI API key | Yes (Vertex + API key) | - |
| `VERTEX_SERVICE_ACCOUNT_PATH` | Path to service account JSON | Yes (Vertex + SA) | - |
| `VERTEX_PROJECT_ID` | Google Cloud Project ID | Yes (Vertex) | - |
| `VERTEX_LOCATION` | Vertex AI region | No | `us-central1` |
| `VERTEX_MODEL` | Vertex AI model name | No | `gemini-1.5-flash` |
| `TEMPERATURE` | Response creativity (0.0-1.0) | No | `0.9` |
| `MAX_OUTPUT_TOKENS` | Maximum response length | No | `2048` |

## 🛠️ Advanced Usage

### Programmatic Service Creation

```dart
import 'services/service_factory.dart';
import 'services/ai_service.dart';

// Create service with auto-detection
final service = AIServiceFactory.createService();

// Create and validate service
final validatedService = await AIServiceFactory.createAndValidateService();

// Custom configuration
final customConfig = APIConfig(
  provider: AIProvider.vertexAI,
  authType: AuthType.serviceAccount,
  serviceAccountPath: '/path/to/key.json',
  projectId: 'my-project',
);
final customService = AIServiceFactory.createService(config: customConfig);
```

### Error Handling

The app includes comprehensive error handling for:

- **Authentication errors** - Invalid API keys or credentials
- **Rate limiting** - Automatic retry suggestions
- **Network issues** - Connection problem detection
- **Invalid requests** - Request format validation
- **Service errors** - Provider-specific error handling

## 🏃 Running the App

### Development
```bash
# Web
flutter run -d chrome

# iOS (macOS only)
flutter run -d ios

# Android
flutter run -d android
```

### Production Build
```bash
# Web
flutter build web

# iOS
flutter build ios --release

# Android
flutter build apk --release
```

## 🔍 Troubleshooting

### Common Issues

**Authentication Errors:**
- ✅ Verify API keys are correct and active
- ✅ Check service account has proper permissions
- ✅ Ensure service account JSON file path is correct

**Network/Connection Issues:**
- ✅ Check internet connectivity
- ✅ Verify firewall settings
- ✅ For web: use `--web-browser-flag "--disable-web-security"`

**Configuration Issues:**
- ✅ Verify all required environment variables are set
- ✅ Check `.env` file format and syntax
- ✅ Restart app after configuration changes

**Vertex AI Specific:**
- ✅ Enable Vertex AI API in Google Cloud Console
- ✅ Check project ID and location settings
- ✅ Verify service account permissions

### Debug Logging

The app includes comprehensive logging. Check the console for detailed error messages with 🔴 (errors), 🟡 (warnings), and 🔵 (info) indicators.

## 🎯 Migration from v1.0

The app maintains backward compatibility. Existing `.env` files with only `GEMINI_API_KEY` will continue to work without changes.

To upgrade to the new architecture:
1. Add `AI_PROVIDER=gemini_api` to your `.env` file
2. Optionally migrate to the new service factory pattern

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Google Gemini AI](https://deepmind.google/technologies/gemini/) for AI capabilities
- [Google Vertex AI](https://cloud.google.com/vertex-ai) for enterprise AI platform
- [Flutter](https://flutter.dev/) for the cross-platform framework
- [Material Design](https://material.io/) for UI components