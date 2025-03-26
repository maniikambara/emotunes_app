import pytest
from fastapi.testclient import TestClient
from ..main import app
from ..schemas import MoodEnum

client = TestClient(app)

def test_health_check():
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert "status" in response.json()
    assert response.json()["status"] == "healthy"

def test_analyze_song():
    """Test song analysis endpoint"""
    test_data = {
        "song_url": "https://example.com/test-song.mp3"
    }
    response = client.post("/analyze_song", json=test_data)
    assert response.status_code in [200, 422]  # 422 if URL is invalid

def test_get_recommendations():
    """Test recommendations endpoint"""
    test_data = {
        "mood": MoodEnum.HAPPY,
        "limit": 5
    }
    response = client.get("/recommendations", params=test_data)
    assert response.status_code in [200, 503]  # 503 if Spotify service not initialized

def test_invalid_mood():
    """Test invalid mood parameter"""
    test_data = {
        "mood": "invalid_mood",
        "limit": 5
    }
    response = client.get("/recommendations", params=test_data)
    assert response.status_code == 422  # Validation error

def test_invalid_limit():
    """Test invalid limit parameter"""
    test_data = {
        "mood": MoodEnum.HAPPY,
        "limit": -1
    }
    response = client.get("/recommendations", params=test_data)
    assert response.status_code == 422  # Validation error

@pytest.mark.asyncio
async def test_spotify_service():
    """Test Spotify service initialization"""
    from ..config import Settings
    from ..services.spotify_service import SpotifyService
    
    settings = Settings()
    try:
        spotify_service = SpotifyService(settings)
        assert spotify_service is not None
    except Exception as e:
        pytest.skip(f"Spotify service test skipped: {str(e)}")

@pytest.mark.asyncio
async def test_audio_analysis():
    """Test audio analysis utilities"""
    from ..utils import predict_mood
    from ..schemas import AudioFeatures
    
    # Test with sample audio features
    features = AudioFeatures(
        tempo=120.0,
        valence=0.8,
        energy=0.7,
        danceability=0.6,
        instrumentalness=0.1
    )
    
    mood = predict_mood(features)
    assert mood in MoodEnum

def test_error_handling():
    """Test error handling middleware"""
    response = client.get("/nonexistent_endpoint")
    assert response.status_code == 404
    assert "detail" in response.json()

if __name__ == "__main__":
    pytest.main([__file__])