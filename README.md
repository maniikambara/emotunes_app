# EmoTunes - Emotion-Based Music Recommendation App

EmoTunes is a cross-platform application that recommends music based on your emotional state, detected through facial expressions. The app uses machine learning to analyze facial expressions in real-time and suggests music that matches or complements your current mood.

## Features

- Real-time facial emotion detection using TensorFlow Lite
- Music recommendations based on detected emotions
- Integration with Spotify for music playback
- Modern, intuitive UI with Flutter
- FastAPI backend for robust music analysis and recommendations

## Project Structure

```
└── emotunes_app/           # Flutter mobile application
    ├── lib/                # Application source code
    │   ├── screens/        # UI screens
    │   ├── services/       # Business logic
    │   └── themes/         # App theming
    ├── assets/             # Static assets
    │   └── models/         # TFLite models
    ├── backend/                # FastAPI backend service
        ├── main.py             # Main application entry point
        ├── services/           # Service layer (Spotify, analysis)
        ├── schemas.py          # Data models and validation
        └── utils.py            # Utility functions
```

## Prerequisites

- Python 3.8+
- Flutter 2.17+
- Spotify Developer Account
- Node.js 14+ (for development)

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/maniikambara/emotunes_app.git
   cd emotunes
   ```

2. Set up the backend:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   cp .env.example .env     # Configure your environment variables
   ```

3. Set up the Flutter app:
   ```bash
   cd ..
   flutter pub get
   cp .env.example .env     # Configure your environment variables
   ```

4. Configure Spotify API:
   - Create a Spotify Developer account
   - Create a new application
   - Add the client ID and secret to both .env files

## Running the Application

1. Start the backend server:
   ```bash
   cd backend
   uvicorn main:app --reload
   ```

2. Run the Flutter app:
   ```bash
   cd emotunes_app
   flutter run
   ```

## Development

- Backend API documentation available at `http://localhost:8000/docs`
- Run tests with `pytest` for backend and `flutter test` for the app
- Follow the contribution guidelines in CONTRIBUTING.md

## Architecture

### Backend

- FastAPI for high-performance API endpoints
- Librosa for audio feature extraction
- Spotipy for Spotify API integration
- Pydantic for data validation

### Mobile App

- Flutter for cross-platform development
- Provider for state management
- TensorFlow Lite for on-device inference
- Camera plugin for real-time video processing

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- TensorFlow team for TFLite
- Spotify for their comprehensive API
- Flutter and FastAPI communities
- Contributors and maintainers

## Contact

For questions or support, please open an issue in the repository.