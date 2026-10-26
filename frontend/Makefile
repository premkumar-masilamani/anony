.PHONY: all dev dev_web dev_ios test lint build clean install check

all: dev_web

install:
	@echo "Installing web frontend dependencies..."
	@$(MAKE) -C web install

dev: dev_web

dev_web:
	@$(MAKE) -C web dev

dev_ios:
	@$(MAKE) -C ios dev

test:
	@echo "Running web frontend test suites..."
	@$(MAKE) -C web test
	@echo "Running iOS mobile test suites..."
	@$(MAKE) -C ios test

lint:
	@echo "Linting web frontend source code..."
	@$(MAKE) -C web lint
	@echo "Linting iOS mobile source code..."
	@$(MAKE) -C ios lint

build:
	@echo "Building web frontend production bundle..."
	@$(MAKE) -C web build
	@echo "Building iOS mobile Swift artifacts..."
	@$(MAKE) -C ios build

clean:
	@$(MAKE) -C web clean
	@$(MAKE) -C ios clean

check:
	@$(MAKE) -C web check
	@$(MAKE) -C ios check
