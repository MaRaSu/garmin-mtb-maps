.PHONY: build push test
version_tag=0.3.0
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
cur_dir := $(dir $(mkfile_path))

build: 
	docker build -t registry.finomena.fi/c/garmin-mtb-maps:$(version_tag) --build-arg NOCACHE=$$(date +%s) .

push: build
	docker push registry.finomena.fi/c/garmin-mtb-maps:$(version_tag)

test: build
	-docker container stop garmin-mtb-maps
	-docker container rm garmin-mtb-maps
	docker run --name garmin-mtb-maps -v $(cur_dir)/osm-data:/osm-data -v $(cur_dir)/maps:/ready_maps -it registry.finomena.fi/c/garmin-mtb-maps:$(version_tag)

test_sh: build
	-docker container stop garmin-mtb-maps
	-docker container rm garmin-mtb-maps
	docker run --name garmin-mtb-maps -v $(cur_dir)/osm-data:/osm-data -v $(cur_dir)/maps:/ready_maps -it registry.finomena.fi/c/garmin-mtb-maps:$(version_tag) bash