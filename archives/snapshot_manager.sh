#!/bin/bash

# Script de gestion des snapshots pour Story Protocol - Testnet Aeneid
# Auteur: Nodes For All

# Définition des couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Répertoire pour les snapshots
SNAPSHOT_DIR="/root/snapshots"
mkdir -p $SNAPSHOT_DIR

# URL de base pour les snapshots
SNAPSHOT_BASE_URL="https://snapshots.validors.site/story"

# Dossiers de données
STORY_DATA_DIR="$HOME/.story/story/data"
GETH_DATA_DIR="$HOME/.story/geth"

# Chemins des services
GETH_SERVICE="story-geth"
STORY_SERVICE="story"

# Chemins des clés
VALIDATOR_KEY_PATH="$HOME/.story/story/config/priv_validator_key.json"
EVM_KEY_PATH="$HOME/.story/story/config/private_key.txt"

# Répertoire pour les sauvegardes
BACKUP_DIR="/root/backup-keys-story"
mkdir -p $BACKUP_DIR

# Fonction d'aide
show_help() {
  echo -e "${BLUE}Script de gestion des snapshots pour Story Protocol - Testnet Aeneid${NC}"
  echo ""
  echo -e "Usage: $0 {command} {type}"
  echo ""
  echo -e "Commands:"
  echo -e "  ${GREEN}download${NC} <type>  - Télécharge un snapshot (pruned/archive)"
  echo -e "  ${GREEN}import${NC} <type>    - Importe un snapshot (pruned/archive)"
  echo -e "  ${GREEN}help${NC}            - Affiche cette aide"
  echo ""
  echo -e "Types:"
  echo -e "  ${GREEN}pruned${NC}  - Version allégée du snapshot (recommandé)"
  echo -e "  ${GREEN}archive${NC} - Version complète avec tout l'historique (plus volumineux)"
  echo ""
}

# Fonction pour vérifier les dépendances
check_dependencies() {
  local missing_deps=()
  
  # Liste des dépendances
  local deps=("aria2c" "lz4" "jq" "tar")
  
  # Vérifier chaque dépendance
  for dep in "${deps[@]}"; do
    if ! command -v $dep &> /dev/null; then
      missing_deps+=($dep)
    fi
  done
  
  # Installer les dépendances manquantes
  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installation des dépendances manquantes: ${missing_deps[*]}${NC}"
    apt update
    apt install -y aria2 liblz4-tool jq tar
  fi
}

# Fonction pour arrêter les services
stop_services() {
  echo -e "${BLUE}Arrêt des services...${NC}"
  systemctl stop $STORY_SERVICE
  sleep 1
  systemctl stop $GETH_SERVICE
  sleep 1
}

# Fonction pour démarrer les services
start_services() {
  echo -e "${BLUE}Démarrage des services...${NC}"
  systemctl start $GETH_SERVICE
  sleep 2
  systemctl start $STORY_SERVICE
  sleep 1
}

# Fonction pour sauvegarder les clés du validateur
backup_keys() {
  echo -e "${BLUE}Sauvegarde des clés du validateur...${NC}"
  
  # Vérifier l'existence des clés
  if [ -f "$EVM_KEY_PATH" ] || [ -f "$VALIDATOR_KEY_PATH" ]; then
    # Créer l'archive de sauvegarde
    tar -czf "$BACKUP_DIR/story_keys_backup.tar.gz" \
      $([ -f "$EVM_KEY_PATH" ] && echo "$EVM_KEY_PATH") \
      $([ -f "$VALIDATOR_KEY_PATH" ] && echo "$VALIDATOR_KEY_PATH")
    
    echo -e "${GREEN}Sauvegarde créée à $BACKUP_DIR/story_keys_backup.tar.gz${NC}"
  else
    echo -e "${YELLOW}Aucune clé trouvée à sauvegarder.${NC}"
  fi
}

# Fonction pour restaurer les clés du validateur
restore_keys() {
  if [ ! -f "$BACKUP_DIR/story_keys_backup.tar.gz" ]; then
    echo -e "${RED}Erreur: Fichier de sauvegarde non trouvé à $BACKUP_DIR/story_keys_backup.tar.gz${NC}"
    return 1
  fi
  
  echo -e "${BLUE}Restauration des clés du validateur...${NC}"
  
  # Extraire les clés
  tar -xzf "$BACKUP_DIR/story_keys_backup.tar.gz" -C /
  
  echo -e "${GREEN}Clés restaurées avec succès!${NC}"
}

