1. Edit Makefile to change Docker image tags to names that fit your own naming scheme & image registry
2. `make build` to build the image or `make test`to build and run. For testing you need to create a `osm-data` and `maps` folders (which are mapped to container)
3. Run `generate_maps.sh` script in container to generate Garmin maps
 