# Changelog - Story Node Manager

## Version 1.3.0 (2025-01-XX)

### ✨ Mise à jour Story v1.3.0 (Polybius)

**Version Story :** v1.2.0 → v1.3.0
**Nom de code :** Polybius
**Type :** Mise à jour obligatoire pour Aeneid Testnet

#### 🔥 Changements importants
- **Augmentation des validateurs actifs** : Passage de 64 à 80 validateurs maximum sur le réseau Aeneid Testnet
- **Hauteur de mise à jour** : 6008000 (mise à jour obligatoire)

#### 📋 Modifications techniques
- Mise à jour des binaires Story vers v1.3.0
- Maintien de Story-Geth v1.1.0 (pas de changement)
- Go version 1.22.5 maintenue
- **Nouvelle fonctionnalité** : Mise à jour sélective des binaires

#### 🆕 Nouvelles commandes de mise à jour
- `./story.sh update` - Met à jour les deux binaires (comportement par défaut)
- `./story.sh update geth` - Met à jour uniquement le binaire Geth
- `./story.sh update story` - Met à jour uniquement le binaire Story

#### 🚀 Comment effectuer la mise à jour

1. **Mise à jour complète (recommandée) :**
   ```bash
   ./story.sh update
   ```

2. **Mise à jour sélective :**
   ```bash
   # Mettre à jour uniquement Story vers v1.3.0
   ./story.sh update story
   
   # Mettre à jour uniquement Geth (si nécessaire)
   ./story.sh update geth
   ```

3. **Vérification des versions après mise à jour :**
   ```bash
   story version
   geth version
   ```

4. **Les services sont redémarrés automatiquement** (pas besoin de restart manuel)

#### ⚠️ Notes importantes
- Cette mise à jour est **obligatoire** pour tous les nœuds du réseau Aeneid Testnet
- La mise à jour se déclenchera automatiquement à la hauteur de bloc 6008000
- Aucune action spéciale n'est requise pour les validateurs existants
- La configuration reste inchangée

#### 🔗 Références
- [Release GitHub v1.3.0](https://github.com/piplabs/story/releases/tag/v1.3.0)
- [Documentation Story Protocol](https://docs.story.foundation/)

---

## Version 1.2.0 (Précédente)

### Fonctionnalités
- Support complet d'Aeneid Testnet
- Gestion automatique des snapshots
- Scripts de mise à jour des pairs
- Monitoring et métriques
- Sauvegarde automatique des clés 