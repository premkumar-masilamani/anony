# Gracefully handle missing local environment configurations in CI/CD
-include .env
ifneq ($(wildcard .env),)
    export $(shell sed 's/=.*//' .env)
endif

.PHONY: all run_database connect_database run_backend run_frontend run_mobile test lint build

all: run_backend

run_database:
	@echo "Starting the database..."
	@$(MAKE) -C database all

connect_database:
	@echo "Connecting to the database CLI..."
	@$(MAKE) -C database connect_database

run_backend:
	@echo "Launching backend development server..."
	@$(MAKE) -C backend dev

run_frontend:
	@echo "Launching frontend development server..."
	@$(MAKE) -C frontend dev

run_mobile:
	@echo "Launching mobile development environment..."
	@$(MAKE) -C mobile dev

test:
	@echo "Running backend test suites..."
	@$(MAKE) -C backend test
	@echo "Running frontend test suites..."
	@$(MAKE) -C frontend test
	@echo "Running mobile test suites..."
	@$(MAKE) -C mobile test

lint:
	@echo "Linting backend source code..."
	@$(MAKE) -C backend lint
	@echo "Linting frontend source code..."
	@$(MAKE) -C frontend lint
	@echo "Linting mobile source code..."
	@$(MAKE) -C mobile lint

build:
	@echo "Building backend production artifact..."
	@$(MAKE) -C backend build
	@echo "Building frontend production bundle..."
	@$(MAKE) -C frontend build
	@echo "Building mobile Swift artifacts..."
	@$(MAKE) -C mobile build
