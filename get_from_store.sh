#!/bin/bash

source /home/renderer/storage.sh

WEEKDAY=$(date +%u)

# Function to retry operations with backoff
retry_operation() {
    local max_attempts=5
    local command=$1
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts: $command"
        if eval "$command"; then
            return 0
        fi
        attempt=$((attempt + 1))
        echo "Operation failed, waiting 60 seconds before retry..."
        sleep 60
    done
    echo "Operation failed after $max_attempts attempts"
    return 1
}

# Function to handle file download
handle_download() {
    local dataset=$1
    local remote_filename="${dataset}_${WEEKDAY}.osm.pbf"
    local destination="/data/data.osm.pbf"

    # Check if source file exists
    if storage_exists "$remote_filename"; then
        if ! retry_operation "storage_download $remote_filename $destination"; then
            echo "Failed to download file for $dataset"
            return 1
        fi
    else
        echo "File not found: $remote_filename"
        return 1
    fi
}

# Main script
DATA_SET=$1

case "$DATA_SET" in
    "selected-europe"|"europe"|"finland"|"test")
        if ! handle_download "$DATA_SET"; then
            exit 1  # Exit with error only if handle_download fails after retries
        fi
        ;;
    *)
        echo "Invalid parameter: $DATA_SET"
        exit 1
        ;;
esac
