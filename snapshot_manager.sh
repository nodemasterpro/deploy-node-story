#!/bin/bash

function manage_snapshots() {
    case "$1" in
        download)
            ansible-playbook manage_snapshots.yml -e "action=download snapshot_type=$2"
            ;;
        import)
            ansible-playbook manage_snapshots.yml -e "action=import snapshot_type=$2"
            ;;
        *)
            echo "Usage: manage_snapshots {download|import} {pruned|archive}"
            exit 1
    esac
}

function display_help() {
    echo "Usage: $0 {download|import} {pruned|archive}"
    echo "  download <type>  : Download a snapshot of the specified type"
    echo "  import <type>    : Import a snapshot of the specified type"
    echo "  <type> can be 'pruned' or 'archive'"
}

if [ $# -eq 0 ] || [ $# -ne 2 ]; then
    display_help
    exit 1
fi

manage_snapshots "$1" "$2"
