#!/bin/bash

WEEKDAY=$(date +%u)
WEEKDAY_MINUS_2=$(((WEEKDAY - 2 + 6) % 7 + 1))
BASENAME="${1}-${2}"

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

# Function to handle backup and upload
handle_upload() {
    local source="/data/${BASENAME}_${WEEKDAY}.tar.gz"
    local destination="trailmap/trailmap-internal/"
    local old_dataset="trailmap/trailmap-internal/${BASENAME}_${WEEKDAY_MINUS_2}.tar.gz"

    # Copy new file
    if ! retry_operation "mc cp $source $destination"; then
        echo "Failed to upload new file for ${BASENAME}"
        return 1
    fi

    mc rm "$old_dataset" || true
}

handle_zip() {
    cd /data || exit 1
    local source="*.img"
    local destination="${BASENAME}_${WEEKDAY}.tar.gz"

    # Zip the file
    if ! retry_operation "tar -cf - $source | pigz > $destination"; then
        echo "Failed to tar files for ${BASENAME}"
        return 1
    fi
}

# Main script

handle_zip
handle_upload
