# Scripts de Reconnaissance Automatisée

Ce dépôt contient deux scripts Bash pour la reconnaissance automatisée de sous-domaines, de ports ouverts, de prises de contrôle potentielles et d'URLs Wayback. L'un des scripts (`auto_recon_new.sh`) inclut des effets visuels pour une meilleure expérience utilisateur, tandis que l'autre (`auto_recon_old.sh`) est une version plus simple et standard.

## Table des Matières

- [Prérequis](#prérequis)
- [Installation](#installation)
- [Utilisation](#utilisation)
  - [Script avec effets visuels (`auto_recon_new.sh`)](#script-avec-effets-visuels-auto_recon_newsh)
  - [Script standard (`auto_recon_old.sh`)](#script-standard-auto_recon_oldsh)
- [Fonctionnalités](#fonctionnalités)
- [Structure des Résultats](#structure-des-résultats)
- [Dépannage](#dépannage)

## Prérequis

Pour exécuter ces scripts, vous devez avoir les outils suivants installés sur votre système. Ces outils sont couramment utilisés dans le domaine de la reconnaissance et de la sécurité informatique.

- **Bash**: Le shell par défaut sur la plupart des systèmes Linux et macOS.
- **assetfinder**: Un outil rapide pour trouver des sous-domaines liés à un domaine cible.
  - Installation: `go install github.com/tomnomnom/assetfinder@latest`
- **httprobe**: Un outil pour prendre une liste de domaines et vérifier lesquels ont des serveurs HTTP ou HTTPS en cours d'exécution.
  - Installation: `go install github.com/tomnomnom/httprobe@latest`
- **subjack**: Un outil pour vérifier les prises de contrôle de sous-domaines.
  - Installation: `go install github.com/haccer/subjack@latest`
- **nmap**: Un utilitaire gratuit et open source pour l'exploration de réseau et l'audit de sécurité.
  - Installation: `sudo apt-get install nmap` (Debian/Ubuntu) ou `sudo yum install nmap` (CentOS/RHEL)
- **waybackurls**: Un outil pour récupérer toutes les URLs connues pour un domaine à partir de la Wayback Machine.
  - Installation: `go install github.com/tomnomnom/waybackurls@latest`
- **wget**: Un utilitaire de ligne de commande pour télécharger des fichiers depuis le web. Généralement préinstallé sur la plupart des systèmes Linux.
- **sublist3r**: Sublist3r est un outil Python conçu pour énumérer les sous-domaines de sites Web en utilisant OSINT. .
  - Installation: `sudo apt install sublis3r`

Assurez-vous que votre `$GOPATH/bin` est dans votre `$PATH` pour que les outils Go soient accessibles depuis n'importe quel répertoire.

```bash
export PATH=$PATH:$(go env GOPATH)/bin
```

## Installation

1. Clonez ce dépôt GitHub ou téléchargez les scripts directement:

   ```bash
   git clone https://github.com/votre_utilisateur/recon_scripts.git
   cd recon_scripts
   ```

2. Rendez les scripts exécutables:

   ```bash
   chmod +x auto_recon_new.sh
   chmod +x auto_recon_old.sh
   ```

## Utilisation

Les deux scripts prennent un domaine cible en argument (par exemple, `example.com`).

### Script avec effets visuels (`auto_recon_new.sh`)

Ce script fournit un retour visuel en temps réel sur la progression de chaque tâche, avec des indicateurs de chargement et des messages colorés.

```bash
./auto_recon_new.sh <domaine_cible>
# Exemple:
./auto_recon_new.sh example.com
```

### Script standard (`auto_recon_old.sh`)

Ce script exécute les mêmes tâches mais avec une sortie plus simple, sans les effets visuels.

```bash
./auto_recon_old.sh <domaine_cible>
# Exemple:
./auto_recon_old.sh example.com
```

## Fonctionnalités

Les deux scripts effectuent les opérations de reconnaissance suivantes:

1.  **Initialisation des répertoires**: Crée une structure de dossiers organisée pour stocker les résultats.
2.  **Récolte de sous-domaines**: Utilise `assetfinder` pour découvrir les sous-domaines.
3.  **Recherche de domaines vivants**: Utilise `httprobe` pour identifier les sous-domaines actifs (avec serveurs HTTP/HTTPS).
4.  **Vérification des prises de contrôle**: Utilise `subjack` pour détecter les sous-domaines vulnérables à la prise de contrôle.
5.  **Scan des ports ouverts**: Utilise `nmap` pour scanner les ports ouverts sur les domaines actifs.
6.  **Récupération des données Wayback**: Utilise `waybackurls` pour collecter les URLs historiques à partir de la Wayback Machine.
7.  **Extraction des paramètres**: Extrait les paramètres des URLs Wayback pour identifier les points d'entrée potentiels.
8.  **Extraction des extensions**: Trie les URLs Wayback par extension (par exemple, `.js`, `.php`, `.json`) pour une analyse ciblée.

## Structure des Résultats

Les résultats de la reconnaissance sont stockés dans un répertoire nommé d'après le domaine cible, avec la structure suivante:

```
<domaine_cible>/
├── recon/
│   ├── httprobe/
│   │   └── alive.txt             # Liste des sous-domaines actifs
│   ├── potential_takeovers/
│   │   └── potential_takeovers.txt # Sous-domaines potentiellement vulnérables à la prise de contrôle
│   ├── scans/
│   │   └── scanned.txt.nmap      # Résultats du scan Nmap
│   │   └── scanned.txt.gnmap
│   │   └── scanned.txt.xml
│   ├── wayback/
│   │   ├── extensions/
│   │   │   ├── aspx.txt
│   │   │   ├── js.txt
│   │   │   ├── json.txt
│   │   │   ├── jsp.txt
│   │   │   └── php.txt           # URLs triées par extension
│   │   ├── params/
│   │   │   └── wayback_params.txt  # Paramètres extraits des URLs Wayback
│   │   └── wayback_output.txt    # Toutes les URLs collectées par waybackurls
│   └── final.txt                 # Liste consolidée de tous les sous-domaines trouvés
```

## Dépannage

- **Commandes introuvables**: Assurez-vous que tous les prérequis sont installés et que leurs chemins d'exécution sont inclus dans votre variable d'environnement `$PATH`.
- **Erreurs de permission**: Assurez-vous que les scripts sont exécutables (`chmod +x`).
- **Problèmes de réseau**: Vérifiez votre connexion Internet et assurez-vous que les outils peuvent accéder aux ressources externes (par exemple, la Wayback Machine, GitHub pour `fingerprints.json`).
- **Sortie vide**: Certains outils peuvent ne pas trouver de résultats pour un domaine donné. Vérifiez les fichiers de sortie individuels pour plus de détails.


