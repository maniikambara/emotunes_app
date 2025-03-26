from pydantic import BaseSettings, HttpUrl, SecretStr
from typing import Optional, List
from functools import lru_cache

class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # API Configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "EmoTunes"
    DEBUG: bool = False
    
    # CORS Configuration
    BACKEND_CORS_ORIGINS: List[str] = ["*"]  # In production, replace with specific origins
    
    # Spotify API Configuration
    SPOTIFY_CLIENT_ID: SecretStr
    SPOTIFY_CLIENT_SECRET: SecretStr
    SPOTIFY_REDIRECT_URI: HttpUrl
    
    # Model Configuration
    MODEL_PATH: str = "models/emotion_detection.tflite"
    CONFIDENCE_THRESHOLD: float = 0.7
    
    # Audio Analysis Configuration
    MAX_AUDIO_SIZE_MB: int = 10
    SUPPORTED_AUDIO_FORMATS: List[str] = ["mp3", "wav"]
    SAMPLE_RATE: int = 22050
    HOP_LENGTH: int = 512
    
    # Cache Configuration
    CACHE_TTL: int = 3600  # 1 hour in seconds
    MAX_CACHE_SIZE: int = 1000
    
    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Security Configuration
    API_KEY_NAME: str = "X-API-Key"
    API_KEY: Optional[SecretStr] = None
    
    class Config:
        case_sensitive = True
        env_file = ".env"
        env_file_encoding = "utf-8"

    def get_spotify_credentials(self) -> dict:
        """Return Spotify API credentials"""
        return {
            "client_id": self.SPOTIFY_CLIENT_ID.get_secret_value(),
            "client_secret": self.SPOTIFY_CLIENT_SECRET.get_secret_value(),
            "redirect_uri": str(self.SPOTIFY_REDIRECT_URI)
        }

@lru_cache()
def get_settings() -> Settings:
    """Create cached instance of settings"""
    return Settings()

# Example .env file template
ENV_TEMPLATE = """
# API Configuration
DEBUG=False
API_V1_STR=/api/v1
PROJECT_NAME=EmoTunes

# CORS Configuration
BACKEND_CORS_ORIGINS=["http://localhost:3000"]

# Spotify API Configuration
SPOTIFY_CLIENT_ID=your_client_id_here
SPOTIFY_CLIENT_SECRET=your_client_secret_here
SPOTIFY_REDIRECT_URI=http://localhost:8000/callback

# Model Configuration
MODEL_PATH=models/emotion_detection.tflite
CONFIDENCE_THRESHOLD=0.7

# Audio Analysis Configuration
MAX_AUDIO_SIZE_MB=10
SAMPLE_RATE=22050
HOP_LENGTH=512

# Cache Configuration
CACHE_TTL=3600
MAX_CACHE_SIZE=1000

# Logging Configuration
LOG_LEVEL=INFO

# Security Configuration
API_KEY=your_api_key_here
"""

# Create a sample .env file if it doesn't exist
def create_env_file():
    """Create a sample .env file with default values"""
    import os
    if not os.path.exists(".env"):
        with open(".env", "w") as f:
            f.write(ENV_TEMPLATE.strip())
        print("Created sample .env file. Please update with your actual values.")

if __name__ == "__main__":
    create_env_file()