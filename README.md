# Story Protocol Node Deployment
This repository contains Ansible and Bash scripts for the installation, updating, management, and removal of Story Protocol validator nodes on Linux systems. The playbooks and scripts are designed to simplify the process of setting up Story nodes, managing their services, and ensuring seamless node operations.

## Prerequisites
Recommended specifications for a server:

Operating System: Ubuntu 22.04
CPU: 4 cores
RAM: 8 GB
Storage: 200 GB SSD
Open TCP Ports: 26666, 26667, and 30303 must be open and accessible.
For hosting a Story node, you can opt for a VPS 2 server. Contabo is a reliable choice to meet the technical requirements of Story Protocol.

## Getting Started
## Step 1: Installing Dependencies
Update your system's package list and install necessary tools:

```
sudo apt update && sudo apt upgrade -y
```
Install Git and Ansible:

```
sudo apt install git ansible -y
```
Check your Ansible version:

```
ansible --version
```
You must have Ansible version 2.15 or higher.

## Step 2: Downloading the Project
Clone this repository to access the Ansible playbook and all necessary files:

```
git clone https://github.com/nodemasterpro/deploy-node-story.git
cd deploy-node-story
```
## Step 3: Using the Story Node Manager
After cloning the repository, you can use the Story Node Manager script for various operations:

1. To install a new Story node:
   ```
   ./story_node_manager.sh install your_node_name
   ```

2. To update an existing Story node:
   ```
   ./story_node_manager.sh update
   ```

3. To view the status of your Story node:
   ```
   ./story_node_manager.sh status
   ```

4. To stop the Story node services:
   ```
   ./story_node_manager.sh stop
   ```

5. To start the Story node services:
   ```
   ./story_node_manager.sh start
   ```

6. To remove the Story node:
   ```
   ./story_node_manager.sh remove
   ```

7. To register the node as a validator:
   ```
   ./story_node_manager.sh register
   ```
   This command will run the registration process for your node to become a validator.

8. To view the logs of the consensus node:
   ```
   ./story_node_manager.sh logs-consensus
   ```

9. To view the logs of the geth node:
   ```
   ./story_node_manager.sh logs-geth
   ```

Note: Replace "your_node_name" with the unique name you wish to assign to your node. Installation takes about 45 minutes due to downloading and importing the snapshot.

Once completed, you can find your private key in /root/.story/story/config/private_key.txt. Save it securely, as it will be useful for the next steps.

## Step 4: Node Synchronization Verification
Ensure your node is fully synchronized with the Story blockchain:

```
./validator_utils.sh sync
```
Wait until the catching_up variable is false. Once catching_up is false, your node is fully synchronized and ready for further operations.

## Step 5: Setting up your Metamask Story Node Wallet
To register your node as a validator, you need to fund it by obtaining tokens from a faucet using your node's public address. To obtain this public address, import your node's private key into a MetaMask wallet. As a reminder, the private key is present in “/root/.story/story/config/private_key.txt”. Add the testnet Story network to this wallet. If you don’t have it, you can add it automatically from the chainlist website.


## Step 6:Requesting Story Testnet Funds
You need 0.5 IP for registering your node as a validator. Get funds for your wallet through faucetme by logging in with your discord and joining their discord. Then, enter the public address of your node’s metamask wallet. You will get 2 IP. You can only make one request every 24 hours.

## Step 7: Registering the Node as a Validator
To accomplish this step, your node must be synchronized with the blockchain and you must hold 0.5 IP (plus gas fees) in your node address for staking:

```
./story_node_manager.sh register
```
During this process, you will be prompted to enter:

moniker: The name of your node.
At the end of the script, you will obtain the public address of your node.

After successfully creating your validator, you can view it on the Story explorer. Simply enter the public address of your node, which was provided to you at the end of the node registration script.

Congratulations! Your Story validator node is operational.

## Additional Information

### Validator Utilities

The `validator_utils.sh` script provides additional functionality to manage your validator node:

1. To backup validator keys:
   ```
   ./validator_utils.sh backup_keys
   ```

2. To restore validator keys:
   ```
   ./validator_utils.sh restore_keys
   ```

3. To check synchronization status:
   ```
   ./validator_utils.sh sync
   ```

4. To view validator information:
   ```
   ./validator_utils.sh info
   ```

5. To display help information:
   ```
   ./validator_utils.sh help
   ```

### Backup and Restore

Ensure to back up all important data before deleting the Story node, as this action may remove node data.

By following this guide, you have successfully deployed and managed a Story validator node, contributing to the robustness of the network and potentially earning rewards. Join the Story community on Discord and Twitter to stay informed about the project.

Thank you for taking the time to read this guide! If you have any questions or would like to continue the conversation, feel free to join the Story Discord server. Stay updated and connected: Follow us on Twitter, join our Telegram group, Discord server, and subscribe to our YouTube channel.

### Creating data.json for Story Validators Race

To participate in the Story Validators Race, you need to create a data.json file and submit it via a pull request. You can use the `create_data_json.yml` playbook to automate this process:

```
ansible-playbook create_data_json.yml
```
This playbook will:
1. Create the data.json file with your validator information
2. Fork the Story Validators Race repository
3. Commit and push the changes to your forked repository
4. Provide instructions for creating a pull request

Follow the instructions provided by the playbook to complete the submission process.

### Snapshot Management

The `snapshot_manager.sh` script provides functionality to manage Story node snapshots:

1. To download a snapshot:
   ```
   ./snapshot_manager.sh download <type>
   ```

2. To import a snapshot:
   ```
   ./snapshot_manager.sh import <type>
   ```

Where `<type>` can be either 'pruned' or 'archive'.

These commands allow you to quickly synchronize your node using the latest available snapshot, which is much faster than syncing from scratch.

### Submitting MD Files for Story Validators Race

In addition to the data.json file, you need to submit several MD files detailing your validator setup and tasks completed. These files are:

- submission-general-task-1.md
- submission-general-task-2.md
- submission-general-task-3.md
- submission-general-task-4.md
- submission-bonus-task-1.md
- submission-bonus-task-2.md
- submission-bonus-task-3.md

These files should be placed in the same directory as your data.json file. The `create_data_json.yml` playbook has been updated to automatically copy these files from your local `deploy-node-story` directory to your forked repository.

To ensure your MD files are included in your submission:

1. Create and edit the MD files in your local `deploy-node-story` directory.
2. Run the `create_data_json.yml` playbook as described above.
3. The playbook will copy your MD files to the correct location in your forked repository.
4. Follow the instructions provided by the playbook to create a pull request.

Your pull request will now include both your data.json file and all the required MD files for the Story Validators Race.
