#!/bin/bash

# Unified script for Story Protocol node management - Aeneid Testnet
# Author: Nodes For All
# This script combines the functionality of:
# - story_node_manager.sh
# - snapshot_manager.sh
# - validator_utils.sh

# Color definitions for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service paths
GETH_SERVICE="story-geth"
STORY_SERVICE="story"

# Important directories and paths
BACKUP_DIR="/root/backup-keys-story"
SNAPSHOT_DIR="/root/snapshots"
VALIDATOR_KEY_PATH="$HOME/.story/story/config/priv_validator_key.json"
EVM_KEY_PATH="$HOME/.story/story/config/private_key.txt"
PRIV_VALIDATOR_STATE="$HOME/.story/story/data/priv_validator_state.json"
STORY_DATA_DIR="$HOME/.story/story/data"
GETH_DATA_DIR="$HOME/.story/geth"

# Base URL for snapshots
SNAPSHOT_BASE_URL="https://server-3.itrocket.net/testnet/story/"

# Variables for installation
STORY_GETH_VERSION="v1.1.0"
STORY_VERSION="v1.2.0"
GO_VERSION="1.22.5"

# Create necessary directories
mkdir -p $BACKUP_DIR
mkdir -p $SNAPSHOT_DIR

# Main help function
show_help() {
  echo -e "${BLUE}Unified script for Story Protocol - Aeneid Testnet${NC}"
  echo ""
  echo -e "Usage: $0 [command] [options]"
  echo ""
  echo -e "${YELLOW}Node management commands:${NC}"
  echo -e "  ${GREEN}install <moniker>${NC} - Install a new Story node with the specified moniker"
  echo -e "  ${GREEN}status${NC}         - Display the services status"
  echo -e "  ${GREEN}start${NC}          - Start the services"
  echo -e "  ${GREEN}stop${NC}           - Stop the services"
  echo -e "  ${GREEN}restart${NC}        - Restart the services"
  echo -e "  ${GREEN}update${NC}         - Update the binaries"
  echo -e "  ${GREEN}update-peers${NC}   - Update peers from the network"
  echo -e "  ${GREEN}update-snapshots${NC} - Update snapshots to the latest version"
  echo -e "  ${GREEN}remove${NC}         - Remove the Story node"
  echo -e "  ${GREEN}register${NC}       - Register the node as a validator"
  echo -e "  ${GREEN}export-key${NC}     - Export validator and EVM keys"
  
  echo -e "\n${YELLOW}Logging commands:${NC}"
  echo -e "  ${GREEN}logs${NC}           - Display logs for both services"
  echo -e "  ${GREEN}logs-geth${NC}      - Display logs for the Geth service"
  echo -e "  ${GREEN}logs-story${NC}     - Display logs for the Story service"
  
  echo -e "\n${YELLOW}Information commands:${NC}"
  echo -e "  ${GREEN}sync${NC}           - Show synchronization status"
  echo -e "  ${GREEN}info${NC}           - Show node information"
  echo -e "  ${GREEN}peers${NC}          - Show connected peers"
  echo -e "  ${GREEN}metrics${NC}        - Show node metrics"
  
  echo -e "\n${YELLOW}Key management commands:${NC}"
  echo -e "  ${GREEN}backup-keys${NC}    - Backup validator keys"
  echo -e "  ${GREEN}restore-keys${NC}   - Restore validator keys"
  
  echo -e "\n${YELLOW}Other:${NC}"
  echo -e "  ${GREEN}help${NC}           - Display this help"
  echo ""
}

# Function to check dependencies
check_dependencies() {
  local missing_deps=()
  
  # List of dependencies
  local deps=("aria2c" "lz4" "jq" "tar" "wget" "curl" "make" "gcc" "g++" "git" "build-essential")
  
  # Check each dependency
  for dep in "${deps[@]}"; do
    if ! command -v $dep &> /dev/null; then
      missing_deps+=($dep)
    fi
  done
  
  # Install missing dependencies
  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing missing dependencies: ${missing_deps[*]}${NC}"
    apt update
    apt install -y aria2 liblz4-tool jq tar wget curl make gcc g++ git build-essential
  fi
  
  # Verify build tools are installed
  if ! command -v make &> /dev/null; then
    echo -e "${RED}Failed to install 'make'. Installing essential build tools...${NC}"
    apt install -y build-essential
  fi
  
  if ! command -v gcc &> /dev/null; then
    echo -e "${RED}Failed to install 'gcc'. Installing C compiler...${NC}"
    apt install -y gcc g++
  fi
}

# Function to check service status
check_status() {
  echo -e "${BLUE}Checking service status...${NC}"
  
  if systemctl is-active --quiet $GETH_SERVICE; then
    echo -e "${GREEN}$GETH_SERVICE is active.${NC}"
  else
    echo -e "${RED}$GETH_SERVICE is inactive.${NC}"
  fi
  
  if systemctl is-active --quiet $STORY_SERVICE; then
    echo -e "${GREEN}$STORY_SERVICE is active.${NC}"
  else
    echo -e "${RED}$STORY_SERVICE is inactive.${NC}"
  fi
}

# Function to start services
start_services() {
  echo -e "${BLUE}Starting services...${NC}"
  systemctl start $GETH_SERVICE
  sleep 2
  systemctl start $STORY_SERVICE
  sleep 1
  check_status
}

# Function to stop services
stop_services() {
  echo -e "${BLUE}Stopping services...${NC}"
  systemctl stop $STORY_SERVICE
  sleep 1
  systemctl stop $GETH_SERVICE
  sleep 1
  check_status
}

# Function to restart services
restart_services() {
  echo -e "${BLUE}Restarting services...${NC}"
  stop_services
  sleep 2
  start_services
}

# Function to display logs
show_logs() {
  echo -e "${BLUE}Displaying real-time logs (Ctrl+C to exit)...${NC}"
  
  echo -e "${YELLOW}Displaying logs for both services (Geth and Story):${NC}"
  journalctl -u $GETH_SERVICE -u $STORY_SERVICE -f -o cat
}

# Function to display Geth logs
show_logs_geth() {
  echo -e "${YELLOW}$GETH_SERVICE real-time logs (Ctrl+C to exit):${NC}"
  journalctl -u $GETH_SERVICE -f -o cat
}

# Function to display Story logs
show_logs_story() {
  echo -e "${YELLOW}$STORY_SERVICE real-time logs (Ctrl+C to exit):${NC}"
  journalctl -u $STORY_SERVICE -f -o cat
}

