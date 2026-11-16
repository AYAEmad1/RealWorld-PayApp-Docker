.PHONY: help build run stop logs shell status clean

help: ## Show available commands
    @grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-8s %s\n", $$1, $$2}'

build: ## Build the Docker images
    docker compose build

run: ## Build (if needed) and start everything in the background
    docker compose up -d --build
    @echo "Open http://localhost:3000  (login: Heath93 / s3cret)"

stop: ## Stop containers (data is kept)
    docker compose down

logs: ## Follow the logs of both containers
    docker compose logs -f

shell: ## Open a shell inside the API container
    docker compose exec api sh

status: ## Show container status and health
    docker compose ps

clean: ## Stop containers AND delete the data volume (resets demo data)
    docker compose down -v --remove-orphans