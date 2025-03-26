# EmoTunes Backend

EmoTunes is an emotion-based music recommendation system that uses facial expression detection and audio analysis to suggest songs matching the user's mood.

## Features

- Real-time facial expression detection
- Audio feature analysis using Librosa
- Integration with Spotify API for music recommendations
- Mood-based song filtering
- Caching system for improved performance
- Comprehensive error handling and logging

## Prerequisites

- Python 3.8+
- Spotify Developer Account (for API credentials)
- Poetry (recommended) or pip for dependency management

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd emotunes/backend
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Create and configure the `.env` file:
```bash
cp .env.example .env
```
Then edit `.env` with your Spotify API credentials and other configuration settings.

## Configuration

The following environment variables need to be set in the `.env` file:

```env
# API Configuration
DEBUG=True/False
API_V1_STR=/api/v1
PROJECT_NAME=EmoTunes

# Spotify API Configuration
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
SPOTIFY_REDIRECT_URI=http://localhost:8000/callback

# Other configurations as needed
```

## Running the Application

1. Start the FastAPI server:
```bash
uvicorn main:app --reload --port 8000
```

2. Access the API documentation:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API Endpoints

### Health Check
```
GET /health
```
Returns the current status of the service.

### Analyze Song
```
POST /analyze_song
```
Analyzes the audio features of a song and predicts its emotional characteristics.

### Get Recommendations
```
GET /recommendations
```
Returns song recommendations based on the specified mood.

## Testing

Run the test suite:
```bash
pytest
```

## Project Structure

```
backend/
├── main.py              # FastAPI application entry point
├── config.py            # Configuration settings
├── schemas.py           # Pydantic models
├── utils.py             # Utility functions
├── requirements.txt     # Project dependencies
├── tests/              # Test files
│   └── test_api.py     # API tests
└── services/           # Service modules
    └── spotify_service.py  # Spotify API integration
```

## Error Handling

The application includes comprehensive error handling for:
- Invalid API requests
- Network issues
- Authentication failures
- Resource limitations
- File processing errors

## Caching

The application implements a caching system for:
- Spotify API responses
- Audio feature analysis results
- Frequently requested recommendations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.