# Function to update peers from the network
update_peers() {
  echo -e "${BLUE}Updating peers from the network...${NC}"
  
  # Define seeds and peers
  SEEDS="46b7995b0b77515380000b7601e6fc21f783e16f@story-testnet-seed.itrocket.net:52656"
  PEERS="01f8a2148a94f0267af919d2eab78452c90d9864@story-testnet-peer.itrocket.net:52656,e1623185b6c5403f77533003b0440fae7c33eeed@15.235.224.129:26656,311cd3903e25ab85e5a26c44510fbc747ab61760@152.53.87.97:36656,6d77bba865d84eea83f29c48d4bf034ee3540a11@37.27.127.145:26656,803b0100deb519eebaa16b9a55058d21aa8f8dd9@135.181.240.57:33656,3d7b3efbe94b84112ec4051693438c91890b09fb@144.76.106.228:62656,d596320a90d17bd630176748d02bf9294252e3d7@195.3.223.78:62656,2440358221774ba82360a08edd4bf5d43ed441a5@65.109.22.211:52656,7e311e22cff1a0d39c3758e342fa4c2ee1aea461@188.166.224.194:28656,83b25d26b8b7dd1d4a6f68182b75097d989dcdd0@88.99.137.138:14656,db6791a8e35dee076de75aebae3c89df8bba3374@65.109.50.22:56656,dfb96be7e47cd76762c1dd45a5f76e536be47faa@65.108.45.34:32655"
  
  echo -e "${YELLOW}Setting seeds: ${SEEDS}${NC}"
  echo -e "${YELLOW}Setting peers: ${PEERS}${NC}"
  
  # Update config.toml with seeds and peers
  sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
         -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.story/story/config/config.toml
  
  # Try to fetch additional peers from the network
  echo -e "${YELLOW}Trying to fetch additional peers from the network...${NC}"
  PEERS_URL="https://rpc.testnet.story.xyz/net_info"
  PEERS_DATA=$(curl -sS ${PEERS_URL})
  
  if [[ $PEERS_DATA == *"result"* ]]; then
    PEERS_LIST=$(echo $PEERS_DATA | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd, -)
    
    if [ ! -z "$PEERS_LIST" ]; then
      echo -e "${GREEN}Found additional peers from the network.${NC}"
      echo -e "${YELLOW}Adding these peers to your config...${NC}"
      
      # Add these peers to config.toml
      CURRENT_PEERS=$(grep "^persistent_peers =" $HOME/.story/story/config/config.toml | sed 's/persistent_peers = //; s/"//g')
      if [ ! -z "$CURRENT_PEERS" ]; then
        NEW_PEERS="${CURRENT_PEERS},${PEERS_LIST}"
      else
        NEW_PEERS="${PEERS_LIST}"
      fi
      
      sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$NEW_PEERS\"/}" $HOME/.story/story/config/config.toml
    else
      echo -e "${YELLOW}No additional peers found from the network.${NC}"
    fi
  else
    echo -e "${YELLOW}Could not fetch additional peers from ${PEERS_URL}${NC}"
  fi
  
  # Restart the Story service
  echo -e "${YELLOW}Restarting Story service...${NC}"
  systemctl restart $STORY_SERVICE
  
  echo -e "${GREEN}Peers updated successfully!${NC}"
  echo -e "${YELLOW}Wait a few minutes for connections to establish, then check with: $0 peers${NC}"
}

