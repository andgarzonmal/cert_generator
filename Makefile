# Makefile for Certificate Generator

.PHONY: up down logs restart

# Start the application and show the link
up:
	@echo "Starting application..."
	@docker-compose up -d
	@echo ""
	@echo "✅ Application is running!"
	@echo "👉 Open: http://localhost:3000"

# Stop the application
down:
	@echo "Stopping application..."
	@docker-compose down

# View logs
logs:
	@docker-compose logs -f

# Restart the application
restart: down up
