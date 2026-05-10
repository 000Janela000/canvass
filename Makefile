.PHONY: help setup up down logs logs-backend logs-frontend shell-backend shell-frontend restart clean reset-db build

# Prefer Compose V2 (`docker compose`), fall back to legacy V1 (`docker-compose`).
COMPOSE := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

help:
	@echo "LeadScout - Makefile Commands"
	@echo ""
	@echo "Setup & Start:"
	@echo "  make setup         - Initial setup (download, build, start)"
	@echo "  make up            - Start containers"
	@echo "  make down          - Stop containers"
	@echo "  make restart       - Restart containers"
	@echo ""
	@echo "Development:"
	@echo "  make build         - Rebuild images"
	@echo "  make logs          - View all logs"
	@echo "  make logs-backend  - View backend logs"
	@echo "  make logs-frontend - View frontend logs"
	@echo "  make shell-backend - Shell into backend container"
	@echo "  make shell-frontend - Shell into frontend container"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean         - Stop and remove containers"
	@echo "  make reset-db      - Reset database (DELETE ALL DATA)"
	@echo ""

setup:
	@bash setup.sh

up:
	@$(COMPOSE) up -d
	@echo "✓ Services started"
	@echo "  Frontend: http://localhost:3000"
	@echo "  Backend:  http://localhost:8000"

down:
	@$(COMPOSE) down
	@echo "✓ Services stopped"

restart:
	@$(COMPOSE) restart
	@echo "✓ Services restarted"

build:
	@$(COMPOSE) build
	@echo "✓ Images rebuilt"

logs:
	@$(COMPOSE) logs -f

logs-backend:
	@$(COMPOSE) logs -f backend

logs-frontend:
	@$(COMPOSE) logs -f frontend

shell-backend:
	@$(COMPOSE) exec backend bash

shell-frontend:
	@$(COMPOSE) exec frontend sh

clean:
	@$(COMPOSE) down -v
	@echo "✓ Containers and volumes removed"

reset-db:
	@echo "🚨 WARNING: This will DELETE all leads and tracking data"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	@rm -f backend/data/leads.db
	@$(COMPOSE) restart backend
	@echo "✓ Database reset"
