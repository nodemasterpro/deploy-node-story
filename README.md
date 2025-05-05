# Story Protocol - Node Deployment for Aeneid Testnet

This repository contains Ansible and Bash scripts for installing, updating, managing, and removing Story Protocol validator nodes on Linux systems. The playbooks and scripts are designed to simplify the process of configuring Story nodes, managing their services, and ensuring proper node functioning.

## System Requirements

### Hardware Requirements
For optimal performance and reliability, we recommend running your node on either:
- A Virtual Private Server (VPS)
- A dedicated Linux-based machine

Recommended specifications for a server:

| Hardware | Minimal Requirement |
|----------|---------------------|
| CPU | Dedicated 8 Cores |
| RAM | 32 GB |
| Disk | 500 GB NVMe Drive |
| Bandwidth | 25 MBit/s |

### Software Requirements
- Operating System: Ubuntu 22.04 LTS
- Root or sudo access

### Required Ports
Ensure the following ports are open and accessible:

**story-geth**:
- 8545: Required for JSON-RPC API over HTTP
- 8546: Required for WebSockets interaction
- 30303 (TCP + UDP): MUST be open for P2P communication

**story**:
- 26656: MUST be open for consensus P2P communication
- 26657: Required for Tendermint RPC
- 26660: Needed for Prometheus metrics exposure

## Quick Start
### Step 1: Install Dependencies
Update your system's package list and install necessary tools:

```bash
sudo apt update && sudo apt upgrade -y
```

Install Git:

```bash
sudo apt install git -y
```

### Step 2: Download the Project
Clone this repository to access the Story node management script:

```bash
git clone https://github.com/your-name/deploy-node-story.git
cd deploy-node-story
```

### Step 3: Using the Story Node Manager
After cloning the repository, you can use the unified Story script for various operations:

1. To install a node with a specified moniker:
   ```bash
   ./story.sh install your_node_name
   ```

2. To check the status of services:
   ```bash
   ./story.sh status
   ```

3. To start the services:
   ```bash
   ./story.sh start
   ```

4. To stop the services:
   ```bash
   ./story.sh stop
   ```

5. To restart the services:
   ```bash
   ./story.sh restart
   ```

6. To view the logs:
   ```bash
   ./story.sh logs
   ```

7. To check the synchronization status:
   ```bash
   ./story.sh sync
   ```

8. To display node information:
   ```bash
   ./story.sh info
   ```

9. To show connected peers:
   ```bash
   ./story.sh peers
   ```

10. To display node metrics:
    ```bash
    ./story.sh metrics
    ```

11. To update the binaries:
    ```bash
    ./story.sh update
    ```

12. To register as a validator:
    ```bash
    ./story.sh register
    ```

Note: Installation takes approximately 30-45 minutes depending on your internet connection and server performance.

## Detailed Installation

### Installation Process
The installation process includes:
- Installing Go 1.22.5
- Setting up environment variables
- Downloading and building Story and Story-Geth binaries
- Configuring services
- Automatically downloading and importing the latest snapshots

```bash
./story.sh install your_node_name
```

Replace "your_node_name" with the unique name you want to assign to your node.

### Customizable Variables
You can customize the following variables by setting them as environment variables before running the install command:

- `MONIKER`: Your node name (default: value provided in the command)
- `STORY_CHAIN_ID`: Chain ID (default: "aeneid")
- `STORY_PORT`: Base port (default: "52")

Example:
```bash
export STORY_PORT=62
./story.sh install my_validator
```

## Project Structure
- `install_story_nodes.yml`: Main playbook for node installation
- `update_story_nodes.yml`: Playbook for node updates
- `story.sh`: Unified script for all node management operations
- `templates/`: Contains configuration files for systemd services

## Information about Aeneid Testnet
The Aeneid testnet is the latest version of the Story Protocol test network. It uses:

- Story v1.2.0
- Story-Geth v1.0.2

Story Protocol draws inspiration from ETH PoS by decoupling execution and consensus clients:
- The execution client (story-geth) relays EVM blocks into the Story consensus client via Engine API
- It uses an ABCI++ adapter to make EVM state compatible with CometBFT
- With this architecture, consensus efficiency is no longer bottlenecked by execution transaction throughput

For more information, see:
- Official documentation: https://docs.story.foundation/network/operating-a-node/node-setup-mainnet
- ITRocket guide: https://itrocket.net/services/testnet/story/installation/

## Troubleshooting
If you encounter problems:

1. Check the logs: `./story.sh logs`
2. Check the synchronization status: `./story.sh sync`
3. Ensure all necessary ports are open
4. Restart the services: `./story.sh restart`

If problems persist, you can reinstall the node or update the binaries.

## Additional Information

### Validator Registration
After your node is fully synced, you can register as a validator:

```bash
./story.sh register
```

This will:
1. Export your validator and EVM keys
2. Guide you through adding tokens to your wallet
3. Create your validator with the appropriate parameters
4. Backup your keys automatically

Remember to save your validator private key:
```bash
cat $HOME/.story/story/config/priv_validator_key.json
```

### Key Management

1. To backup validator keys:
   ```
   ./story.sh backup-keys
   ```

2. To restore validator keys:
   ```
   ./story.sh restore-keys
   ```

### Backup and Restore
Ensure to back up all important data before deleting the Story node, as this action may remove node data.

By following this guide, you have successfully deployed and managed a Story validator node, contributing to the robustness of the network and potentially earning rewards. Join the Story community on Discord and Twitter to stay informed about the project.
