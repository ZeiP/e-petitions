BUILD_COMMIT := $(shell git rev-parse HEAD)
BUILD_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
BUILD_TIME := $(shell date +%Y%m%d-%H%M%S)
IMAGE_TAG_BASE := docker-registry.trineria.fi/partio/partiolaisaloite
IMAGE_TAG_PRECISE := $(IMAGE_TAG_BASE):$(BUILD_BRANCH)-$(BUILD_TIME)
IMAGE_TAG_LATEST := $(IMAGE_TAG_BASE):$(BUILD_BRANCH)-latest

all: docker-image

docker-image:
	@echo ----- Building docker image
	docker build -f Dockerfile.prod -t $(IMAGE_TAG_PRECISE) \
	    --build-arg BUILD_COMMIT=$(BUILD_COMMIT) \
	    --build-arg BUILD_BRANCH=$(BUILD_BRANCH) \
	    --build-arg BUILD_TIME=$(BUILD_TIME) \
	    .
	docker tag $(IMAGE_TAG_PRECISE) $(IMAGE_TAG_LATEST)

docker-image-push: docker-image
	@echo ----- Pushing docker image to registry
	docker push $(IMAGE_TAG_PRECISE)
	docker push $(IMAGE_TAG_LATEST)
