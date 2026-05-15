# Crosscue — local CI helpers
# Mirrors .github/workflows/ci.yml exactly.
# Run from the repo root.

FLUTTER := flutter
DART    := dart
DIR     := crosscue

.PHONY: ci check static format analyze test generated build install-hooks

## Match the hosted PR CI checks.
ci: check

## Run all hosted PR checks.
check: static test

## Run static checks that share one setup pass in hosted CI.
static: format analyze generated

## Stage 1 — formatting
format:
	@echo "▶ format"
	cd $(DIR) && $(DART) format --output=none --set-exit-if-changed .

## Stage 2 — checks (run individually or via `check`)
analyze:
	@echo "▶ analyze"
	cd $(DIR) && $(FLUTTER) analyze

test:
	@echo "▶ test"
	cd $(DIR) && $(FLUTTER) test

generated:
	@echo "▶ generated files"
	cd $(DIR) && $(DART) run build_runner build
	cd $(DIR) && git diff --exit-code -- \
		'*.g.dart' '*.freezed.dart'

## Install git hooks (run once after cloning)
install-hooks:
	@bash scripts/install-hooks.sh

## Optional local build verification (not part of hosted PR CI)
build:
	@echo "▶ build debug APK"
	cd $(DIR) && $(FLUTTER) build apk --debug --no-pub
