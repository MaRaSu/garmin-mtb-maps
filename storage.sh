#!/bin/bash

# Storage abstraction layer
# Source this file to get storage_init, storage_download, storage_upload,
# storage_exists, and storage_delete functions.
#
# If STORAGEBOX_HOST is set, uses Storage Box (rsync over SSH).
# Otherwise, uses S3/MinIO (current behavior).

STORAGEBOX_PORT=${STORAGEBOX_PORT:-23}
STORAGEBOX_PATH=${STORAGEBOX_PATH:-/home}
STORAGEBOX_KEY=${STORAGEBOX_KEY:-/secrets/storagebox/id_rsa}

if [ -n "${STORAGEBOX_HOST}" ]; then
	STORAGE_MODE=storagebox
	RSYNC_SSH="ssh -p ${STORAGEBOX_PORT} -i ${STORAGEBOX_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=60 -o ServerAliveInterval=15 -o ServerAliveCountMax=3"
else
	STORAGE_MODE=s3
fi

storage_init() {
	if [ "${STORAGE_MODE}" = "s3" ]; then
		/home/renderer/config_minio.sh
	else
		echo "Storage mode: Storage Box (${STORAGEBOX_HOST})"
		if [ ! -f "${STORAGEBOX_KEY}" ]; then
			echo "Error: SSH key not found at ${STORAGEBOX_KEY}"
			exit 1
		fi
		if [ ! -r "${STORAGEBOX_KEY}" ]; then
			echo "Error: SSH key at ${STORAGEBOX_KEY} is not readable"
			exit 1
		fi
		echo "Testing Storage Box connectivity..."
		if ! rsync --list-only -e "${RSYNC_SSH}" ${STORAGEBOX_HOST}:${STORAGEBOX_PATH}/ >/dev/null 2>&1; then
			echo "Error: Cannot connect to Storage Box"
			exit 1
		fi
		echo "Storage Box connection OK"
	fi
}

storage_download() {
	local remote_filename=$1
	local local_path=$2
	if [ "${STORAGE_MODE}" = "s3" ]; then
		mc cp trailmap/trailmap-internal/${remote_filename} ${local_path}
	else
		rsync -e "${RSYNC_SSH}" --partial --inplace --timeout=300 --info=progress2 ${STORAGEBOX_HOST}:${STORAGEBOX_PATH}/${remote_filename} ${local_path}
	fi
}

storage_upload() {
	local local_path=$1
	local remote_filename=$2
	if [ "${STORAGE_MODE}" = "s3" ]; then
		mc cp ${local_path} trailmap/trailmap-internal/${remote_filename}
	else
		rsync -e "${RSYNC_SSH}" --partial --inplace --timeout=300 --info=progress2 ${local_path} ${STORAGEBOX_HOST}:${STORAGEBOX_PATH}/${remote_filename}
	fi
}

storage_exists() {
	local remote_filename=$1
	if [ "${STORAGE_MODE}" = "s3" ]; then
		mc stat trailmap/trailmap-internal/${remote_filename} >/dev/null 2>&1
	else
		rsync --list-only -e "${RSYNC_SSH}" ${STORAGEBOX_HOST}:${STORAGEBOX_PATH}/${remote_filename} >/dev/null 2>&1
	fi
}

storage_delete() {
	local remote_filename=$1
	if [ "${STORAGE_MODE}" = "s3" ]; then
		mc rm trailmap/trailmap-internal/${remote_filename}
	else
		ssh -p ${STORAGEBOX_PORT} -i ${STORAGEBOX_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes ${STORAGEBOX_HOST} "rm ${STORAGEBOX_PATH}/${remote_filename}" </dev/null
	fi
}
