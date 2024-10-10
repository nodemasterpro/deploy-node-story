#!/bin/bash

function install_node() {
    ansible-playbook install_story_nodes.yml -e "moniker=$1"
}

function update_node() {
    ansible-playbook update_story_consensus.yml
    ansible-playbook update_story_geth.yml
}

function view_status() {
    systemctl status story-consensus-node
    systemctl status story-geth-node
}

function stop_services() {
    systemctl stop story-geth-node
    systemctl stop story-consensus-node
    echo "Story services stopped."
}

function start_services() {
    systemctl start story-geth-node
    systemctl start story-consensus-node
    echo "Story services started."
}

function remove_node() {
    ansible-playbook remove_story_nodes.yml
}

function display_help() {
    echo "Usage: $0 {install|update|status|stop|start|remove}"
    echo "  install <moniker>    : Install a new Story node with the given moniker"
    echo "  update               : Update the Story node"
    echo "  status               : View the status of the Story node services"
    echo "  stop                 : Stop Story node services"
    echo "  start                : Start Story node services"
    echo "  remove               : Remove the Story node"
}

case "$1" in
    install)
        if [ -z "$2" ]; then
            echo "Error: Moniker is required for installation."
            display_help
            exit 1
        fi
        install_node "$2"
        ;;
    update)
        update_node
        ;;
    status)
        view_status
        ;;
    stop)
        stop_services
        ;;
    start)
        start_services
        ;;
    remove)
        read -p "Are you sure you want to remove the Story node? This action cannot be undone. (y/N) " confirm
        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            remove_node
        else
            echo "Node removal cancelled."
        fi
        ;;
    help)
        display_help
        ;;
    *)
        echo "Error: Invalid command."
        display_help
        exit 1
esac