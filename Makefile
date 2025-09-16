.PHONY: help lint lint-python lint-yaml lint-json lint-md lint-docker lint-docker-ps format format-python install-linters

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install-linters: ## Install all linters
	pip install black flake8 isort mypy bandit yamllint pre-commit
	npm install -g markdownlint-cli jsonlint

lint: lint-python lint-yaml lint-json lint-md lint-docker ## Run all linters

lint-python: ## Lint Python files
	@echo "Running Python linters..."
	flake8 load_tests/
	mypy load_tests/ --ignore-missing-imports
	bandit -r load_tests/ -f json -o bandit-report.json || true

lint-yaml: ## Lint YAML files
	@echo "Linting YAML files..."
	yamllint .

lint-json: ## Lint JSON files
	@echo "Linting JSON files..."
	jsonlint Dashboard/dashboard.json

lint-md: ## Lint Markdown files
	@echo "Linting Markdown files..."
	markdownlint *.md

lint-docker: ## Lint Docker Compose files
	@echo "Linting Docker Compose files..."
	@if command -v docker-compose > /dev/null 2>&1; then \
		docker-compose config -q; \
	elif command -v docker > /dev/null 2>&1 && docker compose version > /dev/null 2>&1; then \
		docker compose config -q; \
	else \
		echo "⚠️ docker-compose not available, skipping syntax validation"; \
		python -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"; \
	fi
	yamllint docker-compose.yml
	@echo "Running custom Docker Compose validation..."
	@chmod +x scripts/validate-docker-compose.sh || true
	@bash scripts/validate-docker-compose.sh

lint-docker-ps: ## Lint Docker Compose files (PowerShell version)
	@echo "Linting Docker Compose files with PowerShell..."
	@powershell -ExecutionPolicy Bypass -File scripts/validate-docker-compose.ps1

format: format-python ## Format all code

format-python: ## Format Python files
	@echo "Formatting Python files..."
	black load_tests/
	isort load_tests/

pre-commit-install: ## Install pre-commit hooks
	pre-commit install

pre-commit-run: ## Run pre-commit on all files
	pre-commit run --all-files

clean: ## Clean up generated files
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	rm -f bandit-report.json