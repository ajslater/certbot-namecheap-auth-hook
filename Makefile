.PHONY: install
## Install buildx platforms
## @category Install
install: 
	bin/install-binfmt-platforms.sh

.PHONY: install-lint
## Install linting tools
## @category Install
install-lint:
	bin/install-lint-deps.sh
	npm install

.PHONY: build
## Build docker image
## @category Build
build:
	bin/docker-bake.sh

.PHONY: deploy
## Build and deploy docker image
## @category Deploy
deploy:
	bin/docker-bake.sh push

.PHONY: update
## Update dependencies
## @category Update
update:
	./bin/update-deps.sh

## Show version. Use V variable to set version
## @category Update
V :=
.PHONY: version
## Show or set project version
## @category Update
version:
	bin/version.sh $(V)

.PHONY: kill-eslint_d
## Kill eslint daemon
## @category Lint
kill-eslint_d:
	bin/kill-eslint_d.sh

.PHONY: fix
## Fix front and back end lint errors
## @category Lint
fix: fix-backend

.PHONY: fix-backend
## Fix only backend lint errors
## @category Lint
fix-backend:
	./bin/fix-lint-backend.sh

.PHONY: lint
## Lint front and back end
## @category Lint
lint: lint-backend

.PHONY: lint-backend
## Lint the backend
## @category Lint
lint-backend:
	./bin/lint-backend.sh

.PHONY: test
## Run Test
## @category Test
test:
	./bin/test.sh

.PHONY: test-proxy
## Test the proxy
## @category Test
test-proxy:
	./bin/test-proxy.sh

.PHONY: news
## Show recent NEWS
## @category Deploy
news:
	head -40 NEWS.md

.PHONY: all
.PHONY: clean

include bin/makefile-help.mk
