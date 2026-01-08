# Start the backend API server
Write-Host "🚀 Starting Fitgirl Scraper Backend..." -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.8+ from https://python.org" -ForegroundColor Yellow
    pause
    exit 1
}

# Check Python version
$pythonVersion = python --version 2>&1
Write-Host "✓ Found: $pythonVersion" -ForegroundColor Green

# Check if requirements are installed
Write-Host ""
Write-Host "📦 Checking dependencies..." -ForegroundColor Cyan

$packagesInstalled = $true
$requiredPackages = @("fastapi", "uvicorn", "requests", "beautifulsoup4")

foreach ($package in $requiredPackages) {
    $installed = python -c "import $package" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ $package not installed" -ForegroundColor Red
        $packagesInstalled = $false
    } else {
        Write-Host "  ✓ $package" -ForegroundColor Green
    }
}

if (-not $packagesInstalled) {
    Write-Host ""
    Write-Host "Installing missing dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        pause
        exit 1
    }
}

Write-Host ""
Write-Host "✓ All dependencies installed" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Backend API Server" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "  📍 URL:       http://127.0.0.1:8000" -ForegroundColor White
Write-Host "  📚 Docs:      http://127.0.0.1:8000/docs" -ForegroundColor White
Write-Host "  🛑 Stop:      Press CTRL+C" -ForegroundColor White
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Start the backend
python backend_api.py
