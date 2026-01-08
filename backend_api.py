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
from fetch_fitgirl import search_fitgirl, fetch_download_links, decrypt_privatebin_paste

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


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "message": "Fitgirl Scraper API is running",
        "version": "1.0.0"
    }


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
