import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import logging
from typing import List, Dict, Optional
import asyncio
from datetime import datetime, timedelta

from ..schemas import SongResponse, AudioFeatures, MoodEnum
from ..config import Settings

logger = logging.getLogger(__name__)

class SpotifyService:
    """Service for interacting with Spotify API"""
    
    # Mood to audio features mapping
    MOOD_FEATURES = {
        MoodEnum.HAPPY: {"valence": (0.6, 1.0), "energy": (0.6, 1.0)},
        MoodEnum.SAD: {"valence": (0.0, 0.4), "energy": (0.0, 0.4)},
        MoodEnum.ENERGETIC: {"valence": (0.5, 1.0), "energy": (0.8, 1.0)},
        MoodEnum.CALM: {"valence": (0.3, 0.7), "energy": (0.0, 0.3)},
        MoodEnum.ANGRY: {"valence": (0.0, 0.4), "energy": (0.8, 1.0)},
        MoodEnum.NEUTRAL: {"valence": (0.4, 0.6), "energy": (0.4, 0.6)}
    }

    def __init__(self, settings: Settings):
        """Initialize Spotify client with credentials"""
        credentials = settings.get_spotify_credentials()
        self.client_credentials_manager = SpotifyClientCredentials(
            client_id=credentials["client_id"],
            client_secret=credentials["client_secret"]
        )
        self.sp = spotipy.Spotify(client_credentials_manager=self.client_credentials_manager)
        self.cache = {}
        self.cache_ttl = timedelta(seconds=settings.CACHE_TTL)
        self.max_cache_size = settings.MAX_CACHE_SIZE

    def _clean_cache(self):
        """Remove expired cache entries"""
        now = datetime.utcnow()
        expired = [k for k, v in self.cache.items() if now - v["timestamp"] > self.cache_ttl]
        for k in expired:
            del self.cache[k]

        # If cache is still too large, remove oldest entries
        if len(self.cache) > self.max_cache_size:
            sorted_cache = sorted(self.cache.items(), key=lambda x: x[1]["timestamp"])
            to_remove = len(self.cache) - self.max_cache_size
            for k, _ in sorted_cache[:to_remove]:
                del self.cache[k]

    def _get_cached(self, key: str) -> Optional[dict]:
        """Get value from cache if not expired"""
        if key in self.cache:
            entry = self.cache[key]
            if datetime.utcnow() - entry["timestamp"] <= self.cache_ttl:
                return entry["data"]
            del self.cache[key]
        return None

    def _set_cached(self, key: str, value: dict):
        """Set value in cache with timestamp"""
        self._clean_cache()
        self.cache[key] = {
            "data": value,
            "timestamp": datetime.utcnow()
        }

    async def get_audio_features(self, track_id: str) -> Optional[AudioFeatures]:
        """Get audio features for a track"""
        try:
            cache_key = f"audio_features_{track_id}"
            cached = self._get_cached(cache_key)
            if cached:
                return AudioFeatures(**cached)

            features = self.sp.audio_features([track_id])[0]
            if not features:
                return None

            audio_features = AudioFeatures(
                tempo=features["tempo"],
                valence=features["valence"],
                energy=features["energy"],
                danceability=features["danceability"],
                instrumentalness=features["instrumentalness"]
            )
            
            self._set_cached(cache_key, audio_features.dict())
            return audio_features
        except Exception as e:
            logger.error(f"Error getting audio features for track {track_id}: {str(e)}")
            return None

    def _matches_mood(self, features: Dict[str, float], mood: MoodEnum) -> bool:
        """Check if audio features match the given mood"""
        mood_ranges = self.MOOD_FEATURES[mood]
        for feature, (min_val, max_val) in mood_ranges.items():
            if feature in features:
                if not (min_val <= features[feature] <= max_val):
                    return False
        return True

    async def get_recommendations(
        self,
        mood: MoodEnum,
        limit: int = 10,
        seed_genres: Optional[List[str]] = None
    ) -> List[SongResponse]:
        """Get song recommendations based on mood"""
        try:
            cache_key = f"recommendations_{mood}_{limit}_{seed_genres}"
            cached = self._get_cached(cache_key)
            if cached:
                return [SongResponse(**track) for track in cached]

            # Get seed genres if not provided
            if not seed_genres:
                available_genres = self.sp.recommendation_genre_seeds()
                seed_genres = available_genres[:5]  # Spotify allows max 5 seed genres

            # Get recommendations with mood-based audio feature targets
            mood_features = self.MOOD_FEATURES[mood]
            recommendations = self.sp.recommendations(
                seed_genres=seed_genres,
                limit=limit * 2,  # Request more tracks to filter
                target_valence=(mood_features["valence"][0] + mood_features["valence"][1]) / 2,
                target_energy=(mood_features["energy"][0] + mood_features["energy"][1]) / 2
            )

            # Process recommendations
            results = []
            for track in recommendations["tracks"]:
                # Get audio features
                features = await self.get_audio_features(track["id"])
                if not features or not self._matches_mood(features.dict(), mood):
                    continue

                response = SongResponse(
                    id=track["id"],
                    name=track["name"],
                    artist=track["artists"][0]["name"],
                    album=track["album"]["name"],
                    preview_url=track["preview_url"],
                    external_url=track["external_urls"]["spotify"],
                    duration_ms=track["duration_ms"],
                    audio_features=features,
                    predicted_mood=mood
                )
                results.append(response)
                
                if len(results) >= limit:
                    break

            self._set_cached(cache_key, [r.dict() for r in results])
            return results

        except Exception as e:
            logger.error(f"Error getting recommendations: {str(e)}")
            raise

    async def get_track_info(self, track_id: str) -> Optional[SongResponse]:
        """Get detailed information about a specific track"""
        try:
            cache_key = f"track_info_{track_id}"
            cached = self._get_cached(cache_key)
            if cached:
                return SongResponse(**cached)

            track = self.sp.track(track_id)
            features = await self.get_audio_features(track_id)

            if not track or not features:
                return None

            # Determine mood based on audio features
            predicted_mood = None
            for mood, ranges in self.MOOD_FEATURES.items():
                if self._matches_mood(features.dict(), mood):
                    predicted_mood = mood
                    break

            response = SongResponse(
                id=track["id"],
                name=track["name"],
                artist=track["artists"][0]["name"],
                album=track["album"]["name"],
                preview_url=track["preview_url"],
                external_url=track["external_urls"]["spotify"],
                duration_ms=track["duration_ms"],
                audio_features=features,
                predicted_mood=predicted_mood
            )

            self._set_cached(cache_key, response.dict())
            return response

        except Exception as e:
            logger.error(f"Error getting track info for {track_id}: {str(e)}")
            return None