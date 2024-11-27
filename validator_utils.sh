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

function check_version() {
    case "$1" in
        story)
            story version
            ;;
        geth)
            geth version
            ;;
        *)
            echo "Error: Please specify 'story' or 'geth' as argument"
            echo "Usage: $0 version {story|geth}"
            exit 1
            ;;
    esac
}

function update_peers() {
    ansible-playbook update_peers.yml
}

function display_help() {
    echo "Usage: $0 {backup_keys|restore_keys|sync|info|version|update_peers}"
    echo "  backup_keys          : Backup validator keys"
    echo "  restore_keys         : Restore validator keys"
    echo "  sync                 : Check synchronization status"
    echo "  info                 : View node status information"
    echo "  version {story|geth} : Check Story or Geth version"
    echo "  update_peers         : Update peers list and restart services"
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
    version)
        check_version "$2"
        ;;
    update_peers)
        update_peers
        ;;
    help)
        display_help
        ;;
    *)
        display_help
        exit 1
esac
