VERSION = 0.9.1
REGISTRY = registry-hetzner.finomena.fi
IMAGE_NAME = garmin-mtb-maps
DATE = $(shell date +%Y%m%d)

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
cur_dir := $(dir $(mkfile_path))

.PHONY: build push test test_sh

build:
	docker buildx build --platform linux/amd64 -t $(REGISTRY)/$(IMAGE_NAME):$(VERSION) --build-arg NOCACHE=$$(date +%s) .

push: build
	docker push $(REGISTRY)/$(IMAGE_NAME):$(VERSION)

test: build
	-docker container stop garmin-mtb-maps
	-docker container rm garmin-mtb-maps
	docker run --name garmin-mtb-maps -v $(cur_dir)/osm-data:/data -it $(REGISTRY)/$(IMAGE_NAME):$(VERSION)

test_sh: build
	-docker container stop garmin-mtb-maps
	-docker container rm garmin-mtb-maps
	docker run --name garmin-mtb-maps -v $(cur_dir)/osm-data:/data -it --entrypoint bash $(REGISTRY)/$(IMAGE_NAME):$(VERSION)
