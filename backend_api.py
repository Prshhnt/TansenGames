"""
FastAPI wrapper for the Fitgirl scraper backend.
This keeps all scraping logic in Python while exposing HTTP endpoints for Flutter.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import uvicorn

# Import the new scraping functions with PrivateBin decryption support
from fetch_fitgirl import (
    search_fitgirl,
    fetch_download_links,
    decrypt_privatebin_paste,
    fetch_fuckingfast_page,
    fetch_popular_repacks,
    fetch_game_metadata,
    fetch_home,
    fetch_home_latest,
    fetch_upcoming_list,
)

app = FastAPI(title="Fitgirl Scraper API", version="1.0.0")

# Enable CORS for local Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Response models for type safety and documentation
class ArticleLink(BaseModel):
    """Represents a search result article"""
    title: str
    url: str
    poster_url: Optional[str] = None

class DownloadLink(BaseModel):
    """Represents a download link from an article page"""
    text: str
    url: str

class SearchResponse(BaseModel):
    """Response for search endpoint"""
    success: bool
    data: Optional[List[ArticleLink]] = None
    error: Optional[str] = None
    count: int = 0

class DownloadLinksResponse(BaseModel):
    """Response for download links endpoint"""
    success: bool
    data: Optional[List[DownloadLink]] = None
    error: Optional[str] = None
    count: int = 0

class DecryptPasteResponse(BaseModel):
    """Response for decrypt paste endpoint"""
    success: bool
    data: Optional[List[str]] = None
    error: Optional[str] = None
    count: int = 0

class FuckingFastButtonsResponse(BaseModel):
    """Response for FuckingFast download buttons extraction"""
    success: bool
    data: Optional[List[DownloadLink]] = None
    error: Optional[str] = None
    count: int = 0

class GameMetadata(BaseModel):
    """Comprehensive game metadata"""
    url: str
    title: str
    full_title: str
    update_number: str
    poster_url: str
    genres: List[str]
    companies: str
    languages: str
    requirements: str
    original_size: str
    repack_size: str
    selective_download: bool
    repack_features: List[str]
    published_date: str
    modified_date: str
    description: str

class GameMetadataResponse(BaseModel):
    """Response for game metadata endpoint"""
    success: bool
    data: Optional[GameMetadata] = None
    error: Optional[str] = None


class HomeItem(BaseModel):
    title: str
    url: str
    image: Optional[str] = None
    version: Optional[str] = None
    published_date: Optional[str] = None
    repack_size: Optional[str] = None


class HomeData(BaseModel):
    featured: Optional[HomeItem] = None
    latest: List[HomeItem] = []
    upcoming: List[str] = []
    popular: List[ArticleLink] = []


class HomeResponse(BaseModel):
    success: bool
    data: Optional[HomeData] = None
    error: Optional[str] = None


class HomeListResponse(BaseModel):
    success: bool
    data: Optional[List[HomeItem]] = None
    error: Optional[str] = None
    count: int = 0


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "message": "Fitgirl Scraper API is running",
        "version": "1.0.0"
    }


@app.get("/api/popular-repacks", response_model=SearchResponse)
async def get_popular_repacks(force_refresh: bool = False, image_size: str = "medium"):
    """
    Fetch popular repacks from Fitgirl Repacks
    
    Returns:
        SearchResponse with list of popular article links
    
    Example:
        GET /api/popular-repacks
    """
    try:
        # Call the popular repacks function
        if image_size not in {"thumb", "medium", "full"}:
            raise HTTPException(status_code=400, detail="image_size must be 'thumb', 'medium', or 'full'")
        links = fetch_popular_repacks(force_refresh=force_refresh, image_size=image_size)
        
        if links is None:
            return SearchResponse(
                success=False,
                error="Failed to fetch popular repacks. Please check your connection.",
                count=0
            )
        
        # Convert to response format
        article_links = [ArticleLink(**link) for link in links]
        
        return SearchResponse(
            success=True,
            data=article_links,
            count=len(article_links)
        )
        
    except Exception as e:
        return SearchResponse(
            success=False,
            error=f"An unexpected error occurred: {str(e)}",
            count=0
        )


@app.get("/api/search", response_model=SearchResponse)
async def search(query: str):
    """
    Search Fitgirl Repacks for games
    
    Args:
        query: Search term (e.g., "resident evil")
    
    Returns:
        SearchResponse with list of article links
    
    Example:
        GET /api/search?query=resident+evil
    """
    if not query or not query.strip():
        raise HTTPException(status_code=400, detail="Search query cannot be empty")
    
    try:
        # Call the existing Python function (unchanged logic)
        links = search_fitgirl(query.strip())
        
        if links is None:
            return SearchResponse(
                success=False,
                error="Failed to fetch search results. Please check your connection.",
                count=0
            )
        
        # Convert to response format
        articles = [ArticleLink(**link) for link in links]
        
        return SearchResponse(
            success=True,
            data=articles,
            count=len(articles)
        )
        
    except Exception as e:
        return SearchResponse(
            success=False,
            error=f"An unexpected error occurred: {str(e)}",
            count=0
        )


@app.get("/api/download-links", response_model=DownloadLinksResponse)
async def get_download_links(page_url: str):
    """
    Fetch download links from a specific article page
    
    Args:
        page_url: Full URL of the article page
    
    Returns:
        DownloadLinksResponse with list of download links
    
    Example:
        GET /api/download-links?page_url=https://fitgirl-repacks.site/...
    """
    if not page_url or not page_url.strip():
        raise HTTPException(status_code=400, detail="Page URL cannot be empty")
    
    # Basic URL validation
    if not page_url.startswith("http"):
        raise HTTPException(status_code=400, detail="Invalid URL format")
    
    try:
        # Call the existing Python function (unchanged logic)
        links = fetch_download_links(page_url.strip())
        
        if links is None:
            return DownloadLinksResponse(
                success=False,
                error="Failed to fetch download links. Please check the URL.",
                count=0
            )
        
        # Convert to response format
        downloads = [DownloadLink(**link) for link in links]
        
        return DownloadLinksResponse(
            success=True,
            data=downloads,
            count=len(downloads)
        )
        
    except Exception as e:
        return DownloadLinksResponse(
            success=False,
            error=f"An unexpected error occurred: {str(e)}",
            count=0
        )


@app.get("/api/decrypt-paste", response_model=DecryptPasteResponse)
async def decrypt_paste(paste_url: str):
    """
    Decrypt PrivateBin paste and extract download URLs
    
    Args:
        paste_url: Full URL of the PrivateBin paste (must include #key)
    
    Returns:
        DecryptPasteResponse with list of extracted URLs
    
    Example:
        GET /api/decrypt-paste?paste_url=https://paste.fitgirl-repacks.site/?...#key
    """
    if not paste_url or not paste_url.strip():
        raise HTTPException(status_code=400, detail="Paste URL cannot be empty")
    
    # Check if URL contains encryption key
    if '#' not in paste_url:
        raise HTTPException(status_code=400, detail="Paste URL must contain encryption key (#key)")
    
    try:
        # Call the decryption function
        urls = decrypt_privatebin_paste(paste_url.strip())
        
        if urls is None:
            return DecryptPasteResponse(
                success=False,
                error="Failed to decrypt paste. The key might be invalid.",
                count=0
            )
        
        return DecryptPasteResponse(
            success=True,
            data=urls,
            count=len(urls)
        )
        
    except Exception as e:
        return DecryptPasteResponse(
            success=False,
            error=f"An unexpected error occurred: {str(e)}",
            count=0
        )


@app.get("/api/extract-fuckingfast", response_model=FuckingFastButtonsResponse)
async def extract_fuckingfast_buttons(fuckingfast_url: str):
    """
    Extract actual download buttons from FuckingFast page
    
    Args:
        fuckingfast_url: FuckingFast URL (e.g., https://fuckingfast.co/...)
    
    Returns:
        FuckingFastButtonsResponse with extracted download buttons
    
    Example:
        GET /api/extract-fuckingfast?fuckingfast_url=https://fuckingfast.co/...
    """
    if not fuckingfast_url or not fuckingfast_url.strip():
        raise HTTPException(status_code=400, detail="FuckingFast URL cannot be empty")
    
    if 'fuckingfast' not in fuckingfast_url.lower():
        raise HTTPException(status_code=400, detail="Invalid FuckingFast URL")
    
    try:
        # Call the extraction function
        buttons = fetch_fuckingfast_page(fuckingfast_url.strip(), save_html=False)
        
        if buttons is None:
            return FuckingFastButtonsResponse(
                success=False,
                error="Failed to extract download buttons from FuckingFast page.",
                count=0
            )
        
        # Convert to response format
        download_links = [DownloadLink(**btn) for btn in buttons]
        
        return FuckingFastButtonsResponse(
            success=True,
            data=download_links,
            count=len(download_links)
        )
        
    except Exception as e:
        return FuckingFastButtonsResponse(
            success=False,
            error=f"An unexpected error occurred: {str(e)}",
            count=0
        )

@app.get("/api/game-metadata", response_model=GameMetadataResponse)
async def get_game_metadata(page_url: str, force_refresh: bool = False, image_size: str = "medium"):
    """
    Fetch comprehensive game metadata from a Fitgirl repack page
    
    Args:
        page_url: Full URL of the game page
    
    Returns:
        GameMetadataResponse with complete game metadata including:
        - Poster image URL
        - Genres and tags
        - Companies (developer/publisher)
        - Languages
        - System requirements
        - Original and repack sizes
        - Repack features
        - Publishing dates
    
    Example:
        GET /api/game-metadata?page_url=https://fitgirl-repacks.site/forza-horizon-5/
    """
    if not page_url or not page_url.strip():
        raise HTTPException(status_code=400, detail="Page URL cannot be empty")
    
    # Basic URL validation
    if not page_url.startswith("http"):
        raise HTTPException(status_code=400, detail="Invalid URL format")
    
    try:
        # Call the metadata extraction function
        if image_size not in {"thumb", "medium", "full"}:
            raise HTTPException(status_code=400, detail="image_size must be 'thumb', 'medium', or 'full'")
        metadata = fetch_game_metadata(page_url.strip(), force_refresh=force_refresh, image_size=image_size)
        
        if metadata is None:
            return GameMetadataResponse(
                success=False,
                error="Failed to fetch game metadata. Please check the URL."
            )
        
        # Convert to response format
        game_data = GameMetadata(**metadata)
        
        return GameMetadataResponse(
            success=True,
            data=game_data
        )
        
    except Exception as e:
        return GameMetadataResponse(
            success=False,
    error=f"An unexpected error occurred: {str(e)}"
    )


@app.get("/api/home", response_model=HomeResponse)
async def get_home(max_items: int = 12, force_refresh: bool = False, image_size: str = "medium"):
    """Aggregate homepage data: featured, latest, upcoming, popular."""
    try:
        if image_size not in {"thumb", "medium", "full"}:
            raise HTTPException(status_code=400, detail="image_size must be 'thumb', 'medium', or 'full'")
        payload = fetch_home(max_items=max_items, force_refresh=force_refresh, image_size=image_size)
        if not payload:
            return HomeResponse(success=False, error="Failed to fetch homepage data")

        featured = payload.get('featured')
        latest = [HomeItem(**item) for item in payload.get('latest', [])]
        popular = [ArticleLink(**item) for item in payload.get('popular', [])]
        return HomeResponse(
            success=True,
            data=HomeData(
                featured=HomeItem(**featured) if featured else None,
                latest=latest,
                upcoming=payload.get('upcoming', []) or [],
                popular=popular,
            )
        )
    except Exception as e:
        return HomeResponse(success=False, error=f"An unexpected error occurred: {str(e)}")


@app.get("/api/home-latest", response_model=HomeListResponse)
async def get_home_latest(max_items: int = 12, force_refresh: bool = False, image_size: str = "medium"):
    """Return the latest repacks list from the homepage widget."""
    try:
        if image_size not in {"thumb", "medium", "full"}:
            raise HTTPException(status_code=400, detail="image_size must be 'thumb', 'medium', or 'full'")
        latest = fetch_home_latest(max_items=max_items, force_refresh=force_refresh, image_size=image_size)
        if latest is None:
            return HomeListResponse(success=False, error="Failed to fetch latest repacks", count=0)
        items = [HomeItem(**item) for item in latest]
        return HomeListResponse(success=True, data=items, count=len(items))
    except Exception as e:
        return HomeListResponse(success=False, error=f"An unexpected error occurred: {str(e)}", count=0)


@app.get("/api/upcoming", response_model=HomeListResponse)
async def get_upcoming():
    """Return the upcoming repacks list from the homepage."""
    try:
        upcoming = fetch_upcoming_list()
        if upcoming is None:
            return HomeListResponse(success=False, error="Failed to fetch upcoming repacks", count=0)
        # Reuse HomeItem schema minimally with title only
        items = [HomeItem(title=text, url="", image=None, version=None, published_date=None, repack_size=None) for text in upcoming]
        return HomeListResponse(success=True, data=items, count=len(items))
    except Exception as e:
        return HomeListResponse(success=False, error=f"An unexpected error occurred: {str(e)}", count=0)


if __name__ == "__main__":
    print("🚀 Starting Fitgirl Scraper API...")
    print("📍 Server running at: http://127.0.0.1:8000")
    print("📚 API documentation: http://127.0.0.1:8000/docs")
    print("\nPress CTRL+C to stop the server\n")
    
    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
        log_level="info"
    )
