#!/bin/bash

# Script de gestion pour les nœuds Story Protocol - Testnet Aeneid
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

# Chemin des journaux
GETH_LOG="/tmp/story_geth.log"
STORY_LOG="/tmp/story_consensus.log"

# Dossiers et chemins importants
BACKUP_DIR="/root/backup-keys-story"
SNAPSHOT_DIR="/root/snapshots"
VALIDATOR_KEY_PATH="$HOME/.story/story/config/priv_validator_key.json"
EVM_KEY_PATH="$HOME/.story/story/config/private_key.txt"
STORY_DATA_DIR="$HOME/.story/story/data"
GETH_DATA_DIR="$HOME/.story/geth"

# Fonction d'aide
show_help() {
  echo -e "${BLUE}Script de gestion des nœuds Story Protocol - Testnet Aeneid${NC}"
  echo ""
  echo -e "Usage: $0 [command]"
  echo ""
  echo -e "Commands:"
  echo -e "  ${GREEN}install <moniker>${NC} - Installe un nouveau nœud Story avec le moniker spécifié"
  echo -e "  ${GREEN}status${NC}         - Affiche l'état des services"
  echo -e "  ${GREEN}start${NC}          - Démarre les services"
  echo -e "  ${GREEN}stop${NC}           - Arrête les services"
  echo -e "  ${GREEN}restart${NC}        - Redémarre les services"
  echo -e "  ${GREEN}logs${NC}           - Affiche les journaux des services"
  echo -e "  ${GREEN}logs-geth${NC}      - Affiche les journaux du service Geth"
  echo -e "  ${GREEN}logs-story${NC}     - Affiche les journaux du service Story"
  echo -e "  ${GREEN}sync${NC}           - Affiche l'état de synchronisation"
  echo -e "  ${GREEN}info${NC}           - Affiche les informations du nœud"
  echo -e "  ${GREEN}peers${NC}          - Affiche les pairs connectés"
  echo -e "  ${GREEN}metrics${NC}        - Affiche les métriques du nœud"
  echo -e "  ${GREEN}update${NC}         - Met à jour les binaires"
  echo -e "  ${GREEN}register${NC}       - Enregistre le nœud comme validateur"
  echo -e "  ${GREEN}remove${NC}         - Supprime le nœud Story"
  echo -e "  ${GREEN}backup-keys${NC}    - Sauvegarde les clés du validateur"
  echo -e "  ${GREEN}restore-keys${NC}   - Restaure les clés du validateur"
  echo -e "  ${GREEN}download-snapshot${NC} <type> - Télécharge un snapshot (pruned/archive)"
  echo -e "  ${GREEN}import-snapshot${NC} <type>   - Importe un snapshot (pruned/archive)"
  echo -e "  ${GREEN}help${NC}           - Affiche cette aide"
  echo ""
}

# Fonction pour vérifier l'état des services
check_status() {
  echo -e "${BLUE}Vérification de l'état des services...${NC}"
  
  if systemctl is-active --quiet $GETH_SERVICE; then
    echo -e "${GREEN}$GETH_SERVICE est actif.${NC}"
  else
    echo -e "${RED}$GETH_SERVICE est inactif.${NC}"
  fi
  
  if systemctl is-active --quiet $STORY_SERVICE; then
    echo -e "${GREEN}$STORY_SERVICE est actif.${NC}"
  else
    echo -e "${RED}$STORY_SERVICE est inactif.${NC}"
  fi
}

# Fonction pour démarrer les services
start_services() {
  echo -e "${BLUE}Démarrage des services...${NC}"
  systemctl start $GETH_SERVICE
  sleep 2
  systemctl start $STORY_SERVICE
  sleep 1
  check_status
}

# Fonction pour arrêter les services
stop_services() {
  echo -e "${BLUE}Arrêt des services...${NC}"
  systemctl stop $STORY_SERVICE
  sleep 1
  systemctl stop $GETH_SERVICE
  sleep 1
  check_status
}

# Fonction pour redémarrer les services
restart_services() {
  echo -e "${BLUE}Redémarrage des services...${NC}"
  stop_services
  sleep 2
  start_services
}

# Fonction pour afficher les journaux
show_logs() {
  echo -e "${BLUE}Récupération des journaux...${NC}"
  
  echo -e "${YELLOW}Journaux de $GETH_SERVICE:${NC}"
  journalctl -u $GETH_SERVICE -n 50 --no-pager
  
  echo -e "\n${YELLOW}Journaux de $STORY_SERVICE:${NC}"
  journalctl -u $STORY_SERVICE -n 50 --no-pager
}

