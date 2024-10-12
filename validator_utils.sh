#!/bin/bash

function backup_keys() {
    ansible-playbook backup_restore_keys.yml -e "action=backup"
    echo "Backup created at /root/backup-keys-story/story_keys_backup.tar.gz"
    echo "This backup contains:"
    echo "  - EVM private key (from /root/.story/story/config/private_key.txt)"
    echo "  - Tendermint validator key (from /root/.story/story/config/priv_validator_key.json)"
}

function restore_keys() {
    ansible-playbook backup_restore_keys.yml -e "action=restore"
}

function check_sync_status() {
    story status | jq '.sync_info'
}

function view_validator_info() {
    curl -s http://localhost:26657/status | jq
}

function display_help() {
    echo "Usage: $0 {backup_keys|restore_keys|sync|info}"
    echo "  backup_keys   : Backup validator keys"
    echo "  restore_keys  : Restore validator keys"
    echo "  sync          : Check synchronization status"
    echo "  info          : View node status information"
}

case "$1" in
    backup_keys)
        backup_keys
        ;;
    restore_keys)
        restore_keys
        ;;
    sync)
        check_sync_status
        ;;
    info)
        view_validator_info
        ;;
    help)
        display_help
        ;;
    *)
        echo "Error: Invalid command."
        display_help
        exit 1
esac
