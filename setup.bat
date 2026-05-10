@echo off
REM LeadScout - Windows Setup Script

echo.
echo 🚀 LeadScout - Setup Script
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Docker is not installed or not in PATH
    echo Download from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo ✓ Docker found

REM Prefer Compose V2 (`docker compose`), fall back to legacy V1 (`docker-compose`).
docker compose version >nul 2>&1
if %errorlevel% equ 0 (
    set "COMPOSE=docker compose"
) else (
    docker-compose --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ⚠️  Docker Compose is not installed.
        echo Docker Desktop ships it built-in. If Docker Desktop is running, try restarting it.
        pause
        exit /b 1
    )
    set "COMPOSE=docker-compose"
)

echo.
echo 📝 Checking .env file...

REM Only DATABASE_URL is read from env; API keys are configured in the Settings UI.
if not exist "backend\.env" (
    echo Creating .env file from template...
    copy backend\.env.example backend\.env
    echo ✓ .env created
) else (
    echo ✓ .env already exists
)

echo.
echo 🐳 Building and starting Docker containers...
%COMPOSE% up -d --build

if %errorlevel% neq 0 (
    echo ❌ Failed to start containers
    pause
    exit /b 1
)

echo.
echo ⏳ Waiting for backend to start...
timeout /t 5 /nobreak

echo.
echo ✅ Setup complete!
echo.
echo 🌐 Access the application:
echo    Frontend:  http://localhost:3000
echo    Backend:   http://localhost:8000
echo    API Docs:  http://localhost:8000/docs
echo.
echo 📝 Next steps:
echo    1. Open http://localhost:3000 in your browser
echo    2. Go to Settings and paste in your API keys:
echo       - Google Places API key (up to 3 for rotation)
echo       - Google CSE API key + CX (for Facebook page lookup)
echo       - Facebook Graph access token (optional, enriches leads)
echo    3. Go to Discover to pull businesses without websites
echo    4. Go to My Leads to work the list
echo.
echo 🛑 To stop:
echo    %COMPOSE% down
echo.
echo 📚 More info:
echo    See README.md and docs\features\leadscout\
echo.

pause