# Fonction pour afficher les journaux de Geth
show_logs_geth() {
  echo -e "${YELLOW}Journaux de $GETH_SERVICE:${NC}"
  journalctl -u $GETH_SERVICE -f -o cat
}

# Fonction pour afficher les journaux de Story
show_logs_story() {
  echo -e "${YELLOW}Journaux de $STORY_SERVICE:${NC}"
  journalctl -u $STORY_SERVICE -f -o cat
}

# Fonction pour vérifier l'état de synchronisation
check_sync() {
  echo -e "${BLUE}Vérification de l'état de synchronisation...${NC}"
  
  echo -e "${YELLOW}Statut de synchronisation Geth:${NC}"
  curl -s localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' | jq
  
  echo -e "\n${YELLOW}Statut de synchronisation Story:${NC}"
  curl -s localhost:26657/status | jq '.result.sync_info'
}

# Fonction pour afficher les informations du nœud
show_info() {
  echo -e "${BLUE}Récupération des informations du nœud...${NC}"
  
  echo -e "${YELLOW}Informations du nœud Geth:${NC}"
  curl -s localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' | jq
  
  echo -e "\n${YELLOW}Informations du nœud Story:${NC}"
  curl -s localhost:26657/status | jq '.result.node_info'
  
  echo -e "\n${YELLOW}Statut de rattrapage:${NC}"
  curl -s localhost:26657/status | jq '.result.sync_info.catching_up'
}

# Fonction pour afficher les pairs connectés
show_peers() {
  echo -e "${BLUE}Récupération des pairs connectés...${NC}"
  
  echo -e "${YELLOW}Nombre de pairs Geth:${NC}"
  curl -s localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' | jq
  
  echo -e "\n${YELLOW}Pairs Story:${NC}"
  curl -s localhost:26657/net_info | jq '.result.peers | length'
  curl -s localhost:26657/net_info | jq '.result.peers[] | {node_id: .node_info.id, addr: .remote_ip, moniker: .node_info.moniker}'
}

# Fonction pour afficher les métriques
show_metrics() {
  echo -e "${BLUE}Récupération des métriques...${NC}"
  
  echo -e "${YELLOW}Métriques de base Geth:${NC}"
  curl -s localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq
  
  echo -e "\n${YELLOW}Métriques Story:${NC}"
  curl -s localhost:26657/consensus_state | jq '.result.round_state.height_vote_set[0].prevotes_bit_array'
}

# Fonction pour mettre à jour les binaires
update_binaries() {
  echo -e "${BLUE}Mise à jour des binaires...${NC}"
  
  # Variables des versions
STORY_GETH_VERSION="v1.1.0"
STORY_VERSION="v1.3.0"
  
  # Arrêt des services
  stop_services
  
  # Mise à jour de Geth
  echo -e "${YELLOW}Mise à jour de Geth vers $STORY_GETH_VERSION...${NC}"
  cd $HOME
  rm -rf story-geth
  git clone https://github.com/piplabs/story-geth.git
  cd story-geth
  git checkout $STORY_GETH_VERSION
  make geth
  mv build/bin/geth $HOME/go/bin/
  
  # Mise à jour de Story
  echo -e "${YELLOW}Mise à jour de Story vers $STORY_VERSION...${NC}"
  cd $HOME
  rm -rf story
  git clone https://github.com/piplabs/story
  cd story
  git checkout $STORY_VERSION
  go build -o story ./client
  mv story $HOME/go/bin/
  
  # Redémarrage des services
  start_services
  
  echo -e "${GREEN}Mise à jour terminée!${NC}"
}

# Fonction pour installer un nouveau nœud
install_node() {
  if [ -z "$1" ]; then
    echo -e "${RED}Erreur: Moniker est requis pour l'installation.${NC}"
    show_help
    exit 1
  fi
  
  echo -e "${BLUE}Installation d'un nœud Story avec le moniker: $1${NC}"
  ansible-playbook install_story_nodes.yml -e "moniker=$1"
}

