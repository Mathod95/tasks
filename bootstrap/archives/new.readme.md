# Taskfile Bootstrap WSL2

Automatisation complète de l'installation et de la configuration d'un environnement de développement WSL2 Debian avec Homebrew, Zsh, et gestion de secrets via SOPS/Age.

## 📋 Table des matières

- [Prérequis](#prérequis)
- [Installation initiale](#installation-initiale)
- [Structure du projet](#structure-du-projet)
- [Bootstrap complet](#bootstrap-complet)
- [Commandes disponibles](#commandes-disponibles)
- [Gestion des secrets](#gestion-des-secrets)
- [Configuration](#configuration)
- [Dépannage](#dépannage)

## 🔧 Prérequis

Avant de lancer le bootstrap, installer manuellement les dépendances minimales :

```bash
sudo apt update
sudo apt-get install -y locales curl git age
sudo sh -c "$(curl -sL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
```

## 🚀 Installation initiale

1. **Cloner le repository :**
```bash
git clone https://github.com/Mathod95/task.git ~/github/task
cd ~/github/task
```

2. **Lancer le bootstrap :**
```bash
task
```

Le bootstrap va :
- ✅ Authentifier sudo
- 🔑 Décrypter la clé age (demande passphrase)
- 🌍 Configurer les locales (en_US.UTF-8)
- 🍺 Installer Homebrew + packages
- 🔐 Déployer les clés SSH via SOPS
- 🔧 Configurer Git
- 🐚 Configurer Zsh comme shell par défaut
- 🔒 Supprimer la clé age déchiffrée (sécurité)

## 📁 Structure du projet

```
.
├── README.md                    # Cette documentation
├── taskfile.yaml                # Automatisation avec Task
├── configs/                     # 📂 Configurations (non chiffrées)
│   ├── .zshrc                   # Configuration Zsh
│   ├── .p10k.zsh                # Configuration Powerlevel10k (optionnel)
│   ├── config.kdl               # Configuration Zellij
│   ├── dracula.kdl              # Thème Zellij
│   └── user-abbreviations       # Abbreviations zsh-abbr
└── secrets/                     # 🔒 Secrets chiffrés
    ├── age-key.txt.age          # Clé age chiffrée avec passphrase
    └── ssh-keys.sops.yaml       # Clés SSH chiffrées avec SOPS
```

## 🎯 Bootstrap complet

### Ordre d'exécution

```yaml
1. sudo:main              # Authentification sudo
2. age:main               # Décryptage clé age (DEMANDE PASSPHRASE)
3. locales:main           # Configuration locales
4. brew:main              # Installation Homebrew + packages
5. sops:main              # Déploiement clés SSH
6. git:main               # Configuration Git
7. zsh:main               # Configuration Zsh
8. age:remove:key         # Suppression clé age (sécurité)
```

### Variables configurables

Dans `taskfile.yaml` :

```yaml
vars:
  QUIET: ""                                          # Afficher les outputs (défaut)
  # QUIET: ">/dev/null 2>&1"                        # Mode silencieux
  BREW: /home/linuxbrew/.linuxbrew/bin/brew         # Chemin Homebrew
  SOPS: /home/linuxbrew/.linuxbrew/bin/sops         # Chemin SOPS
```

## 📚 Commandes disponibles

### Principales

```bash
task                    # Bootstrap complet
task help               # Afficher l'aide
task --list             # Liste exhaustive des commandes
```

### Homebrew

```bash
task brew:update        # Mettre à jour les dépôts
task brew:upgrade       # Upgrader tous les packages
task brew:cleanup       # Nettoyer anciennes versions
task brew:list          # Lister tous les packages
task brew:leaves        # Packages installés manuellement
```

### SSH

```bash
task ssh:add:keys       # Ajouter les clés SSH à l'agent (demande passphrases)
```

### Zsh

```bash
task zsh:main                          # Configuration complète
task zsh:configure:histfile            # Créer fichier historique
task zsh:configure:add-to-shells       # Ajouter à /etc/shells
task zsh:configure:default-shell       # Définir comme shell par défaut
task zsh:deploy:config                 # Déployer .zshrc
```

### Age & SOPS

```bash
task age:decrypt:key    # Décrypter la clé age
task age:remove:key     # Supprimer la clé age déchiffrée
task sops:deploy:ssh    # Déployer les clés SSH
```

## 🔐 Gestion des secrets

### Architecture

1. **Clé age** (`secrets/age-key.txt.age`)
   - Chiffrée avec une passphrase
   - Déchiffrée temporairement dans `~/.config/sops/age/keys.txt`
   - Supprimée automatiquement après utilisation

2. **Secrets SOPS** (`secrets/ssh-keys.sops.yaml`)
   - Chiffrés avec la clé age
   - Contient les clés SSH (gitlab, github, seedbox)
   - Déchiffrés et déployés dans `~/.ssh/`

### Workflow de sécurité

Le bootstrap garantit que :
- ✅ La clé age n'est jamais stockée en clair sur le disque après le bootstrap
- ✅ Les secrets SSH sont déployés avant la suppression de la clé age
- ✅ Une seule passphrase à taper (clé age)

## ⚙️ Configuration

### Packages Homebrew installés

Liste des packages actifs (décommentés dans `taskfile.yaml`) :

```yaml
- age                    # Chiffrement
- argocd                 # GitOps
- bat                    # cat amélioré
- cloud-provider-kind    # Kubernetes
- eza                    # ls amélioré
- fastfetch              # Informations système
- fzf                    # Fuzzy finder
- helm                   # Kubernetes package manager
- kind                   # Kubernetes local
- kubecolor              # kubectl coloré
- kubectx                # Changement de contexte K8s
- ripgrep                # grep amélioré
- sops                   # Gestion secrets
- vim                    # Éditeur
- wget                   # Téléchargement
- yq                     # Parser YAML
- zellij                 # Multiplexeur terminal
- zinit                  # Plugin manager Zsh
- zsh                    # Shell
```

### Configuration Git

```yaml
user.email: "felix.mathias95@gmail.com"
user.name: "Mathod"
```

### Configuration Zsh

- **Histfile** : `~/.histfile`
- **Shell par défaut** : `/home/linuxbrew/.linuxbrew/bin/zsh`
- **Plugins zinit** : Installés automatiquement au premier lancement de Zsh

## 🔧 Dépannage

### Le bootstrap échoue sur SOPS

**Symptôme :** `"sops": executable file not found in $PATH`

**Solution :** Le chemin absolu est déjà configuré. Vérifier que Homebrew s'est bien installé :
```bash
/home/linuxbrew/.linuxbrew/bin/brew --version
```

### La clé age ne se déchiffre pas

**Symptôme :** Erreur lors de `age:decrypt:key`

**Cause :** Passphrase incorrecte ou fichier `secrets/age-key.txt.age` manquant

**Solution :**
```bash
# Vérifier la présence du fichier
ls -la secrets/age-key.txt.age

# Tester le déchiffrement manuellement
age --decrypt secrets/age-key.txt.age
```

### Zsh n'est pas le shell par défaut après le bootstrap

**Symptôme :** Bash s'ouvre au lieu de Zsh

**Solution :** Redémarrer le terminal ou WSL :
```powershell
# Dans PowerShell
wsl --shutdown
```

### Les plugins Zsh ne sont pas installés

**Symptôme :** Erreurs au lancement de Zsh

**Solution :** Les plugins s'installent au premier lancement de Zsh. Lancer :
```bash
zsh
```

Zinit téléchargera automatiquement tous les plugins listés dans `.zshrc`.

## 📝 Notes importantes

- **Sudo** : Le mot de passe sudo est mis en cache pendant 15 minutes
- **Passphrase age** : Demandée une seule fois au début du bootstrap
- **Passphrases SSH** : Demandées seulement si tu lances `task ssh:add:keys`
- **Redémarrage terminal** : Nécessaire après le bootstrap pour activer Zsh

## 🤝 Contribution

Ce projet est personnel mais les suggestions sont bienvenues via issues ou pull requests.

## 📜 Licence

MIT