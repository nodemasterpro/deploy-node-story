#!/bin/bash

# Utilitaires pour les validateurs Story Protocol - Testnet Aeneid
# Auteur: Nodes For All

# Définition des couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Chemins des services
GETH_SERVICE="story-geth"
STORY_SERVICE="story"

# Dossiers et chemins importants
BACKUP_DIR="/root/backup-keys-story"
VALIDATOR_KEY_PATH="$HOME/.story/story/config/priv_validator_key.json"
EVM_KEY_PATH="$HOME/.story/story/config/private_key.txt"
PRIV_VALIDATOR_STATE="$HOME/.story/story/data/priv_validator_state.json"

# Fonction d'aide
show_help() {
  echo -e "${BLUE}Utilitaires pour les validateurs Story Protocol - Testnet Aeneid${NC}"
  echo ""
  echo -e "Usage: $0 [command]"
  echo ""
  echo -e "Commands:"
  echo -e "  ${GREEN}backup_keys${NC}    - Sauvegarde les clés du validateur"
  echo -e "  ${GREEN}restore_keys${NC}   - Restaure les clés du validateur"
  echo -e "  ${GREEN}sync${NC}           - Vérifie l'état de synchronisation"
  echo -e "  ${GREEN}info${NC}           - Affiche les informations du nœud"
  echo -e "  ${GREEN}help${NC}           - Affiche cette aide"
  echo ""
}