# Fonction pour enregistrer un nœud comme validateur
register_validator() {
  echo -e "${BLUE}Enregistrement du nœud comme validateur...${NC}"
  
  # Vérifier que le nœud est synchronisé
  CATCHING_UP=$(curl -s localhost:26657/status | jq -r '.result.sync_info.catching_up')
  
  if [ "$CATCHING_UP" == "true" ]; then
    echo -e "${RED}Erreur: Le nœud n'est pas encore synchronisé. Veuillez attendre la fin de la synchronisation.${NC}"
    echo -e "Vous pouvez vérifier l'état de synchronisation avec: $0 sync"
    exit 1
  fi
  
  # Vérifier l'existence de la clé privée
  if [ ! -f "$EVM_KEY_PATH" ]; then
    echo -e "${RED}Erreur: Clé EVM non trouvée à $EVM_KEY_PATH${NC}"
    exit 1
  fi
  
  # Demander au validateur d'exporter sa clé EVM
  echo -e "${YELLOW}Exportation de la clé EVM...${NC}"
  $HOME/go/bin/story validator export --export-evm-key

  # Informations sur le financement du nœud
  echo -e "${GREEN}Pour enregistrer votre nœud comme validateur, veuillez suivre ces étapes:${NC}"
  echo -e "1. Importez votre clé privée EVM (située à $EVM_KEY_PATH) dans votre portefeuille MetaMask."
  echo -e "2. Ajoutez le réseau testnet Story à MetaMask (via Chainlist)."
  echo -e "3. Obtenez des tokens IP via le faucet Story (vous avez besoin d'au moins 0.5 IP)."
  echo -e "4. Utilisez le CLI Story pour créer votre validateur:"
  echo -e "   $HOME/go/bin/story validator create --moniker <votre_moniker> --amount 0.5"
  
  # Vérifier l'adresse du validateur
  VALIDATOR_ADDRESS=$($HOME/go/bin/story validator address)
  echo -e "${GREEN}Adresse de votre validateur: ${VALIDATOR_ADDRESS}${NC}"
  echo -e "Vous pouvez vérifier votre validateur sur l'explorateur Story en recherchant cette adresse."
}

# Fonction pour supprimer le nœud
remove_node() {
  read -p "Êtes-vous sûr de vouloir supprimer le nœud Story? Cette action est irréversible. (o/N) " confirm
  if [[ $confirm == [oO] || $confirm == [oO][uU][iI] ]]; then
    echo -e "${BLUE}Suppression du nœud Story...${NC}"
    ansible-playbook remove_story_nodes.yml
  else
    echo -e "${YELLOW}Suppression annulée.${NC}"
  fi
}

# Fonction pour sauvegarder les clés du validateur
backup_keys() {
  echo -e "${BLUE}Sauvegarde des clés du validateur...${NC}"
  
  # Créer le répertoire de sauvegarde s'il n'existe pas
  mkdir -p $BACKUP_DIR
  
  # Créer l'archive de sauvegarde
  tar -czf "$BACKUP_DIR/story_keys_backup.tar.gz" -C $(dirname $EVM_KEY_PATH) $(basename $EVM_KEY_PATH) -C $(dirname $VALIDATOR_KEY_PATH) $(basename $VALIDATOR_KEY_PATH)
  
  echo -e "${GREEN}Sauvegarde créée à $BACKUP_DIR/story_keys_backup.tar.gz${NC}"
  echo -e "Cette sauvegarde contient:"
  echo -e "  - Clé privée EVM (de $EVM_KEY_PATH)"
  echo -e "  - Clé du validateur Tendermint (de $VALIDATOR_KEY_PATH)"
}

# Fonction pour restaurer les clés du validateur
restore_keys() {
  if [ ! -f "$BACKUP_DIR/story_keys_backup.tar.gz" ]; then
    echo -e "${RED}Erreur: Fichier de sauvegarde non trouvé à $BACKUP_DIR/story_keys_backup.tar.gz${NC}"
    exit 1
  fi
  
  echo -e "${BLUE}Restauration des clés du validateur...${NC}"
  
  # Arrêter les services
  stop_services
  
  # Extraire les clés
  mkdir -p $(dirname $EVM_KEY_PATH)
  mkdir -p $(dirname $VALIDATOR_KEY_PATH)
  tar -xzf "$BACKUP_DIR/story_keys_backup.tar.gz" -C $(dirname $EVM_KEY_PATH)
  
  # Redémarrer les services
  start_services
  
  echo -e "${GREEN}Clés restaurées avec succès!${NC}"
}

