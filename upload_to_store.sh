#!/bin/bash

source /home/renderer/storage.sh

WEEKDAY=$(date +%u)
WEEKDAY_MINUS_2=$(((WEEKDAY - 2 + 6) % 7 + 1))
BASENAME="${1}-${2}"
MODE="${3:-multi}"  # Default to "multi" if not specified
SOURCE_FILE="${4:-}"  # Optional: specific source filename for single mode

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
    local extension=$1
    local source="/data/${BASENAME}_${WEEKDAY}.${extension}"
    local remote_filename="${BASENAME}_${WEEKDAY}.${extension}"
    local old_remote="${BASENAME}_${WEEKDAY_MINUS_2}.${extension}"

    # Copy new file
    if ! retry_operation "storage_upload $source $remote_filename"; then
        echo "Failed to upload new file for ${BASENAME}"
        return 1
    fi

    storage_delete "$old_remote" || true
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

# Function to prepare single file for upload
handle_single() {
    cd /data || exit 1

    local source_file
    if [ -n "$SOURCE_FILE" ]; then
        # Use specified source file
        if [ ! -f "$SOURCE_FILE" ]; then
            echo "Error: Specified source file '$SOURCE_FILE' not found"
            return 1
        fi
        source_file="$SOURCE_FILE"
    else
        # Find the single .img file
        local img_files=(*.img)

        if [ ${#img_files[@]} -ne 1 ]; then
            echo "Error: Expected exactly one .img file, found ${#img_files[@]}"
            return 1
        fi
        source_file="${img_files[0]}"
    fi

    local destination="${BASENAME}_${WEEKDAY}.img"

    # Rename/copy to expected filename
    if ! cp "$source_file" "$destination"; then
        echo "Failed to prepare file for ${BASENAME}"
        return 1
    fi
}

# Main script

if [ "$MODE" = "single" ]; then
    echo "Upload mode: single file"
    handle_single
    handle_upload "img"
else
    echo "Upload mode: multi-file archive"
    handle_zip
    handle_upload "tar.gz"
fi
