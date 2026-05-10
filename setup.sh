#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 LeadScout - Setup Script${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker is not installed. Please install Docker first.${NC}"
    echo "Download from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Detect Compose: prefer V2 (`docker compose`), fall back to legacy V1 (`docker-compose`).
if docker compose version &> /dev/null; then
    COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE="docker-compose"
else
    echo -e "${YELLOW}⚠️  Docker Compose is not installed.${NC}"
    echo "Docker Desktop ships it built-in. If Docker Desktop is running, try restarting it."
    exit 1
fi

echo -e "${GREEN}✓ Docker found (using: ${COMPOSE})${NC}"
echo ""

# Create .env file from example if it doesn't exist (only DATABASE_URL is read from env;
# all API keys are configured via the Settings page in the UI).
if [ ! -f backend/.env ]; then
    echo -e "${BLUE}📝 Creating .env file...${NC}"
    cp backend/.env.example backend/.env
    echo -e "${GREEN}✓ .env created from template${NC}"
else
    echo -e "${GREEN}✓ .env already exists${NC}"
fi

echo ""
echo -e "${BLUE}🐳 Building and starting Docker containers...${NC}"
if ! $COMPOSE up -d --build; then
    echo ""
    echo -e "${YELLOW}❌ Build failed. See the error above.${NC}"
    echo "Run '${COMPOSE} logs' to inspect, or fix the reported error and retry."
    exit 1
fi

# Wait for backend to be ready
echo ""
echo -e "${BLUE}⏳ Waiting for backend to start...${NC}"
sleep 5

# Check backend health
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Backend still starting, this is normal${NC}"
fi

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${BLUE}🌐 Access the application:${NC}"
echo "  Frontend:  http://localhost:3000"
echo "  Backend:   http://localhost:8000"
echo "  API Docs:  http://localhost:8000/docs"
echo ""
echo -e "${BLUE}📝 Next steps:${NC}"
echo "  1. Open http://localhost:3000 in your browser"
echo "  2. Go to Settings and paste in your API keys:"
echo "     - Google Places API key (up to 3 for rotation)"
echo "     - Google CSE API key + CX (for Facebook page lookup)"
echo "     - Facebook Graph access token (optional, enriches leads)"
echo "  3. Go to Discover to pull businesses without websites"
echo "  4. Go to My Leads to work the list"
echo ""
echo -e "${BLUE}🛑 To stop:${NC}"
echo "  ${COMPOSE} down"
echo ""
echo -e "${BLUE}📚 More info:${NC}"
echo "  See README.md and docs/features/leadscout/"