# Fonction pour télécharger un snapshot
download_snapshot() {
  if [ -z "$1" ]; then
    echo -e "${RED}Erreur: Type de snapshot non spécifié (pruned/archive)${NC}"
    show_help
    exit 1
  fi
  
  # Vérifier le type de snapshot
  if [ "$1" != "pruned" ] && [ "$1" != "archive" ]; then
    echo -e "${RED}Erreur: Type de snapshot invalide. Utilisez 'pruned' ou 'archive'${NC}"
    exit 1
  fi
  
  echo -e "${BLUE}Téléchargement du snapshot $1...${NC}"
  
  # Créer le répertoire de snapshot s'il n'existe pas
  mkdir -p $SNAPSHOT_DIR
  
  # URL des snapshots (exemple, à adapter selon les sources réelles)
  SNAPSHOT_BASE_URL="https://snapshots.validors.site/story"
  
  # Télécharger les snapshots Geth et Story
  echo -e "${YELLOW}Téléchargement du snapshot Geth...${NC}"
  aria2c -x 16 -s 16 "$SNAPSHOT_BASE_URL/geth_$1_latest.tar.lz4" -d $SNAPSHOT_DIR
  
  echo -e "${YELLOW}Téléchargement du snapshot Story...${NC}"
  aria2c -x 16 -s 16 "$SNAPSHOT_BASE_URL/story_$1_latest.tar.lz4" -d $SNAPSHOT_DIR
  
  echo -e "${GREEN}Snapshots téléchargés dans $SNAPSHOT_DIR${NC}"
}

# Fonction pour importer un snapshot
import_snapshot() {
  if [ -z "$1" ]; then
    echo -e "${RED}Erreur: Type de snapshot non spécifié (pruned/archive)${NC}"
    show_help
    exit 1
  fi
  
  # Vérifier le type de snapshot
  if [ "$1" != "pruned" ] && [ "$1" != "archive" ]; then
    echo -e "${RED}Erreur: Type de snapshot invalide. Utilisez 'pruned' ou 'archive'${NC}"
    exit 1
  fi
  
  # Vérifier l'existence des fichiers de snapshot
  if [ ! -f "$SNAPSHOT_DIR/geth_$1_latest.tar.lz4" ] || [ ! -f "$SNAPSHOT_DIR/story_$1_latest.tar.lz4" ]; then
    echo -e "${RED}Erreur: Snapshots non trouvés dans $SNAPSHOT_DIR${NC}"
    echo -e "Veuillez d'abord télécharger les snapshots avec: $0 download-snapshot $1"
    exit 1
  }
  
  echo -e "${BLUE}Importation du snapshot $1...${NC}"
  
  # Arrêter les services
  stop_services
  
  # Sauvegarder les clés
  echo -e "${YELLOW}Sauvegarde des clés...${NC}"
  backup_keys
  
  # Supprimer les anciennes données
  echo -e "${YELLOW}Suppression des anciennes données...${NC}"
  rm -rf $STORY_DATA_DIR
  rm -rf $GETH_DATA_DIR/aeneid/geth/chaindata
  
  # Importer les snapshots
  echo -e "${YELLOW}Importation du snapshot Story...${NC}"
  lz4 -cd "$SNAPSHOT_DIR/story_$1_latest.tar.lz4" | tar -xf - -C $(dirname $STORY_DATA_DIR)
  
  echo -e "${YELLOW}Importation du snapshot Geth...${NC}"
  lz4 -cd "$SNAPSHOT_DIR/geth_$1_latest.tar.lz4" | tar -xf - -C $GETH_DATA_DIR/aeneid/geth
  
  # Restaurer les clés
  echo -e "${YELLOW}Restauration des clés...${NC}"
  restore_keys
  
  # Démarrer les services
  start_services
  
  echo -e "${GREEN}Snapshots importés avec succès!${NC}"
}

# Traitement des commandes
case "$1" in
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
  logs)
    show_logs
    ;;
  logs-geth)
    show_logs_geth
    ;;
  logs-story)
    show_logs_story
    ;;
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
  update)
    update_binaries
    ;;
  install)
    install_node "$2"
    ;;
  register)
    register_validator
    ;;
  remove)
    remove_node
    ;;
  backup-keys)
    backup_keys
    ;;
  restore-keys)
    restore_keys
    ;;
  download-snapshot)
    download_snapshot "$2"
    ;;
  import-snapshot)
    import_snapshot "$2"
    ;;
  help|*)
    show_help
    ;;
esac

exit 0
