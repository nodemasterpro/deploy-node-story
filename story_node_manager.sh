#!/bin/bash

function install_node() {
    ansible-playbook install_story_nodes.yml -e "moniker=$1"
}

function update_node() {
    ansible-playbook update_story_nodes.yml
}

function view_status() {
    systemctl status story-consensus-node
    systemctl status story-geth-node
}

function stop_services() {
    # Stop consensus service first
    systemctl stop story-consensus-node
    
    # Check and kill consensus process
    local story_pid=$(pgrep -f "/usr/local/bin/story run")
    if [ ! -z "$story_pid" ]; then
        echo "Force stopping story process (PID: $story_pid)..."
        kill -15 $story_pid
        sleep 2
        if ps -p $story_pid > /dev/null; then
            echo "Process still running, using SIGKILL..."
            kill -9 $story_pid
        fi
    fi
    
    # Remove any stale lock files
    rm -f /root/.story/story/data/application.db/LOCK
    
    # Stop geth service
    systemctl stop story-geth-node
    
    # Check and kill geth process if still running
    local geth_pid=$(pgrep -f "/usr/local/bin/geth.*--odyssey")
    if [ ! -z "$geth_pid" ]; then
        echo "Force stopping geth process (PID: $geth_pid)..."
        kill -15 $geth_pid
        sleep 2
        if ps -p $geth_pid > /dev/null; then
            echo "Process still running, using SIGKILL..."
            kill -9 $geth_pid
        fi
    fi
    
    echo "Story services stopped."
}

function start_services() {
    # Start geth service first
    systemctl start story-geth-node
    echo "Story geth service started."
    
    # Wait for geth to initialize
    sleep 5
    
    # Start consensus service
    systemctl start story-consensus-node
    echo "Story consensus service started."
    
    # Final confirmation
    echo "All Story services started."
}

function remove_node() {
    ansible-playbook remove_story_nodes.yml
}

function view_logs() {
    case "$1" in
        story)
            journalctl -u story-consensus-node -f -o cat
            ;;
        geth)
            journalctl -u story-geth-node -f -o cat
            ;;
        *)
            echo "Error: Invalid log type. Use 'story' or 'geth'"
            exit 1
            ;;
    esac
}

function display_help() {
    echo "Usage: $0 {install|update|status|stop|start|remove|register|logs}"
    echo "  install <moniker>    : Install a new Story node with the given moniker"
    echo "  update              : Update the Story node"
    echo "  status              : View the status of the Story node services"
    echo "  stop                : Stop Story node services"
    echo "  start               : Start Story node services"
    echo "  remove              : Remove the Story node"
    echo "  register            : Register the node as a validator"
    echo "  logs <story|geth>   : View the logs of the specified service"
}

function register_validator() {
    ansible-playbook register_story_validator_node.yml
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
    register)
        register_validator
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
    logs)
        if [ -z "$2" ]; then
            echo "Error: Please specify which logs to view (story or geth)"
            display_help
            exit 1
        fi
        view_logs "$2"
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
        display_help
        exit 1
esac
