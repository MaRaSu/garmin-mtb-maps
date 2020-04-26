.PHONY: build push test
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
cur_dir := $(dir $(mkfile_path))

build: 
	docker build -t registry.finomena.fi/c/garmin-mtb-maps:0.2.1 --build-arg NOCACHE=$$(date +%s) .

push: build
	docker push registry.finomena.fi/c/garmin-mtb-maps:0.2.1

test: build
	-docker container rm garmin-mtb-maps
	docker run --name garmin-mtb-maps -v $(cur_dir)/osm-data:/osm-data -v $(cur_dir)/maps:/ready_maps -it registry.finomena.fi/c/garmin-mtb-maps:0.1.1

test_sh: build
	-docker container rm garmin-mtb-maps
	docker run --name garmin-mtb-maps -v $(cur_dir)/osm-data:/osm-data -v $(cur_dir)/maps:/ready_maps -it registry.finomena.fi/c/garmin-mtb-maps:0.1.1 bash