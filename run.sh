#!/bin/bash

set -e

cd /home/renderer/
source /home/renderer/storage.sh
storage_init

./get_from_store.sh finland

# Generate and upload TK maps
./generate_maps.sh
./upload_to_store.sh garmin finland

# Clean up TK map outputs before generating trailmap
rm -f /data/*.img

# Generate and upload new trailmap (multi-layer) maps
./generate_trailmap.sh
./upload_to_store.sh garmin_new finland single
