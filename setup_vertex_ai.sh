#!/bin/bash

# Vertex AI Setup Script for Gemini Chatbot
# This script helps you set up Vertex AI authentication

set -e

echo "🤖 Gemini Chatbot - Vertex AI Setup"
echo "=================================="
echo

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed."
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Get current project
current_project=$(gcloud config get project 2>/dev/null || echo "")

if [ -z "$current_project" ]; then
    echo "❌ No default project set in gcloud."
    echo "Please run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "✅ Current project: $current_project"
echo

# Ask user for setup preference
echo "Choose authentication method:"
echo "1) Service Account (Recommended for production)"
echo "2) API Key (Simpler for development)"
echo "3) Use Gemini API instead"
echo

read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo
        echo "🔐 Setting up Service Account authentication..."
        
        # Create service account
        echo "Creating service account..."
        gcloud iam service-accounts create gemini-chatbot \
            --description="Service account for Gemini chatbot" \
            --display-name="Gemini Chatbot" 2>/dev/null || echo "Service account may already exist"
        
        # Grant permissions
        echo "Granting permissions..."
        gcloud projects add-iam-policy-binding $current_project \
            --member="serviceAccount:gemini-chatbot@$current_project.iam.gserviceaccount.com" \
            --role="roles/aiplatform.user" > /dev/null
        
        # Create key
        key_path="$HOME/gemini-chatbot-key.json"
        echo "Creating service account key..."
        gcloud iam service-accounts keys create "$key_path" \
            --iam-account=gemini-chatbot@$current_project.iam.gserviceaccount.com
        
        # Create .env file
        echo "Creating .env file..."
        cat > .env << EOF
AI_PROVIDER=vertex_ai
VERTEX_AUTH_TYPE=service_account
VERTEX_SERVICE_ACCOUNT_PATH=$key_path
VERTEX_PROJECT_ID=$current_project
VERTEX_LOCATION=us-central1
VERTEX_MODEL=gemini-1.5-flash
TEMPERATURE=0.9
MAX_OUTPUT_TOKENS=2048
EOF
        
        echo "✅ Service account setup complete!"
        echo "📄 Key saved to: $key_path"
        ;;
        
    2)
        echo
        echo "🔑 Setting up API Key authentication..."
        echo
        echo "Please create an API key:"
        echo "1. Go to: https://console.cloud.google.com/apis/credentials"
        echo "2. Click 'Create Credentials' → 'API Key'"
        echo "3. Copy the generated key"
        echo
        read -p "Enter your API key: " api_key
        
        if [ -z "$api_key" ]; then
            echo "❌ No API key provided. Exiting."
            exit 1
        fi
        
        # Create .env file
        echo "Creating .env file..."
        cat > .env << EOF
AI_PROVIDER=vertex_ai
VERTEX_AUTH_TYPE=api_key
VERTEX_API_KEY=$api_key
VERTEX_PROJECT_ID=$current_project
VERTEX_LOCATION=us-central1
VERTEX_MODEL=gemini-1.5-flash
TEMPERATURE=0.9
MAX_OUTPUT_TOKENS=2048
EOF
        
        echo "✅ API Key setup complete!"
        ;;
        
    3)
        echo
        echo "🎯 Setting up Gemini API..."
        echo
        echo "Please get your Gemini API key:"
        echo "1. Go to: https://aistudio.google.com/app/apikey"
        echo "2. Create an API key"
        echo "3. Copy the generated key"
        echo
        read -p "Enter your Gemini API key: " gemini_key
        
        if [ -z "$gemini_key" ]; then
            echo "❌ No API key provided. Exiting."
            exit 1
        fi
        
        # Create .env file
        echo "Creating .env file..."
        cat > .env << EOF
AI_PROVIDER=gemini_api
GEMINI_API_KEY=$gemini_key
GEMINI_MODEL=gemini-1.5-flash-latest
TEMPERATURE=0.9
MAX_OUTPUT_TOKENS=2048
EOF
        
        echo "✅ Gemini API setup complete!"
        ;;
        
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo
echo "🚀 Setup complete! You can now run:"
echo "   flutter pub get"
echo "   flutter run"
echo
echo "📚 For more details, see VERTEX_AI_SETUP.md"