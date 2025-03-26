import logging
import librosa
import numpy as np
from typing import Dict, Optional, Tuple
import aiohttp
import tempfile
import os
from datetime import datetime

from schemas import AudioFeatures, MoodEnum

logger = logging.getLogger(__name__)

async def download_audio(url: str) -> Optional[str]:
    """
    Download audio file from URL to temporary file
    Returns path to temporary file if successful, None otherwise
    """
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url) as response:
                if response.status != 200:
                    logger.error(f"Failed to download audio: HTTP {response.status}")
                    return None
                
                # Create temporary file
                temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.mp3')
                temp_path = temp_file.name
                
                # Write content to temporary file
                with open(temp_path, 'wb') as f:
                    while True:
                        chunk = await response.content.read(8192)
                        if not chunk:
                            break
                        f.write(chunk)
                
                return temp_path
    except Exception as e:
        logger.error(f"Error downloading audio: {str(e)}")
        return None

def extract_audio_features(audio_path: str, sr: int = 22050) -> Optional[Dict[str, float]]:
    """
    Extract audio features from file using librosa
    Returns dictionary of features if successful, None otherwise
    """
    try:
        # Load audio file
        y, sr = librosa.load(audio_path, sr=sr)
        
        # Extract features
        tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
        
        # Spectral features
        spectral_centroids = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
        spectral_rolloff = librosa.feature.spectral_rolloff(y=y, sr=sr)[0]
        
        # Energy
        energy = np.mean(librosa.feature.rms(y=y)[0])
        
        # Normalize energy to 0-1 range
        energy = min(energy / 0.2, 1.0)  # 0.2 is a reasonable maximum energy value
        
        # Calculate "valence" (musical positiveness) using spectral features
        # This is a simplified approximation
        valence = np.mean([
            np.mean(spectral_centroids) / (sr/2),  # Normalize by Nyquist frequency
            np.mean(spectral_rolloff) / (sr/2)
        ])
        valence = min(valence, 1.0)
        
        # Calculate danceability using tempo and rhythm regularity
        tempo_normalized = min(tempo / 200.0, 1.0)  # Normalize tempo (assuming max 200 BPM)
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        pulse = librosa.beat.plp(onset_envelope=onset_env, sr=sr)
        rhythm_regularity = np.mean(pulse)
        danceability = np.mean([tempo_normalized, rhythm_regularity])
        
        # Calculate instrumentalness using MFCC variance
        mfccs = librosa.feature.mfcc(y=y, sr=sr)
        instrumentalness = min(np.var(mfccs) / 100.0, 1.0)  # Normalize variance
        
        return {
            "tempo": float(tempo),
            "valence": float(valence),
            "energy": float(energy),
            "danceability": float(danceability),
            "instrumentalness": float(instrumentalness)
        }
    except Exception as e:
        logger.error(f"Error extracting audio features: {str(e)}")
        return None
    finally:
        # Clean up temporary file
        try:
            os.remove(audio_path)
        except:
            pass

def predict_mood(features: AudioFeatures) -> Optional[MoodEnum]:
    """
    Predict mood based on audio features
    Uses a simple rule-based system - could be replaced with ML model
    """
    try:
        # Convert features to normalized values
        valence = features.valence
        energy = features.energy
        
        # Simple rule-based classification
        if valence > 0.6 and energy > 0.6:
            return MoodEnum.HAPPY
        elif valence < 0.4 and energy < 0.4:
            return MoodEnum.SAD
        elif energy > 0.8:
            return MoodEnum.ENERGETIC
        elif energy < 0.3:
            return MoodEnum.CALM
        elif valence < 0.4 and energy > 0.8:
            return MoodEnum.ANGRY
        else:
            return MoodEnum.NEUTRAL
            
    except Exception as e:
        logger.error(f"Error predicting mood: {str(e)}")
        return None

async def analyze_song_features(song_url: str) -> Optional[Dict[str, float]]:
    """
    Analyze song features from URL
    Downloads song, extracts features, and predicts mood
    """
    try:
        # Download audio file
        temp_path = await download_audio(song_url)
        if not temp_path:
            return None
            
        # Extract features
        features = extract_audio_features(temp_path)
        if not features:
            return None
            
        # Create AudioFeatures object
        audio_features = AudioFeatures(**features)
        
        # Predict mood
        mood = predict_mood(audio_features)
        
        # Return combined results
        return {
            **features,
            "predicted_mood": mood.value if mood else None
        }
        
    except Exception as e:
        logger.error(f"Error analyzing song: {str(e)}")
        return None

def format_duration(ms: int) -> str:
    """Format milliseconds duration as MM:SS string"""
    seconds = ms // 1000
    minutes = seconds // 60
    seconds = seconds % 60
    return f"{minutes:02d}:{seconds:02d}"

def get_timestamp() -> str:
    """Get current timestamp in ISO format"""
    return datetime.utcnow().isoformat()

def validate_audio_file(file_path: str, max_size_mb: int = 10) -> Tuple[bool, str]:
    """
    Validate audio file
    Returns (is_valid, error_message)
    """
    try:
        # Check file size
        size_mb = os.path.getsize(file_path) / (1024 * 1024)
        if size_mb > max_size_mb:
            return False, f"File size exceeds maximum allowed size of {max_size_mb}MB"
            
        # Check if file is valid audio
        y, sr = librosa.load(file_path, duration=1)  # Load first second only
        return True, ""
        
    except Exception as e:
        return False, f"Invalid audio file: {str(e)}"