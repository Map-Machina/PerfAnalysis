.PHONY: help build up down restart logs test clean

# Default target
help:
	@echo "PerfAnalysis Development Commands"
	@echo ""
	@echo "Setup & Build:"
	@echo "  make build          - Build all Docker images"
	@echo "  make up             - Start all services"
	@echo "  make down           - Stop all services"
	@echo "  make restart        - Restart all services"
	@echo ""
	@echo "Development:"
	@echo "  make logs           - View logs from all services"
	@echo "  make logs-xat       - View XATbackend logs"
	@echo "  make logs-pcd       - View pcd logs"
	@echo "  make shell-xat      - Shell into XATbackend container"
	@echo "  make shell-go       - Shell into perfcollector2 container"
	@echo "  make shell-r        - Shell into R container"
	@echo ""
	@echo "Testing:"
	@echo "  make test           - Run all tests"
	@echo "  make test-go        - Run Go tests"
	@echo "  make test-django    - Run Django tests"
	@echo "  make test-r         - Run R tests"
	@echo ""
	@echo "Database:"
	@echo "  make db-migrate     - Run Django migrations"
	@echo "  make db-shell       - PostgreSQL shell"
	@echo "  make db-reset       - Reset database (WARNING: destroys data)"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean          - Remove all containers and volumes"
	@echo "  make ps             - Show running containers"
	@echo "  make health         - Check health of all services"

# Build all Docker images
build:
	docker-compose build

# Start all services
up:
	docker-compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@make health

# Stop all services
down:
	docker-compose down

# Restart all services
restart: down up

# View logs from all services
logs:
	docker-compose logs -f

# View logs from specific services
logs-xat:
	docker-compose logs -f xatbackend

logs-pcd:
	docker-compose logs -f pcd

logs-r:
	docker-compose logs -f r-dev

# Shell into containers
shell-xat:
	docker-compose exec xatbackend bash

shell-go:
	docker-compose exec pcd sh

shell-r:
	docker-compose exec r-dev bash

# Run all tests
test: test-go test-django test-r

# Run Go tests
test-go:
	@echo "Running Go tests..."
	cd perfcollector2 && go test ./... -v

# Run Django tests
test-django:
	@echo "Running Django tests..."
	docker-compose exec xatbackend python manage.py test

# Run R tests
test-r:
	@echo "Running R tests..."
	docker-compose exec r-dev Rscript -e "lintr::lint_dir()"

# Database operations
db-migrate:
	docker-compose exec xatbackend python manage.py migrate

db-shell:
	docker-compose exec postgres psql -U perfadmin -d perfanalysis

db-reset:
	@echo "WARNING: This will destroy all data. Press Ctrl+C to cancel, Enter to continue..."
	@read confirm
	docker-compose down -v
	docker-compose up -d postgres
	@sleep 5
	@make db-migrate

# Show running containers
ps:
	docker-compose ps

# Health check all services
health:
	@echo "Checking service health..."
	@echo -n "PostgreSQL: "
	@docker-compose exec -T postgres pg_isready -U perfadmin && echo "✅" || echo "❌"
	@echo -n "XATbackend: "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health | grep -q 200 && echo "✅" || echo "❌"
	@echo -n "pcd: "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/v1/ping | grep -q 200 && echo "✅" || echo "❌"

# Clean up everything
clean:
	docker-compose down -v
	rm -rf perfcollector2/bin/
	rm -rf XATbackend/staticfiles/
	@echo "Cleanup complete"

# Initialize development environment
init: build up db-migrate
	@echo ""
	@echo "✅ Development environment initialized!"
	@echo ""
	@echo "Services running at:"
	@echo "  - XATbackend: http://localhost:8000"
	@echo "  - pcd API:    http://localhost:8080"
	@echo "  - PostgreSQL: localhost:5432"
	@echo ""
	@echo "Next steps:"
	@echo "  make logs       - View logs"
	@echo "  make test       - Run tests"
	@echo "  make shell-xat  - Django shell"
