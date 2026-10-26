# Gracefully handle missing local environment configurations in CI/CD
-include .env
ifneq ($(wildcard .env),)
    export $(shell sed 's/=.*//' .env)
endif

.PHONY: all run_database connect_database run_backend test lint build

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

test:
	@echo "Running backend test suites..."
	@$(MAKE) -C backend test

lint:
	@echo "Linting backend source code..."
	@$(MAKE) -C backend lint

build:
	@echo "Building backend production artifact..."
	@$(MAKE) -C backend build
