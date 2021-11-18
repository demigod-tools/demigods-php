PROJECT_NAME ?= php
REPO_NAME    ?= ${DOCKER_IMAGE_ORG}/${PROJECT_NAME}
VCS_REF      ?= $(shell git rev-parse --short HEAD)
DATE_TAG     ?= $(shell TZ=UTC date +%Y-%m-%d_%H.%M)
VERSION      ?= $(shell git describe --tags --always --dirty --match="v*" 2> /dev/null || cat $(CURDIR)/.version 2> /dev/null || echo v0)
PHP_VERSION  ?= 8.0

IMAGE_TAG=${DOCKER_IMAGE_HOST}/${DOCKER_IMAGE_ORG}/${PROJECT_NAME}
BUILD_ID=${USER}-${VERSION}-$(VCS_REF)

docker:
	docker build \
		--build-arg BUILD_DATE="${DATE_TAG}" \
		--build-arg BUILD_ID="${BUILD_ID}" \
		--build-arg VCS_REF="${VCS_REF}" \
		--build-arg VERSION="${VERSION}" \
		--build-arg REPO_NAME="${REPO_NAME}" \
		--build-arg PHP_VERSION="${PHP_VERSION}" \
		--tag=${IMAGE_TAG}:php-${PHP_VERSION} \
		 .

.DEFAULT_GOAL := docker
