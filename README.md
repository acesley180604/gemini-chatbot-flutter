# Gemini Chatbot Flutter

A Flutter chatbot application powered by Google's Gemini AI API.

## Features

- 🤖 Real-time chat with Google Gemini AI
- 💬 Clean Material Design UI
- 🌐 Cross-platform (Web, iOS, Android)
- 🔒 Secure API key management
- ⚡ Fast and responsive interface

## Screenshots

![Chatbot Interface](screenshot.png)

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (3.0.0 or higher)
- Google Gemini API key

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/acesley180604/gemini-chatbot-flutter.git
   cd gemini-chatbot-flutter
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Create environment file:**
   ```bash
   cp .env.example .env  # Or create .env manually
   ```

4. **Add your Gemini API key:**
   
   Edit `.env` file and add your API key:
   ```
   GEMINI_API_KEY=your_actual_gemini_api_key_here
   ```
   
   Get your API key from: [Google AI Studio](https://aistudio.google.com/app/apikey)

5. **Generate platform files (if needed):**
   ```bash
   flutter create . --project-name gemini_chatbot
   ```

## Running the App

### Web
```bash
flutter run -d chrome
```

### iOS (macOS only)
```bash
flutter run -d ios
```

### Android
```bash
flutter run -d android
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── message.dart          # Message data model
├── screens/
│   └── chat_screen.dart      # Main chat interface
├── services/
│   └── gemini_service.dart   # Gemini API integration
└── widgets/
    └── message_bubble.dart   # Chat bubble UI component
```

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

### API Key Setup

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key and add it to your `.env` file

## Troubleshooting

### Common Issues

1. **"API key not found" error:**
   - Make sure you've created the `.env` file
   - Verify the API key is correctly added without extra spaces
   - Restart the app after adding the key

2. **"Failed to generate response: 400" error:**
   - Check if your API key is valid and active
   - Ensure the Generative Language API is enabled in Google Cloud Console

3. **Flutter command not found:**
   - Make sure Flutter SDK is installed and added to your PATH
   - Run `flutter doctor` to check your installation

4. **Web CORS issues:**
   - Use `flutter run -d chrome --web-browser-flag "--disable-web-security"`

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Google Gemini AI](https://deepmind.google/technologies/gemini/) for the AI capabilities
- [Flutter](https://flutter.dev/) for the cross-platform framework
- [Material Design](https://material.io/) for the UI components