# Function to check synchronization status - FIXED
check_sync() {
  echo -e "${BLUE}Checking synchronization status...${NC}"
  
  # Check if geth.ipc exists
  if [ -S "$HOME/.story/geth/aeneid/geth.ipc" ]; then
    echo -e "${YELLOW}Geth sync status:${NC}"
    GETH_SYNCING=$($HOME/go/bin/geth --exec "eth.syncing" attach $HOME/.story/geth/aeneid/geth.ipc)
    
    if [ "$GETH_SYNCING" == "false" ]; then
      BLOCK_NUMBER=$($HOME/go/bin/geth --exec "eth.blockNumber" attach $HOME/.story/geth/aeneid/geth.ipc)
      echo -e "${GREEN}Geth is synchronized. Current block: $BLOCK_NUMBER${NC}"
    else
      echo -e "${YELLOW}Geth is still syncing:${NC}"
      $HOME/go/bin/geth --exec "eth.syncing" attach $HOME/.story/geth/aeneid/geth.ipc
    fi
  else
    echo -e "${RED}Error: Geth IPC file not found. Is Geth running?${NC}"
    
    # Fallback to HTTP API
    echo -e "${YELLOW}Trying HTTP API instead...${NC}"
    local eth_block=$(curl -s localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' | jq -r '.result')
    
    if [ "$eth_block" == "null" ]; then
      echo -e "${YELLOW}Geth node synchronized or connection error${NC}"
      local block_number=$(curl -s localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
      if [ "$block_number" != "null" ]; then
        # Convert hex block to decimal
        local block_number_dec=$((16#${block_number:2}))
        echo -e "${GREEN}Current block height: $block_number_dec${NC}"
      fi
    else
      echo -e "${YELLOW}Syncing: ${NC}"
      echo $eth_block | jq
    fi
  fi
  
  # Check Story node sync status
  # First try using the RPC port from config
  RPC_PORT=$(sed -n '/\[rpc\]/,/laddr/ { /laddr/ {s/.*://; s/".*//; p} }' $HOME/.story/story/config/config.toml)
  
  if [ -z "$RPC_PORT" ]; then
    RPC_PORT=26657 # Default fallback
  fi
  
  echo -e "\n${YELLOW}Story synchronization status:${NC}"
  local sync_info=$(curl -s localhost:$RPC_PORT/status)
  
  if [[ $sync_info == *"result"* ]]; then
    # Successful response
    sync_info=$(echo $sync_info | jq '.result.sync_info')
    
    if [ -z "$sync_info" ]; then
      echo -e "${RED}Error: Unable to parse Story synchronization status.${NC}"
    else
      local latest_block_height=$(echo $sync_info | jq -r '.latest_block_height')
      local catching_up=$(echo $sync_info | jq -r '.catching_up')
      
      echo -e "${GREEN}Story block height: $latest_block_height${NC}"
      
      if [ "$catching_up" == "true" ]; then
        echo -e "${YELLOW}Status: Synchronizing (catching_up: true)${NC}"
      else
        echo -e "${GREEN}Status: Synchronized (catching_up: false)${NC}"
      fi
    fi
  else
    echo -e "${RED}Error: Unable to connect to Story RPC (port: $RPC_PORT).${NC}"
    echo -e "Please verify if the Story service is running: systemctl status $STORY_SERVICE"
  fi
}

# Function to display node information - FIXED
show_info() {
  echo -e "${BLUE}Retrieving node information...${NC}"
  
  # First try using the RPC port from config
  RPC_PORT=$(sed -n '/\[rpc\]/,/laddr/ { /laddr/ {s/.*://; s/".*//; p} }' $HOME/.story/story/config/config.toml)
  
  if [ -z "$RPC_PORT" ]; then
    RPC_PORT=26657 # Default fallback
  fi
  
  local status_response=$(curl -s localhost:$RPC_PORT/status)
  
  if [[ $status_response == *"result"* ]]; then
    # Successful response
    local node_info=$(echo $status_response | jq '.result.node_info')
    local sync_info=$(echo $status_response | jq '.result.sync_info')
    
    if [ -z "$node_info" ] || [ -z "$sync_info" ]; then
      echo -e "${RED}Error: Unable to parse node information.${NC}"
      exit 1
    fi
    
    local node_id=$(echo $node_info | jq -r '.id')
    local moniker=$(echo $node_info | jq -r '.moniker')
    local network=$(echo $node_info | jq -r '.network')
    local latest_block_height=$(echo $sync_info | jq -r '.latest_block_height')
    local catching_up=$(echo $sync_info | jq -r '.catching_up')
    
    echo -e "${GREEN}Node information:${NC}"
    echo -e "Node ID: $node_id"
    echo -e "Moniker: $moniker"
    echo -e "Network: $network"
    echo -e "Block height: $latest_block_height"
    echo -e "Synchronizing: $catching_up"
    
    # Check validator status
    local validator_status=$(echo $status_response | jq -r '.result.validator_info')
    
    echo -e "\n${GREEN}Validator information:${NC}"
    if [ "$validator_status" == "null" ]; then
      echo -e "${YELLOW}This node is not an active validator.${NC}"
    else
      echo $validator_status | jq
    fi
    
    # Show Geth info
    if [ -S "$HOME/.story/geth/aeneid/geth.ipc" ]; then
      echo -e "\n${GREEN}Geth information:${NC}"
      echo -e "Block number: $($HOME/go/bin/geth --exec "eth.blockNumber" attach $HOME/.story/geth/aeneid/geth.ipc 2>/dev/null || echo "Error fetching block number")"
      echo -e "Syncing: $($HOME/go/bin/geth --exec "eth.syncing" attach $HOME/.story/geth/aeneid/geth.ipc 2>/dev/null || echo "Error fetching sync status")"
      echo -e "Network ID: $($HOME/go/bin/geth --exec "net.version" attach $HOME/.story/geth/aeneid/geth.ipc 2>/dev/null || echo "Error fetching network ID")"
      echo -e "Peer count: $($HOME/go/bin/geth --exec "net.peerCount" attach $HOME/.story/geth/aeneid/geth.ipc 2>/dev/null || echo "Error fetching peer count")"
    else
      echo -e "\n${RED}Geth IPC file not found at $HOME/.story/geth/aeneid/geth.ipc${NC}"
      echo -e "${YELLOW}Check if Geth is running and the correct network (aeneid) is configured.${NC}"
    fi
    
    # Get validator address and EVM address
    if [ -x "$HOME/go/bin/story" ]; then
      if [ -f "$HOME/.story/story/config/priv_validator_key.json" ]; then
        echo -e "\n${GREEN}Validator key information:${NC}"
        VALIDATOR_EXPORT=$($HOME/go/bin/story validator export 2>/dev/null)
        if [[ $VALIDATOR_EXPORT == *"PUB_KEY"* ]]; then
          echo -e "Validator public key: $(echo "$VALIDATOR_EXPORT" | grep "PUB_KEY" | cut -d'=' -f2)"
        else
          echo -e "${YELLOW}Could not extract validator public key${NC}"
        fi
        
        if [ -f "$HOME/.story/story/config/private_key.txt" ]; then
          echo -e "\n${GREEN}EVM information:${NC}"
          EVM_ADDRESS=$($HOME/go/bin/story validator address 2>/dev/null)
          if [ ! -z "$EVM_ADDRESS" ]; then
            echo -e "EVM address: $EVM_ADDRESS"
            
            # Check validator balance if geth is running
            if [ -S "$HOME/.story/geth/aeneid/geth.ipc" ]; then
              BALANCE=$($HOME/go/bin/geth --exec "web3.fromWei(eth.getBalance('$EVM_ADDRESS'), 'ether')" attach $HOME/.story/geth/aeneid/geth.ipc 2>/dev/null)
              if [ ! -z "$BALANCE" ] && [[ ! "$BALANCE" == *"SyntaxError"* ]]; then
                echo -e "Balance: $BALANCE IP"
              else
                echo -e "${YELLOW}Could not get balance, please check manually${NC}"
              fi
            else
              echo -e "${YELLOW}Geth is not running, cannot check balance${NC}"
            fi
          else
            echo -e "${YELLOW}Could not get EVM address${NC}"
          fi
        else
          echo -e "${YELLOW}EVM private key file not found${NC}"
        fi
      else
        echo -e "${YELLOW}Validator key file not found${NC}"
      fi
    else
      echo -e "${YELLOW}Story binary not found in $HOME/go/bin/story${NC}"
    fi
  else
    echo -e "${RED}Error: Unable to connect to Story RPC (port: $RPC_PORT).${NC}"
    echo -e "Please verify if the Story service is running: systemctl status $STORY_SERVICE"
    echo -e "Error details: $status_response"
  fi
}

# Function to display connected peers - FIXED
show_peers() {
  echo -e "${BLUE}Retrieving connected peers...${NC}"
  
  # Check Geth peers
  if [ -S "$HOME/.story/geth/aeneid/geth.ipc" ]; then
    echo -e "${YELLOW}Geth peers:${NC}"
    PEER_COUNT=$($HOME/go/bin/geth --exec "net.peerCount" attach $HOME/.story/geth/aeneid/geth.ipc 2>/dev/null || echo "Error")
    
    if [[ "$PEER_COUNT" == "Error" ]]; then
      echo -e "${RED}Error fetching Geth peer count. Is Geth running?${NC}"
    else
      echo -e "Connected to ${GREEN}$PEER_COUNT${NC} peers"
      
      if [ "$PEER_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}Peer details:${NC}"
        PEERS_DATA=$($HOME/go/bin/geth --exec "admin.peers" attach $HOME/.story/geth/aeneid/geth.ipc 2>/dev/null)
        echo "$PEERS_DATA" | jq '.' 2>/dev/null || echo "$PEERS_DATA"
      else
        echo -e "${YELLOW}No peers connected to Geth.${NC}"
        echo -e "${YELLOW}Trying to add peers for Geth...${NC}"
        
        # Try to add a bootnode
        BOOTNODE="enode://64f0cec7ffb47c868cfcd63a1c30d4944c26cb4fd59b42b9b55c9ba567dea7ecbb80099e9e87e242e5600b36e3a6b39a8c9db28f1f43a7f74e2f9ce76dd6da26@52.18.124.107:30303"
        $HOME/go/bin/geth --exec "admin.addPeer('$BOOTNODE')" attach $HOME/.story/geth/aeneid/geth.ipc 2>/dev/null
        
        echo -e "${YELLOW}Added bootnode for Geth. Check again in a few minutes.${NC}"
      fi
    fi
  else
    echo -e "${RED}Error: Geth IPC file not found at $HOME/.story/geth/aeneid/geth.ipc${NC}"
    echo -e "${YELLOW}Is Geth running? Check with: systemctl status $GETH_SERVICE${NC}"
    
    # Fallback to HTTP API
    echo -e "${YELLOW}Trying HTTP API instead...${NC}"
    GETH_PORT=$(echo $STORY_PORT)545
    if [ -z "$GETH_PORT" ]; then
      GETH_PORT=8545 # Default fallback
    fi
    
    HTTP_RESULT=$(curl -s localhost:$GETH_PORT -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' 2>/dev/null)
    
    if [[ $HTTP_RESULT == *"result"* ]]; then
      PEER_COUNT_HEX=$(echo $HTTP_RESULT | jq -r '.result')
      if [ ! -z "$PEER_COUNT_HEX" ] && [ "$PEER_COUNT_HEX" != "null" ]; then
        PEER_COUNT_DEC=$((16#${PEER_COUNT_HEX:2}))
        echo -e "Connected to ${GREEN}$PEER_COUNT_DEC${NC} peers via HTTP API"
      else
        echo -e "${YELLOW}No peers connected or error in API response.${NC}"
      fi
    else
      echo -e "${RED}Error connecting to Geth HTTP API on port $GETH_PORT${NC}"
    fi
  fi
  
  # Check Story peers
  RPC_PORT=$(sed -n '/\[rpc\]/,/laddr/ { /laddr/ {s/.*://; s/".*//; p} }' $HOME/.story/story/config/config.toml)
  
  if [ -z "$RPC_PORT" ]; then
    RPC_PORT=26657 # Default fallback
  fi
  
  echo -e "\n${YELLOW}Story peers:${NC}"
  local net_info=$(curl -s localhost:$RPC_PORT/net_info 2>/dev/null)
  
  if [[ $net_info == *"result"* ]]; then
    local peer_count=$(echo $net_info | jq '.result.peers | length')
    echo -e "Connected to ${GREEN}$peer_count${NC} peers"
    
    if [ "$peer_count" -gt 0 ]; then
      echo -e "${YELLOW}Peer details:${NC}"
      echo $net_info | jq '.result.peers[] | {node_id: .node_info.id, addr: .remote_ip, moniker: .node_info.moniker}'
    else
      echo -e "${YELLOW}No peers connected to Story node.${NC}"
      echo -e "${YELLOW}You can try to update peers with: $0 update-peers${NC}"
      
      # Show configured peers
      echo -e "${YELLOW}Currently configured peers:${NC}"
      CONFIGURED_PEERS=$(grep "persistent_peers" $HOME/.story/story/config/config.toml | sed 's/persistent_peers = //; s/"//g')
      if [ ! -z "$CONFIGURED_PEERS" ]; then
        echo -e "$CONFIGURED_PEERS"
      else
        echo -e "${RED}No persistent peers configured.${NC}"
      fi
    fi
  else
    echo -e "${RED}Error: Unable to connect to Story RPC (port: $RPC_PORT).${NC}"
    echo -e "Please verify if the Story service is running: systemctl status $STORY_SERVICE"
  fi
  
  echo -e "\n${YELLOW}Suggestions if you have no peers:${NC}"
  echo -e "1. Run '$0 update-peers' to update your peer configuration"
  echo -e "2. Check your firewall settings to ensure ports are open"
  echo -e "3. Wait a few minutes for connections to be established"
  echo -e "4. Restart the services with '$0 restart'"
}

# Function to display metrics - FIXED
show_metrics() {
  echo -e "${BLUE}Retrieving metrics...${NC}"
  
  # Check Geth metrics
  if [ -S "$HOME/.story/geth/aeneid/geth.ipc" ]; then
    echo -e "${YELLOW}Geth metrics:${NC}"
    echo -e "Block number: $($HOME/go/bin/geth --exec "eth.blockNumber" attach $HOME/.story/geth/aeneid/geth.ipc)"
    echo -e "Gas price: $($HOME/go/bin/geth --exec "eth.gasPrice" attach $HOME/.story/geth/aeneid/geth.ipc)"
    echo -e "Peer count: $($HOME/go/bin/geth --exec "net.peerCount" attach $HOME/.story/geth/aeneid/geth.ipc)"
    echo -e "Network ID: $($HOME/go/bin/geth --exec "net.version" attach $HOME/.story/geth/aeneid/geth.ipc)"
    echo -e "Mining: $($HOME/go/bin/geth --exec "eth.mining" attach $HOME/.story/geth/aeneid/geth.ipc)"
    echo -e "Coinbase: $($HOME/go/bin/geth --exec "eth.coinbase" attach $HOME/.story/geth/aeneid/geth.ipc)"
  else
    echo -e "${RED}Error: Geth IPC file not found. Is Geth running?${NC}"
    
    # Fallback to HTTP API
    echo -e "${YELLOW}Trying HTTP API instead...${NC}"
    curl -s localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq
  fi
  
  # Check Story metrics
  RPC_PORT=$(sed -n '/\[rpc\]/,/laddr/ { /laddr/ {s/.*://; s/".*//; p} }' $HOME/.story/story/config/config.toml)
  
  if [ -z "$RPC_PORT" ]; then
    RPC_PORT=26657 # Default fallback
  fi
  
  echo -e "\n${YELLOW}Story metrics:${NC}"
  
  # Get consensus state
  local consensus_state=$(curl -s localhost:$RPC_PORT/consensus_state)
  if [[ $consensus_state == *"result"* ]]; then
    echo -e "${GREEN}Consensus state:${NC}"
    echo $consensus_state | jq '.result.round_state.height_vote_set[0].prevotes_bit_array'
  fi
  
  # Get network info
  local net_info=$(curl -s localhost:$RPC_PORT/net_info)
  if [[ $net_info == *"result"* ]]; then
    echo -e "\n${GREEN}Network info:${NC}"
    echo $net_info | jq '.result.n_peers'
  fi
  
  # Get abci info
  local abci_info=$(curl -s localhost:$RPC_PORT/abci_info)
  if [[ $abci_info == *"result"* ]]; then
    echo -e "\n${GREEN}ABCI info:${NC}"
    echo $abci_info | jq '.result.response'
  fi
  
  if [[ $consensus_state != *"result"* ]] && [[ $net_info != *"result"* ]] && [[ $abci_info != *"result"* ]]; then
    echo -e "${RED}Error: Unable to connect to Story RPC (port: $RPC_PORT).${NC}"
    echo -e "Please verify if the Story service is running: systemctl status $STORY_SERVICE"
  fi
}

# Function to update binaries
update_binaries() {
  echo -e "${BLUE}Updating binaries...${NC}"
  
  # Stop services
  stop_services
  
  # Update Geth
  echo -e "${YELLOW}Updating Geth to $STORY_GETH_VERSION...${NC}"
  cd $HOME
  rm -rf story-geth
  git clone https://github.com/piplabs/story-geth.git
  cd story-geth
  git checkout $STORY_GETH_VERSION
  make geth
  mv build/bin/geth $HOME/go/bin/
  
  # Update Story
  echo -e "${YELLOW}Updating Story to $STORY_VERSION...${NC}"
  cd $HOME
  rm -rf story
  git clone https://github.com/piplabs/story
  cd story
  git checkout $STORY_VERSION
  go build -o story ./client
  mv story $HOME/go/bin/
  
  # Restart services
  start_services
  
  echo -e "${GREEN}Update completed!${NC}"
}

# Function to import snapshots
import_snapshots() {
  echo -e "${YELLOW}Downloading and importing snapshots...${NC}"
  
  # Install lz4 if needed
  if ! command -v lz4 &> /dev/null; then
    echo -e "${YELLOW}Installing lz4...${NC}"
    sudo apt update && sudo apt install -y liblz4-tool
  fi
  
  # Install curl if needed
  if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}Installing curl...${NC}"
    sudo apt update && sudo apt install -y curl
  fi
  
  # Get the latest snapshot filenames from the server
  echo -e "${YELLOW}Finding latest available snapshots...${NC}"
  
  # Backup priv_validator_state.json
  if [ -f "$HOME/.story/story/data/priv_validator_state.json" ]; then
    echo -e "${YELLOW}Backing up priv_validator_state.json...${NC}"
    cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup
  fi
  
  # Get list of files on the server
  SNAPSHOT_HTML=$(curl -s $SNAPSHOT_BASE_URL)
  STORY_SNAPSHOT=$(echo "$SNAPSHOT_HTML" | grep -o 'story_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\+_snap\.tar\.lz4' | sort -r | head -n 1)
  GETH_SNAPSHOT=$(echo "$SNAPSHOT_HTML" | grep -o 'geth_story_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\+_snap\.tar\.lz4' | sort -r | head -n 1)
  
  if [ -z "$STORY_SNAPSHOT" ] || [ -z "$GETH_SNAPSHOT" ]; then
    echo -e "${RED}Error: Unable to find the most recent snapshots.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Latest snapshots found:${NC}"
  echo -e "Story: $STORY_SNAPSHOT"
  echo -e "Geth: $GETH_SNAPSHOT"
  
  # Remove old data and extract Story snapshot
  echo -e "${YELLOW}Removing old Story data...${NC}"
  rm -rf $HOME/.story/story/data
  
  echo -e "${YELLOW}Downloading and extracting Story snapshot...${NC}"
  curl -s ${SNAPSHOT_BASE_URL}${STORY_SNAPSHOT} | lz4 -dc - | tar -xf - -C $HOME/.story/story 2>/dev/null
  
  # Restore priv_validator_state.json
  if [ -f "$HOME/.story/story/priv_validator_state.json.backup" ]; then
    echo -e "${YELLOW}Restoring priv_validator_state.json...${NC}"
    mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json
  fi
  
  # Remove Geth data and extract snapshot
  echo -e "${YELLOW}Removing Geth data...${NC}"
  rm -rf $HOME/.story/geth/aeneid/geth/chaindata
  mkdir -p $HOME/.story/geth/aeneid/geth
  
  echo -e "${YELLOW}Downloading and extracting Geth snapshot...${NC}"
  curl -s ${SNAPSHOT_BASE_URL}${GETH_SNAPSHOT} | lz4 -dc - | tar -xf - -C $HOME/.story/geth/aeneid/geth 2>/dev/null
  
  echo -e "${GREEN}Snapshots imported successfully!${NC}"
}

# Function to install a new node
install_node() {
  check_dependencies
  
  if [ -z "$1" ]; then
    echo -e "${RED}Error: Moniker is required for installation.${NC}"
    show_help
    exit 1
  fi
  
  local moniker=$1
  
  echo -e "${BLUE}Installing a Story node with moniker: $moniker${NC}"
  
  # Install Go if needed
  echo -e "${YELLOW}Checking and installing Go...${NC}"
  cd $HOME
  VER="$GO_VERSION"
  wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz" 2>/dev/null
  rm "go$VER.linux-amd64.tar.gz"
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  source $HOME/.bash_profile
  [ ! -d ~/go/bin ] && mkdir -p ~/go/bin
  
  # Set variables
  echo "export MONIKER=\"$moniker\"" >> $HOME/.bash_profile
  echo "export STORY_CHAIN_ID=\"aeneid\"" >> $HOME/.bash_profile
  echo "export STORY_PORT=\"52\"" >> $HOME/.bash_profile
  source $HOME/.bash_profile
  
  # Display environment for debugging
  echo -e "${YELLOW}Environment variables:${NC}"
  echo "PATH=$PATH"
  echo "MONIKER=$MONIKER"
  echo "STORY_CHAIN_ID=$STORY_CHAIN_ID"
  echo "STORY_PORT=$STORY_PORT"
  
  # Download and install Geth binaries
  echo -e "${YELLOW}Installing Story-Geth...${NC}"
  cd $HOME
  rm -rf story-geth
  git clone https://github.com/piplabs/story-geth.git
  cd story-geth
  git checkout $STORY_GETH_VERSION
  make geth
  cp build/bin/geth $HOME/go/bin/
  chmod +x $HOME/go/bin/geth
  
  # Create necessary directories
  [ ! -d "$HOME/.story/story" ] && mkdir -p "$HOME/.story/story"
  [ ! -d "$HOME/.story/geth" ] && mkdir -p "$HOME/.story/geth"
  
  # Install Story
  echo -e "${YELLOW}Installing Story...${NC}"
  cd $HOME
  rm -rf story
  git clone https://github.com/piplabs/story
  cd story
  git checkout $STORY_VERSION
  go build -o story ./client
  mkdir -p $HOME/go/bin/
  cp $HOME/story/story $HOME/go/bin/
  chmod +x $HOME/go/bin/story
  
  # Initialize Story application
  echo -e "${YELLOW}Initializing Story...${NC}"
  $HOME/go/bin/story init --moniker $MONIKER --network $STORY_CHAIN_ID
  
  # Configure seeds and peers
  echo -e "${YELLOW}Configuring peers and seeds...${NC}"
  SEEDS="46b7995b0b77515380000b7601e6fc21f783e16f@story-testnet-seed.itrocket.net:52656"
  PEERS="01f8a2148a94f0267af919d2eab78452c90d9864@story-testnet-peer.itrocket.net:52656,e1623185b6c5403f77533003b0440fae7c33eeed@15.235.224.129:26656,311cd3903e25ab85e5a26c44510fbc747ab61760@152.53.87.97:36656,6d77bba865d84eea83f29c48d4bf034ee3540a11@37.27.127.145:26656,803b0100deb519eebaa16b9a55058d21aa8f8dd9@135.181.240.57:33656,3d7b3efbe94b84112ec4051693438c91890b09fb@144.76.106.228:62656,d596320a90d17bd630176748d02bf9294252e3d7@195.3.223.78:62656,2440358221774ba82360a08edd4bf5d43ed441a5@65.109.22.211:52656,7e311e22cff1a0d39c3758e342fa4c2ee1aea461@188.166.224.194:28656,83b25d26b8b7dd1d4a6f68182b75097d989dcdd0@88.99.137.138:14656,db6791a8e35dee076de75aebae3c89df8bba3374@65.109.50.22:56656,dfb96be7e47cd76762c1dd45a5f76e536be47faa@65.108.45.34:32655"
  sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
         -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.story/story/config/config.toml
  
  # Configure custom ports in story.toml
  echo -e "${YELLOW}Configuring ports in story.toml...${NC}"
  sed -i.bak -e "s%:1317%:${STORY_PORT}317%g;
s%:8551%:${STORY_PORT}551%g" $HOME/.story/story/config/story.toml
  
  # Configure custom ports in config.toml
  echo -e "${YELLOW}Configuring ports in config.toml...${NC}"
  sed -i.bak -e "s%:26658%:${STORY_PORT}658%g;
s%:26657%:${STORY_PORT}657%g;
s%:26656%:${STORY_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${STORY_PORT}656\"%;
s%:26660%:${STORY_PORT}660%g" $HOME/.story/story/config/config.toml
  
  # Enable prometheus and disable indexing
  echo -e "${YELLOW}Configuring prometheus and indexing...${NC}"
  sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.story/story/config/config.toml
  sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.story/story/config/config.toml
  
  # Create Geth service file
  echo -e "${YELLOW}Creating Geth service file...${NC}"
  sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/geth --aeneid --syncmode full --http --http.api eth,net,web3,engine --http.vhosts '*' --http.addr 0.0.0.0 --http.port ${STORY_PORT}545 --authrpc.port ${STORY_PORT}551 --ws --ws.api eth,web3,net,txpool --ws.addr 0.0.0.0 --ws.port ${STORY_PORT}546
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
  
  # Create Story service file
  echo -e "${YELLOW}Creating Story service file...${NC}"
  sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/.story/story
ExecStart=$(which story) run

Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
  
  # Download snapshots
  import_snapshots

  # Enable and start services
  echo -e "${YELLOW}Enabling and starting services...${NC}"
  sudo systemctl daemon-reload
  sudo systemctl enable story-geth story
  sudo systemctl restart story-geth 
  sleep 5 
  sudo systemctl restart story
  
  echo -e "${GREEN}Installation completed successfully!${NC}"
  echo -e "${YELLOW}To check logs:${NC} journalctl -u story -u story-geth -f"
  echo -e "${YELLOW}After synchronization, export your validator key with:${NC} $0 export-key"
}

# Function to register a node as validator
register_validator() {
  echo -e "${BLUE}Registering node as validator...${NC}"
  
  # Check if node is synchronized
  CATCHING_UP=$(curl -s localhost:$(sed -n '/\[rpc\]/,/laddr/ { /laddr/ {s/.*://; s/".*//; p} }' $HOME/.story/story/config/config.toml)/status | jq -r '.result.sync_info.catching_up')
  
  if [ "$CATCHING_UP" == "true" ]; then
    echo -e "${RED}Error: Node is not yet synchronized. Please wait for synchronization to complete.${NC}"
    echo -e "You can check the synchronization status with: $0 sync"
    exit 1
  fi
  
  # Get moniker from the config file correctly
  MONIKER=$(grep -E "^moniker[ ]*=" $HOME/.story/story/config/config.toml | sed -E 's/moniker[ ]*=[ ]*"([^"]*)"/\1/')
  
  if [ -z "$MONIKER" ]; then
    MONIKER="validator"
  fi
  
  # Ask if user wants to use a different moniker
  read -p "Current moniker: $MONIKER. Do you want to use a different name? (y/N) " change_moniker
  if [[ $change_moniker == [yY] || $change_moniker == [yY][eE][sS] ]]; then
    read -p "Enter new moniker: " new_moniker
    if [ ! -z "$new_moniker" ]; then
      MONIKER=$new_moniker
    fi
  fi
  
  # Export validator key and get addresses
  VALIDATOR_INFO=$($HOME/go/bin/story validator export)
  VALOPER_ADDRESS=$(echo "$VALIDATOR_INFO" | grep "Validator Address:" | awk '{print $3}')
  EVM_ADDRESS=$(echo "$VALIDATOR_INFO" | grep "EVM Address:" | awk '{print $3}')
  
  # Fixed values for the validator
  local stake_amount="1024000000000000000000"
  local commission_rate="700"
  local rpc_endpoint="https://aeneid.storyrpc.io"
  local unlocked="true"
  
  echo -e "${YELLOW}Validator will be created with the following parameters:${NC}"
  echo -e "Stake amount: $stake_amount"
  echo -e "Commission rate: $commission_rate bips (7%)"
  echo -e "RPC endpoint: $rpc_endpoint"
  echo -e "Unlocked tokens: $unlocked"
  echo -e "Moniker: $MONIKER"
  
  # Create .env file if needed
  if [ -f "$HOME/.story/story/config/private_key.txt" ]; then
    echo -e "${YELLOW}Creating .env file for validator operations...${NC}"
    PRIVATE_KEY=$(cat $HOME/.story/story/config/private_key.txt | grep "PRIVATE_KEY" | awk -F'=' '{print $2}')
    # Place .env in the same directory as the story binary
    echo "PRIVATE_KEY=$PRIVATE_KEY" > $HOME/go/bin/.env
    echo -e "${GREEN}Created .env file in $HOME/go/bin/.env with your private key${NC}"
  else
    echo -e "${YELLOW}Exporting EVM key...${NC}"
    $HOME/go/bin/story validator export --export-evm-key
    
    # Wait for file creation
    sleep 2
    
    if [ -f "$HOME/.story/story/config/private_key.txt" ]; then
      echo -e "${YELLOW}Creating .env file for validator operations...${NC}"
      PRIVATE_KEY=$(cat $HOME/.story/story/config/private_key.txt | grep "PRIVATE_KEY" | awk -F'=' '{print $2}')
      # Place .env in the same directory as the story binary
      echo "PRIVATE_KEY=$PRIVATE_KEY" > $HOME/go/bin/.env
      echo -e "${GREEN}Created .env file in $HOME/go/bin/.env with your private key${NC}"
    else
      echo -e "${RED}Error: Could not export EVM key.${NC}"
      exit 1
    fi
  fi
  
  # Complete command to create the validator
  CREATE_CMD="$HOME/go/bin/story validator create --stake $stake_amount --moniker \"$MONIKER\" --rpc $rpc_endpoint --chain-id 1315 --commission-rate $commission_rate --unlocked=$unlocked"
  
  echo -e "${YELLOW}Executing validator creation command:${NC}"
  echo -e "$CREATE_CMD"
  
  # Execute the command directly without asking for confirmation
  cd $HOME/go/bin
  story validator create --stake "$stake_amount" --moniker "$MONIKER" --rpc "$rpc_endpoint" --chain-id 1315 --commission-rate "$commission_rate" --unlocked="$unlocked"
  
  # Display important information
  echo -e "\n${GREEN}Important information:${NC}"
  echo -e "Validator address: ${VALOPER_ADDRESS}"
  echo -e "EVM address: ${EVM_ADDRESS}"
  echo -e "\n${YELLOW}Note: If you don't have enough funds, the transaction will fail. This is normal if you haven't funded your account yet.${NC}"
  echo -e "${YELLOW}You can check if your validator is in the active set with:${NC}"
  echo -e "curl https://aeneid.storyrpc.io/validators | jq ."
}

# Function to remove the node
remove_node() {
  read -p "Are you sure you want to remove the Story node? This action is irreversible. (y/N) " confirm
  if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo -e "${BLUE}Removing Story node...${NC}"
    
    # Stop services
    echo -e "${YELLOW}Stopping services...${NC}"
    systemctl stop story-geth story
    
    # Disable services
    echo -e "${YELLOW}Disabling services...${NC}"
    systemctl disable story-geth story
    
    # Remove service files
    echo -e "${YELLOW}Removing service files...${NC}"
    rm -f /etc/systemd/system/story-geth.service
    rm -f /etc/systemd/system/story.service
    systemctl daemon-reload
    
    # Ask about data removal
    read -p "Do you want to remove all data including keys? (y/N) " remove_data
    if [[ $remove_data == [yY] || $remove_data == [yY][eE][sS] ]]; then
      echo -e "${YELLOW}Removing all Story data...${NC}"
      rm -rf $HOME/.story
    else
      echo -e "${YELLOW}Keeping data directory intact.${NC}"
    fi
    
    echo -e "${GREEN}Story node removed successfully!${NC}"
  else
    echo -e "${YELLOW}Removal cancelled.${NC}"
  fi
}

# Function to backup validator keys
backup_keys() {
  echo -e "${BLUE}Backing up validator keys...${NC}"
  
  # Create backup directory if it doesn't exist
  mkdir -p $BACKUP_DIR
  
  # Check keys existence
  local files_to_backup=()
  
  if [ -f "$EVM_KEY_PATH" ]; then
    files_to_backup+=("$EVM_KEY_PATH")
    echo -e "${GREEN}EVM key found: $EVM_KEY_PATH${NC}"
  else
    echo -e "${YELLOW}EVM key not found: $EVM_KEY_PATH${NC}"
  fi
  
  if [ -f "$VALIDATOR_KEY_PATH" ]; then
    files_to_backup+=("$VALIDATOR_KEY_PATH")
    echo -e "${GREEN}Validator key found: $VALIDATOR_KEY_PATH${NC}"
  else
    echo -e "${YELLOW}Validator key not found: $VALIDATOR_KEY_PATH${NC}"
  fi
  
  if [ -f "$PRIV_VALIDATOR_STATE" ]; then
    files_to_backup+=("$PRIV_VALIDATOR_STATE")
    echo -e "${GREEN}Validator state found: $PRIV_VALIDATOR_STATE${NC}"
  else
    echo -e "${YELLOW}Validator state not found: $PRIV_VALIDATOR_STATE${NC}"
  fi
  
  # If no files to backup
  if [ ${#files_to_backup[@]} -eq 0 ]; then
    echo -e "${RED}No files to backup. Please check your installation.${NC}"
    exit 1
  fi
  
  # Create backup archive
  tar -czf "$BACKUP_DIR/story_keys_backup.tar.gz" "${files_to_backup[@]}" 2>/dev/null
  
  echo -e "${GREEN}Backup created at $BACKUP_DIR/story_keys_backup.tar.gz${NC}"
  echo -e "This backup contains:"
  
  if [[ " ${files_to_backup[*]} " =~ " $EVM_KEY_PATH " ]]; then
    echo -e "  - EVM private key (from $EVM_KEY_PATH)"
  fi
  
  if [[ " ${files_to_backup[*]} " =~ " $VALIDATOR_KEY_PATH " ]]; then
    echo -e "  - Tendermint validator key (from $VALIDATOR_KEY_PATH)"
  fi
  
  if [[ " ${files_to_backup[*]} " =~ " $PRIV_VALIDATOR_STATE " ]]; then
    echo -e "  - Validator state (from $PRIV_VALIDATOR_STATE)"
  fi
}

# Function to restore validator keys
restore_keys() {
  if [ ! -f "$BACKUP_DIR/story_keys_backup.tar.gz" ]; then
    echo -e "${RED}Error: Backup file not found at $BACKUP_DIR/story_keys_backup.tar.gz${NC}"
    exit 1
  fi
  
  echo -e "${BLUE}Restoring validator keys...${NC}"
  
  # Stop services
  echo -e "${YELLOW}Stopping services...${NC}"
  systemctl stop $STORY_SERVICE
  sleep 1
  
  # Extract keys
  echo -e "${YELLOW}Extracting keys...${NC}"
  tar -xzf "$BACKUP_DIR/story_keys_backup.tar.gz" -C / 2>/dev/null
  
  # Check permissions
  echo -e "${YELLOW}Checking permissions...${NC}"
  if [ -f "$EVM_KEY_PATH" ]; then
    chmod 600 "$EVM_KEY_PATH"
  fi
  
  if [ -f "$VALIDATOR_KEY_PATH" ]; then
    chmod 600 "$VALIDATOR_KEY_PATH"
  fi
  
  if [ -f "$PRIV_VALIDATOR_STATE" ]; then
    chmod 600 "$PRIV_VALIDATOR_STATE"
  fi
  
  # Restart services
  echo -e "${YELLOW}Restarting services...${NC}"
  systemctl start $STORY_SERVICE
  
  echo -e "${GREEN}Keys restored successfully!${NC}"
}

# Function to update snapshots with latest version
update_snapshots() {
  echo -e "${BLUE}Updating to latest snapshots...${NC}"
  
  # Stop services
  echo -e "${YELLOW}Stopping services...${NC}"
  systemctl stop $STORY_SERVICE
  sleep 1
  systemctl stop $GETH_SERVICE
  sleep 1
  
  # Install lz4 if needed
  if ! command -v lz4 &> /dev/null; then
    echo -e "${YELLOW}Installing lz4...${NC}"
    sudo apt update && sudo apt install -y liblz4-tool
  fi
  
  # Install curl if needed
  if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}Installing curl...${NC}"
    sudo apt update && sudo apt install -y curl
  fi
  
  # Get the latest snapshot filenames from the server
  echo -e "${YELLOW}Finding latest available snapshots...${NC}"
  
  # Get list of files on the server
  SNAPSHOT_HTML=$(curl -s $SNAPSHOT_BASE_URL)
  STORY_SNAPSHOT=$(echo "$SNAPSHOT_HTML" | grep -o 'story_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\+_snap\.tar\.lz4' | sort -r | head -n 1)
  GETH_SNAPSHOT=$(echo "$SNAPSHOT_HTML" | grep -o 'geth_story_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\+_snap\.tar\.lz4' | sort -r | head -n 1)
  
  if [ -z "$STORY_SNAPSHOT" ] || [ -z "$GETH_SNAPSHOT" ]; then
    echo -e "${RED}Error: Unable to find the most recent snapshots.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Latest snapshots found:${NC}"
  echo -e "Story: $STORY_SNAPSHOT"
  echo -e "Geth: $GETH_SNAPSHOT"
  
  # Backup priv_validator_state.json
  if [ -f "$HOME/.story/story/data/priv_validator_state.json" ]; then
    echo -e "${YELLOW}Backing up priv_validator_state.json...${NC}"
    cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup
  fi
  
  # Remove old data and extract Story snapshot
  echo -e "${YELLOW}Removing old Story data...${NC}"
  rm -rf $HOME/.story/story/data
  
  echo -e "${YELLOW}Downloading and extracting Story snapshot...${NC}"
  curl -s ${SNAPSHOT_BASE_URL}${STORY_SNAPSHOT} | lz4 -dc - | tar -xf - -C $HOME/.story/story 2>/dev/null
  
  # Restore priv_validator_state.json
  if [ -f "$HOME/.story/story/priv_validator_state.json.backup" ]; then
    echo -e "${YELLOW}Restoring priv_validator_state.json...${NC}"
    mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json
  fi
  
  # Remove Geth data and extract snapshot
  echo -e "${YELLOW}Removing Geth data...${NC}"
  rm -rf $HOME/.story/geth/aeneid/geth/chaindata
  mkdir -p $HOME/.story/geth/aeneid/geth
  
  echo -e "${YELLOW}Downloading and extracting Geth snapshot...${NC}"
  curl -s ${SNAPSHOT_BASE_URL}${GETH_SNAPSHOT} | lz4 -dc - | tar -xf - -C $HOME/.story/geth/aeneid/geth 2>/dev/null
  
  # Restart services
  echo -e "${YELLOW}Enabling and restarting services...${NC}"
  sudo systemctl daemon-reload
  sudo systemctl enable $STORY_SERVICE $GETH_SERVICE
  sudo systemctl restart $GETH_SERVICE
  sleep 5
  sudo systemctl restart $STORY_SERVICE
  
  echo -e "${GREEN}Snapshots updated successfully!${NC}"
  echo -e "${YELLOW}To check logs:${NC} journalctl -u $STORY_SERVICE -u $GETH_SERVICE -f"
}

# Command processing
case "$1" in
  # Node management commands
  install)
    install_node "$2"
    ;;
  status)
    check_status
    ;;
  start)
    start_services
    ;;
  stop)
    stop_services
    ;;
  restart)
    restart_services
    ;;
  update)
    update_binaries
    ;;
  update-peers)
    update_peers
    ;;
  update-snapshots)
    update_snapshots
    ;;
  remove)
    remove_node
    ;;
  register)
    register_validator
    ;;
  export-key)
    export_validator_key
    ;;
    
  # Logging commands
  logs)
    show_logs
    ;;
  logs-geth)
    show_logs_geth
    ;;
  logs-story)
    show_logs_story
    ;;
    
  # Information commands
  sync)
    check_sync
    ;;
  info)
    show_info
    ;;
  peers)
    show_peers
    ;;
  metrics)
    show_metrics
    ;;
    
  # Key management commands
  backup-keys)
    backup_keys
    ;;
  restore-keys)
    restore_keys
    ;;
    
  # Help and default option
  help|*)
    show_help
    ;;
esac

exit 0 