# Fonction pour télécharger un snapshot
download_snapshot() {
  local type=$1
  
  if [ -z "$type" ]; then
    echo -e "${RED}Erreur: Type de snapshot non spécifié (pruned/archive)${NC}"
    show_help
    exit 1
  fi
  
  # Vérifier le type de snapshot
  if [ "$type" != "pruned" ] && [ "$type" != "archive" ]; then
    echo -e "${RED}Erreur: Type de snapshot invalide. Utilisez 'pruned' ou 'archive'${NC}"
    exit 1
  fi
  
  # Vérifier les dépendances
  check_dependencies
  
  echo -e "${BLUE}Téléchargement du snapshot $type...${NC}"
  
  # Télécharger les snapshots Geth et Story
  echo -e "${YELLOW}Téléchargement du snapshot Geth...${NC}"
  aria2c -x 16 -s 16 "$SNAPSHOT_BASE_URL/geth_${type}_latest.tar.lz4" -d $SNAPSHOT_DIR
  
  echo -e "${YELLOW}Téléchargement du snapshot Story...${NC}"
  aria2c -x 16 -s 16 "$SNAPSHOT_BASE_URL/story_${type}_latest.tar.lz4" -d $SNAPSHOT_DIR
  
  echo -e "${GREEN}Snapshots téléchargés dans $SNAPSHOT_DIR${NC}"
}

# Fonction pour importer un snapshot
import_snapshot() {
  local type=$1
  
  if [ -z "$type" ]; then
    echo -e "${RED}Erreur: Type de snapshot non spécifié (pruned/archive)${NC}"
    show_help
    exit 1
  fi
  
  # Vérifier le type de snapshot
  if [ "$type" != "pruned" ] && [ "$type" != "archive" ]; then
    echo -e "${RED}Erreur: Type de snapshot invalide. Utilisez 'pruned' ou 'archive'${NC}"
    exit 1
  fi
  
  # Vérifier l'existence des fichiers de snapshot
  if [ ! -f "$SNAPSHOT_DIR/geth_${type}_latest.tar.lz4" ] || [ ! -f "$SNAPSHOT_DIR/story_${type}_latest.tar.lz4" ]; then
    echo -e "${RED}Erreur: Snapshots non trouvés dans $SNAPSHOT_DIR${NC}"
    echo -e "Veuillez d'abord télécharger les snapshots avec: $0 download $type"
    exit 1
  fi
  
  echo -e "${BLUE}Importation du snapshot $type...${NC}"
  
  # Arrêter les services
  stop_services
  
  # Sauvegarder les clés
  echo -e "${YELLOW}Sauvegarde des clés...${NC}"
  backup_keys
  
  # Supprimer les anciennes données
  echo -e "${YELLOW}Suppression des anciennes données...${NC}"
  rm -rf $STORY_DATA_DIR
  mkdir -p $STORY_DATA_DIR
  rm -rf $GETH_DATA_DIR/aeneid/geth/chaindata
  mkdir -p $GETH_DATA_DIR/aeneid/geth
  
  # Importer les snapshots
  echo -e "${YELLOW}Importation du snapshot Story...${NC}"
  lz4 -cd "$SNAPSHOT_DIR/story_${type}_latest.tar.lz4" | tar -xf - -C $(dirname $STORY_DATA_DIR)
  
  echo -e "${YELLOW}Importation du snapshot Geth...${NC}"
  lz4 -cd "$SNAPSHOT_DIR/geth_${type}_latest.tar.lz4" | tar -xf - -C $GETH_DATA_DIR/aeneid/geth
  
  # Restaurer les clés
  echo -e "${YELLOW}Restauration des clés...${NC}"
  restore_keys
  
  # Démarrer les services
  start_services
  
  echo -e "${GREEN}Snapshots importés avec succès!${NC}"
}

# Traitement des commandes
case "$1" in
  download)
    download_snapshot "$2"
    ;;
  import)
    import_snapshot "$2"
    ;;
  help|*)
    show_help
    ;;
esac

exit 0
