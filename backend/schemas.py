from pydantic import BaseModel, HttpUrl, Field
from typing import Optional, List
from enum import Enum

class MoodEnum(str, Enum):
    """Enumeration of possible mood categories"""
    HAPPY = "happy"
    SAD = "sad"
    ENERGETIC = "energetic"
    CALM = "calm"
    ANGRY = "angry"
    NEUTRAL = "neutral"

class SongAnalysisRequest(BaseModel):
    """Request model for song analysis"""
    song_url: HttpUrl = Field(..., description="URL of the song to analyze")
    duration: Optional[int] = Field(None, description="Duration in seconds")

    class Config:
        schema_extra = {
            "example": {
                "song_url": "https://open.spotify.com/track/example",
                "duration": 180
            }
        }

class SongRecommendationRequest(BaseModel):
    """Request model for song recommendations"""
    mood: MoodEnum = Field(..., description="Target mood for recommendations")
    limit: Optional[int] = Field(10, ge=1, le=50, description="Number of recommendations to return")
    seed_genres: Optional[List[str]] = Field(None, description="List of seed genres")
    
    class Config:
        schema_extra = {
            "example": {
                "mood": "happy",
                "limit": 10,
                "seed_genres": ["pop", "rock"]
            }
        }

class AudioFeatures(BaseModel):
    """Model for audio features extracted from a song"""
    tempo: float = Field(..., description="Tempo in BPM")
    valence: float = Field(..., ge=0, le=1, description="Musical positiveness")
    energy: float = Field(..., ge=0, le=1, description="Perceptual measure of intensity")
    danceability: float = Field(..., ge=0, le=1, description="How suitable for dancing")
    instrumentalness: float = Field(..., ge=0, le=1, description="Predicts whether a track contains no vocals")

class SongResponse(BaseModel):
    """Response model for song data"""
    id: str = Field(..., description="Song ID")
    name: str = Field(..., description="Song name")
    artist: str = Field(..., description="Artist name")
    album: str = Field(..., description="Album name")
    preview_url: Optional[HttpUrl] = Field(None, description="30-second preview URL")
    external_url: HttpUrl = Field(..., description="External URL to the full song")
    duration_ms: int = Field(..., description="Duration in milliseconds")
    audio_features: Optional[AudioFeatures] = Field(None, description="Extracted audio features")
    predicted_mood: Optional[MoodEnum] = Field(None, description="Predicted mood category")

    class Config:
        schema_extra = {
            "example": {
                "id": "spotify:track:example",
                "name": "Example Song",
                "artist": "Example Artist",
                "album": "Example Album",
                "preview_url": "https://p.scdn.co/mp3-preview/example",
                "external_url": "https://open.spotify.com/track/example",
                "duration_ms": 180000,
                "audio_features": {
                    "tempo": 120.0,
                    "valence": 0.8,
                    "energy": 0.7,
                    "danceability": 0.6,
                    "instrumentalness": 0.1
                },
                "predicted_mood": "happy"
            }
        }

class ErrorResponse(BaseModel):
    """Model for error responses"""
    detail: str = Field(..., description="Error description")

    class Config:
        schema_extra = {
            "example": {
                "detail": "An error occurred while processing the request"
            }
        }