#!/bin/bash

set -e

cd /home/renderer/
./config_minio.sh

./get_from_store.sh finland
./generate_maps.sh
./upload_to_store.sh garmin finland
