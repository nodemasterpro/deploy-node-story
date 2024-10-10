#!/bin/bash

function backup_keys() {
    ansible-playbook backup_restore_keys.yml -e "action=backup"
}

function restore_keys() {
    ansible-playbook backup_restore_keys.yml -e "action=restore"
}

function check_sync_status() {
    story status 2>&1 | jq '.SyncInfo'
}

function view_validator_info() {
    story query staking validator $(story keys show validator -a --bech val) --node https://rpc.story-testnet-1.storyprotocol.xyz:443
}

function register_validator() {
    ansible-playbook register_story_validator_node.yml
}

function display_help() {
    echo "Usage: $0 {backup_keys|restore_keys|sync|info|register}"
    echo "  backup_keys   : Backup validator keys"
    echo "  restore_keys  : Restore validator keys"
    echo "  sync          : Check synchronization status"
    echo "  info          : View validator information"
    echo "  register      : Register the node as a validator"
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
    register)
        register_validator
        ;;
    help)
        display_help
        ;;
    *)
        echo "Error: Invalid command."
        display_help
        exit 1
esac