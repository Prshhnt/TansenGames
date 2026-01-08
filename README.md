# Fitgirl Repack Scraper

A desktop application for searching and browsing Fitgirl Repacks using a Flutter frontend and Python backend.

## Architecture

This application follows a clean separation of concerns:

- **Python Backend** (FastAPI): Handles all web scraping and parsing logic
- **Flutter Frontend**: Provides a clean, Material 3 UI for user interaction
- **HTTP Communication**: Backend and frontend communicate via REST API on localhost

## Prerequisites

### Python Backend
- Python 3.8 or higher
- pip package manager

### Flutter Frontend
- Flutter SDK 3.10.4 or higher
- Dart SDK (included with Flutter)

## Setup Instructions

### 1. Install Python Dependencies

```bash
# Navigate to project root
cd "d:\Programs\Fitgirl Repack"

# Install Python packages
pip install -r requirements.txt
```

### 2. Install Flutter Dependencies

```bash
# Navigate to Flutter project
cd fitgirl

# Get Flutter packages
flutter pub get
```

## Running the Application

### Step 1: Start the Python Backend

```bash
# From project root
python backend_api.py
```

The backend will start on `http://127.0.0.1:8000`

You can verify it's running by visiting:
- API Health: http://127.0.0.1:8000
- API Documentation: http://127.0.0.1:8000/docs

### Step 2: Run the Flutter App

```bash
# From the fitgirl directory
flutter run -d windows
```

Or use VS Code's Run button to launch the Flutter application.

## API Endpoints

### GET /api/search
Search for games on Fitgirl Repacks

**Query Parameters:**
- `query` (string): Search term (e.g., "resident evil")

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "title": "Game Title",
      "url": "https://fitgirl-repacks.site/..."
    }
  ],
  "count": 10
}
```

### GET /api/download-links
Fetch download links from an article page

**Query Parameters:**
- `page_url` (string): Full URL of the article

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "text": "Link description",
      "url": "https://..."
    }
  ],
  "count": 5
}
```

## Project Structure

```
Fitgirl Repack/
├── backend_api.py          # FastAPI wrapper for scraping logic
├── fetch_fitgirl.py        # Original scraping functions
├── requirements.txt        # Python dependencies
└── fitgirl/                # Flutter application
    ├── lib/
    │   ├── main.dart       # App entry point
    │   ├── models/         # Data models
    │   │   ├── article_link.dart
    │   │   └── download_link.dart
    │   ├── services/       # API communication
    │   │   └── api_service.dart
    │   ├── screens/        # UI screens
    │   │   └── home_screen.dart
    │   └── widgets/        # Reusable UI components
    │       ├── search_bar_widget.dart
    │       ├── article_list_widget.dart
    │       ├── download_links_widget.dart
    │       └── error_widget.dart
    └── pubspec.yaml        # Flutter dependencies
```

## Features

### Backend (Python)
- ✅ Search Fitgirl Repacks by game name
- ✅ Parse search results and extract article links
- ✅ Fetch download links from article pages
- ✅ RESTful API with FastAPI
- ✅ CORS enabled for local development
- ✅ Structured JSON responses
- ✅ Error handling

### Frontend (Flutter)
- ✅ Material 3 design
- ✅ Desktop-optimized UI
- ✅ Real-time backend status indicator
- ✅ Search functionality
- ✅ Scrollable search results
- ✅ Download link viewer
- ✅ Copy and open links
- ✅ Loading states
- ✅ Error handling with retry
- ✅ Empty state handling
- ✅ Hover effects and animations
- ✅ Dark mode support

## Usage Flow

1. **Start Backend**: Launch the Python API server
2. **Start Frontend**: Run the Flutter application
3. **Search**: Enter a game name and click "Search"
4. **Browse Results**: View the list of matching articles
5. **Select Article**: Click on an article to view download links
6. **Download**: Copy or open download links

## Development Notes

### Why This Architecture?

- **Separation of Concerns**: Scraping logic stays in Python where it's easier to maintain
- **Cross-Platform Ready**: Flutter frontend can easily support Android in the future
- **Scalable**: Backend can be moved to cloud without changing frontend
- **Maintainable**: Clear boundaries between UI and business logic

### Key Design Decisions

1. **NO scraping in Flutter**: All web scraping happens in Python
2. **HTTP API**: Enables future migration to remote backend
3. **Material 3**: Modern, accessible UI design
4. **State Management**: Simple setState for clarity and maintainability
5. **Error Handling**: Graceful degradation with user-friendly messages

## Troubleshooting

### Backend won't start
- Ensure all Python dependencies are installed: `pip install -r requirements.txt`
- Check if port 8000 is available
- Verify Python version: `python --version` (should be 3.8+)

### Frontend shows "Backend Offline"
- Make sure the Python backend is running on port 8000
- Check the terminal for backend error messages
- Click the refresh icon to retry connection

### No search results
- Verify internet connection
- Check if the Fitgirl website is accessible
- Look at backend terminal for scraping errors

## Future Enhancements

- [ ] Android support
- [ ] Caching for faster repeated searches
- [ ] Favorite/bookmark functionality
- [ ] Download progress tracking
- [ ] Settings for backend URL configuration
- [ ] Multiple backend instances support

## License

This is a personal project for educational purposes. Respect the website's terms of service and use responsibly.
