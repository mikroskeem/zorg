#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# This script syncs host:a/b/* to c/d/*, and avoids creating any additional snapshots on source.
# Permissions to grant using ZFS (more or less):
# - source: sudo zfs allow -u mark send,snapshot rpool/data/gameserver
# - target: sudo zfs allow -u mark snapshot,receive,create,mount,rollback,destroy htank/backups/gameserver
# In ideal you should set up a dedicated user for syncoid (& on NixOS, ensure that user environment has all needed packages on PATH, 
# easily doable using configuration.nix/flake)

# You need to ensure that ${ZORG_SANOID_DATASET_TARGET} exists

syncoid --no-privilege-elevation --skip-parent --recursive --no-sync-snap "${ZORG_SANOID_DATASET_SOURCE}" "${ZORG_SANOID_DATASET_TARGET}"
