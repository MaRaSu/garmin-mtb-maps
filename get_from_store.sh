#!/bin/bash

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
    local source="trailmap/trailmap-internal/${dataset}_${WEEKDAY}.osm.pbf"
    local destination="/data/data.osm.pbf"

    # Check if source file exists
    if mc stat "$source" >/dev/null 2>&1; then
        if ! retry_operation "mc cp $source $destination"; then
            echo "Failed to download file for $dataset"
            return 1
        fi
    else
        echo "File not found: $source"
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
