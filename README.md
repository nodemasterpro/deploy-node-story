# Story Protocol Node Deployment
This repository contains Ansible scripts for the installation, updating, and removal of Story Protocol validator nodes on Linux systems. The playbooks are designed to simplify the process of setting up Story nodes, managing their services, and ensuring seamless node operations.

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
Install Git:

```
sudo apt install git -y
```
Install Ansible:

```
sudo apt remove ansible -y
sudo apt-get install -y software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
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
## Step 3: Installing the Story Validator Node
Execute the playbook using the following command, specifying the moniker (node name) as an extra variable:

```
ansible-playbook install_story_nodes.yml -e moniker="your_node_name"
```
Note: Replace "your_node_name" with the unique name you wish to assign to your node. Installation takes about 45 minutes due to downloading and importing the snapshot.

Once completed, you can find your private key in /root/.story/story/config/private_key.txt. Save it securely, as it will be useful for the next steps.

## Step 4: Starting Node Services and Viewing Logs
Start the Geth and Consensus nodes and monitor their logs:

Geth Node:

```
sudo systemctl start story-geth-node && journalctl -u story-geth-node -f -o cat
```
To exit the logs, type Ctrl+C.

Consensus Node:
```
sudo systemctl start story-consensus-node && journalctl -u story-consensus-node -f -o cat
```
To exit the logs, type Ctrl+C.

Regularly check these logs to ensure everything is running smoothly.

## Step 5: Setting up your Metamask Story Node Wallet
To register your node as a validator, you need to fund it by obtaining tokens from a faucet using your node’s public address. To obtain this public address, import your node’s private key into a MetaMask wallet. As a reminder, the private key is present in “/root/.story/story/config/private_key.txt”. Add the testnet Story network to this wallet. If you don’t have it, you can add it automatically from the chainlist website.


## Step 6:Requesting Story Testnet Funds
You need 0.5 IP for registering your node as a validator. Get funds for your wallet through faucetme by logging in with your discord and joining their discord. Then, enter the public address of your node’s metamask wallet. You will get 2 IP. You can only make one request every 24 hours.

## Step 6: Node Synchronization Verification
Ensure your node is fully synchronized with the Story blockchain:
```
curl -s localhost:26657/status | jq '.result.sync_info'
```
Wait until the catching_up variable is false. Once catching_up is false, your node is fully synchronized and ready for further operations.

## Step 7: Registering the Node as a Validator
To accomplish this step, your node must be synchronized with the blockchain and you must hold 0.5 IP (plus gas fees) in your node address for staking:

```
ansible-playbook register_story_validator_node.yml
```
During this process, you will be prompted to enter:

moniker: The name of your node.
At the end of the script, you will obtain the public address of your node.

After successfully creating your validator, you can view it on the Story explorer. Simply enter the public address of your node, which was provided to you at the end of the node registration script.

Congratulations! Your Story validator node is operational.

Additional Information
Stopping Services
To stop the Story Geth node and Story Consensus node:

```
sudo systemctl stop story-geth-node && sudo systemctl stop story-consensus-node
```
Starting Services
To start the Story Geth node and Story Consensus node:

```
sudo systemctl start story-geth-node && sudo systemctl start story-consensus-node
```
Removing the Story Nodes
To remove the Story nodes, run this playbook:

```
ansible-playbook remove_story_nodes.yml
```
Ensure to back up all important data before deleting the Story node, as this action may remove node data.

By following this guide, you have successfully deployed and managed a Story validator node, contributing to the robustness of the network and potentially earning rewards. Join the Story community on Discord and Twitter to stay informed about the project.

Thank you for taking the time to read this guide! If you have any questions or would like to continue the conversation, feel free to join the Story Discord server. Stay updated and connected: Follow us on Twitter, join our Telegram group, Discord server, and subscribe to our YouTube channel.