# Fonction pour sauvegarder les clés du validateur
backup_keys() {
  echo -e "${BLUE}Sauvegarde des clés du validateur...${NC}"
  
  # Créer le répertoire de sauvegarde s'il n'existe pas
  mkdir -p $BACKUP_DIR
  
  # Vérifier l'existence des clés
  local files_to_backup=()
  
  if [ -f "$EVM_KEY_PATH" ]; then
    files_to_backup+=("$EVM_KEY_PATH")
    echo -e "${GREEN}Clé EVM trouvée: $EVM_KEY_PATH${NC}"
  else
    echo -e "${YELLOW}Clé EVM non trouvée: $EVM_KEY_PATH${NC}"
  fi
  
  if [ -f "$VALIDATOR_KEY_PATH" ]; then
    files_to_backup+=("$VALIDATOR_KEY_PATH")
    echo -e "${GREEN}Clé de validateur trouvée: $VALIDATOR_KEY_PATH${NC}"
  else
    echo -e "${YELLOW}Clé de validateur non trouvée: $VALIDATOR_KEY_PATH${NC}"
  fi
  
  if [ -f "$PRIV_VALIDATOR_STATE" ]; then
    files_to_backup+=("$PRIV_VALIDATOR_STATE")
    echo -e "${GREEN}État du validateur trouvé: $PRIV_VALIDATOR_STATE${NC}"
  else
    echo -e "${YELLOW}État du validateur non trouvé: $PRIV_VALIDATOR_STATE${NC}"
  fi
  
  # Si aucun fichier à sauvegarder
  if [ ${#files_to_backup[@]} -eq 0 ]; then
    echo -e "${RED}Aucun fichier à sauvegarder. Veuillez vérifier votre installation.${NC}"
    exit 1
  fi
  
  # Créer l'archive de sauvegarde
  tar -czf "$BACKUP_DIR/story_keys_backup.tar.gz" "${files_to_backup[@]}"
  
  echo -e "${GREEN}Sauvegarde créée à $BACKUP_DIR/story_keys_backup.tar.gz${NC}"
  echo -e "Cette sauvegarde contient:"
  
  if [[ " ${files_to_backup[*]} " =~ " $EVM_KEY_PATH " ]]; then
    echo -e "  - Clé privée EVM (de $EVM_KEY_PATH)"
  fi
  
  if [[ " ${files_to_backup[*]} " =~ " $VALIDATOR_KEY_PATH " ]]; then
    echo -e "  - Clé du validateur Tendermint (de $VALIDATOR_KEY_PATH)"
  fi
  
  if [[ " ${files_to_backup[*]} " =~ " $PRIV_VALIDATOR_STATE " ]]; then
    echo -e "  - État du validateur (de $PRIV_VALIDATOR_STATE)"
  fi
}

# Fonction pour restaurer les clés du validateur
restore_keys() {
  if [ ! -f "$BACKUP_DIR/story_keys_backup.tar.gz" ]; then
    echo -e "${RED}Erreur: Fichier de sauvegarde non trouvé à $BACKUP_DIR/story_keys_backup.tar.gz${NC}"
    exit 1
  fi
  
  echo -e "${BLUE}Restauration des clés du validateur...${NC}"
  
  # Arrêter les services
  echo -e "${YELLOW}Arrêt des services...${NC}"
  systemctl stop $STORY_SERVICE
  sleep 1
  
  # Extraire les clés
  echo -e "${YELLOW}Extraction des clés...${NC}"
  tar -xzf "$BACKUP_DIR/story_keys_backup.tar.gz" -C /
  
  # Vérifier les permissions
  echo -e "${YELLOW}Vérification des permissions...${NC}"
  if [ -f "$EVM_KEY_PATH" ]; then
    chmod 600 "$EVM_KEY_PATH"
  fi
  
  if [ -f "$VALIDATOR_KEY_PATH" ]; then
    chmod 600 "$VALIDATOR_KEY_PATH"
  fi
  
  if [ -f "$PRIV_VALIDATOR_STATE" ]; then
    chmod 600 "$PRIV_VALIDATOR_STATE"
  fi
  
  # Redémarrer les services
  echo -e "${YELLOW}Redémarrage des services...${NC}"
  systemctl start $STORY_SERVICE
  
  echo -e "${GREEN}Clés restaurées avec succès!${NC}"
}

# Fonction pour vérifier l'état de synchronisation
check_sync() {
  echo -e "${BLUE}Vérification de l'état de synchronisation...${NC}"
  
  echo -e "${YELLOW}Hauteur de bloc Geth:${NC}"
  local eth_block=$(curl -s localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
  
  if [ "$eth_block" == "null" ]; then
    echo -e "${RED}Erreur: Impossible de récupérer la hauteur de bloc Geth.${NC}"
  else
    # Convertir le bloc hexadécimal en décimal
    local eth_block_dec=$((16#${eth_block:2}))
    echo -e "${GREEN}Hauteur de bloc Geth: $eth_block_dec${NC}"
  fi
  
  echo -e "\n${YELLOW}État de synchronisation Story:${NC}"
  local sync_info=$(curl -s localhost:26657/status | jq '.result.sync_info')
  
  if [ -z "$sync_info" ]; then
    echo -e "${RED}Erreur: Impossible de récupérer l'état de synchronisation Story.${NC}"
    exit 1
  fi
  
  local latest_block_height=$(echo $sync_info | jq -r '.latest_block_height')
  local catching_up=$(echo $sync_info | jq -r '.catching_up')
  
  echo -e "${GREEN}Hauteur de bloc Story: $latest_block_height${NC}"
  
  if [ "$catching_up" == "true" ]; then
    echo -e "${YELLOW}Status: En cours de synchronisation (catching_up: true)${NC}"
  else
    echo -e "${GREEN}Status: Synchronisé (catching_up: false)${NC}"
  fi
}

# Fonction pour afficher les informations du nœud
show_info() {
  echo -e "${BLUE}Récupération des informations du nœud...${NC}"
  
  local node_info=$(curl -s localhost:26657/status | jq '.result.node_info')
  local sync_info=$(curl -s localhost:26657/status | jq '.result.sync_info')
  
  if [ -z "$node_info" ] || [ -z "$sync_info" ]; then
    echo -e "${RED}Erreur: Impossible de récupérer les informations du nœud.${NC}"
    exit 1
  fi
  
  local node_id=$(echo $node_info | jq -r '.id')
  local moniker=$(echo $node_info | jq -r '.moniker')
  local network=$(echo $node_info | jq -r '.network')
  local latest_block_height=$(echo $sync_info | jq -r '.latest_block_height')
  local catching_up=$(echo $sync_info | jq -r '.catching_up')
  
  echo -e "${GREEN}Informations du nœud:${NC}"
  echo -e "Node ID: $node_id"
  echo -e "Moniker: $moniker"
  echo -e "Network: $network"
  echo -e "Hauteur de bloc: $latest_block_height"
  echo -e "En cours de synchronisation: $catching_up"
  
  # Vérifier l'état du validateur
  local validator_status=$(curl -s localhost:26657/status | jq -r '.result.validator_info')
  
  echo -e "\n${GREEN}Informations du validateur:${NC}"
  if [ "$validator_status" == "null" ]; then
    echo -e "${YELLOW}Ce nœud n'est pas un validateur actif.${NC}"
  else
    echo $validator_status | jq
  fi
  
  # Récupérer l'adresse du validateur
  if [ -x "$(command -v $HOME/go/bin/story)" ]; then
    local validator_address=$($HOME/go/bin/story validator address)
    echo -e "\n${GREEN}Adresse du validateur: $validator_address${NC}"
  fi
}

# Traitement des commandes
case "$1" in
  backup_keys)
    backup_keys
    ;;
  restore_keys)
    restore_keys
    ;;
  sync)
    check_sync
    ;;
  info)
    show_info
    ;;
  help|*)
    show_help
    ;;
esac

exit 0
