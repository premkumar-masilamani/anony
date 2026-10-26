# Gracefully handle missing local environment configurations in CI/CD
-include .env
ifneq ($(wildcard .env),)
    export $(shell sed 's/=.*//' .env)
endif

.PHONY: all run_database connect_database run_backend run_frontend run_ios run_android test lint build

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
	@echo "Launching frontend web development server..."
	@$(MAKE) -C frontend/web dev

run_ios:
	@echo "Launching iOS mobile development environment..."
	@$(MAKE) -C frontend/ios dev

run_android:
	@echo "Launching Android mobile development environment..."
	@$(MAKE) -C frontend/android dev

test:
	@echo "Running backend test suites..."
	@$(MAKE) -C backend test
	@echo "Running frontend (web, iOS, Android) test suites..."
	@$(MAKE) -C frontend test

lint:
	@echo "Linting backend source code..."
	@$(MAKE) -C backend lint
	@echo "Linting frontend (web, iOS, Android) source code..."
	@$(MAKE) -C frontend lint

build:
	@echo "Building backend production artifact..."
	@$(MAKE) -C backend build
	@echo "Building frontend (web, iOS, Android) production bundles..."
	@$(MAKE) -C frontend build
