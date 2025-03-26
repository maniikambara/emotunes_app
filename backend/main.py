from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
from datetime import datetime
from typing import Optional, List

# Import our modules (will create these next)
from schemas import SongAnalysisRequest, SongRecommendationRequest, SongResponse
from services.spotify_service import SpotifyService
from config import Settings
import utils

# Initialize FastAPI app
app = FastAPI(
    title="EmoTunes Backend",
    description="Backend service for EmoTunes - Emotion-based music recommendation system",
    version="1.0.0"
)

# Load settings
settings = Settings()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize services
spotify_service = None

@app.on_event("startup")
async def startup_event():
    global spotify_service
    spotify_service = SpotifyService(settings)
    logger.info("EmoTunes backend started successfully")

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = datetime.utcnow()
    response = await call_next(request)
    end_time = datetime.utcnow()
    
    logger.info(
        f"Path: {request.url.path} "
        f"Method: {request.method} "
        f"Status: {response.status_code} "
        f"Duration: {(end_time - start_time).total_seconds():.3f}s"
    )
    return response

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.utcnow()}

@app.post("/analyze_song", response_model=SongResponse)
async def analyze_song(request: SongAnalysisRequest):
    """
    Analyze a song's emotional characteristics
    """
    try:
        # Will implement the analysis logic in analysis.py
        result = await utils.analyze_song_features(request.song_url)
        return result
    except Exception as e:
        logger.error(f"Error analyzing song: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/recommendations", response_model=List[SongResponse])
async def get_recommendations(request: SongRecommendationRequest):
    """
    Get song recommendations based on mood
    """
    try:
        if not spotify_service:
            raise HTTPException(status_code=503, detail="Spotify service not initialized")
        
        recommendations = await spotify_service.get_recommendations(
            mood=request.mood,
            limit=request.limit or 10
        )
        return recommendations
    except Exception as e:
        logger.error(f"Error getting recommendations: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Custom exception handler for HTTP exceptions"""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """General exception handler for unhandled exceptions"""
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)