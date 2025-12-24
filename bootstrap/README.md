Utiliser task --dry pour tester les changements sans exécution


# 🚀 Taskfile Bootstrap WSL2

Bootstrap automatique d'un environnement de développement WSL2 (Debian) avec gestion sécurisée des secrets via **age + SOPS**.

Automatisation complète de l'installation et de la configuration d'un environnement de développement WSL2 Debian avec Homebrew, Zsh, et gestion de secrets via SOPS/Age.

---

## 📋 Table des matières

- [Structure du projet](#structure-du-projet)
- [Vue d'ensemble](#vue-densemble)
- [Prérequis](#prérequis)
- [Installation rapide](#installation-rapide)
- [Architecture de sécurité](#architecture-de-sécurité)
- [Setup initial (première fois)](#setup-initial-première-fois)
- [Déploiement sur nouvelle machine](#déploiement-sur-nouvelle-machine)
- [Utilisation quotidienne](#utilisation-quotidienne)
- [Commandes disponibles](#commandes-disponibles)
- [Gestion des secrets](#gestion-des-secrets)
- [Dépannage](#dépannage)
- [FAQ](#faq)


- [Installation initiale](#installation-initiale)
- [Bootstrap complet](#bootstrap-complet)
- [Gestion des secrets](#gestion-des-secrets)
- [Configuration](#configuration)


---

## 📁 Structure du projet

```
.
├── README.md                    # Documentation complète
├── taskfile.yaml                # Automatisation avec Task
├── .sops.yaml                   # Configuration SOPS (clé publique age)
├── .gitignore                   # Fichiers à exclure de Git
├── configs/                     # 📝 Fichiers de configuration
│   ├── .zshrc                   # Configuration ZSH complète
│   ├── .p10k.zsh                # Configuration Powerlevel10k
│   ├── user-abbreviations       # Abbreviations ZSH
│   ├── config.kdl               # Configuration Zellij
│   └── dracula.kdl              # Thème Dracula pour Zellij
└── secrets/                     # 🔒 Secrets chiffrés
    ├── age-key.txt.age          # Clé age chiffrée avec passphrase
    └── ssh-keys.sops.yaml       # Clés SSH chiffrées avec SOPS
```

---

## 🎯 Vue d'ensemble

Ce projet automatise la configuration complète d'un environnement de développement WSL2 :

**✨ Fonctionnalités :**
- 🍺 Installation automatique de Homebrew
- 📦 Installation de 40+ packages essentiels (git, kubectl, helm, argocd, zsh, zellij, etc.)
- 🔐 Gestion sécurisée des clés SSH avec **double chiffrement** (age + SOPS)
- 🔑 Configuration SSH automatique (GitLab, Seedbox, etc.)
- 🎨 Configuration VS Code (extensions Kubernetes, Docker, Task, Upbound, YAML)
- 🐚 Configuration ZSH complète (Powerlevel10k, plugins Zinit)
- 🖥️ Configuration Zellij (terminal multiplexer)
- ⚙️ Configuration WSL (systemd activé)
- 🌿 Configuration Git (repos clonés automatiquement)
- 🤖 Workflow GitOps-ready
- 🔒 Auto-verrouillage des secrets après bootstrap

**🔐 Sécurité :**
- Double chiffrement AES-256 (age + passphrase + SOPS)
- Clés SSH chiffrées avant commit dans Git
- Passphrase requise pour déchiffrer
- Auto-lock des secrets après utilisation
- Repo public safe avec passphrase forte

---

## 🔧 Prérequis

Avant de lancer le bootstrap, installer manuellement les dépendances minimales :

```
sudo apt update
sudo apt-get install -y curl git age 
sudo sh -c "$(curl -sL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
git clone https://github.com/Mathod95/task.git ~/github/task
cd ~/github/task
task
```

---


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




### Variables configurables

Dans `taskfile.yaml` :

```yaml
vars:
  QUIET: ""                                         # Afficher les outputs (défaut)
  # QUIET: ">/dev/null 2>&1"                        # Mode silencieux
  BREW: /home/linuxbrew/.linuxbrew/bin/brew         # Chemin Homebrew
  SOPS: /home/linuxbrew/.linuxbrew/bin/sops         # Chemin SOPS
```


### Configuration Git

```yaml
user.email: "felix.mathias95@gmail.com"
user.name: "Mathod"
```



###################################################################################################

## 📦 Packages installés

| Outil | Description |
|-------|-------------|
| 🔐 **ArgoCD** | GitOps continuous delivery tool |
| 🦇 **Bat** | Cat clone avec coloration syntaxique |
| 📁 **Eza** | Remplacement moderne de `ls` |
| 🐙 **Git** | Système de contrôle de version |
| 🛳️ **Helm** | Gestionnaire de packages Kubernetes |
| 🧱 **Kind** | Kubernetes in Docker |
| 🐋 **Kubectl** | CLI Kubernetes |
| 🎨 **Kubecolor** | Colorisation pour kubectl |
| 🧭 **Kubectx** | Changement rapide de contexte K8s |
| 🐍 **Vim** | Éditeur de texte |
| 🐚 **Zsh** | Shell puissant |
| 🧩 **Zellij** | Multiplexeur de terminal |

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

```
📦 Packages installés :
--------------------------------------------
🔐  ArgoCD         : 2.9.3
🦇  Bat            : 0.24.0
📁  Eza            : 0.17.0
🐙  Git            : 2.43.0
🛳️  Helm           : 3.13.3
🧱  Kind           : 0.20.0
🐋  Kubectl        : 1.29.0
🎨  Kubecolor      : 0.2.2
🧭  Kubectx        : 0.9.5
🐍  Vim            : 9.0.2116
🐚  Zsh            : 5.9
🧩  Zellij         : 0.39.2
--------------------------------------------
```

###################################################################################################









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







---

## 📝 Notes importantes

- **Première exécution** : Brew est installé, packages installés (sans update)
- **Exécutions suivantes** : Brew est skippé, packages réinstallés (sans upgrade)
- **Upgrades** : Toujours manuels avec `task brew:upgrade`
- **Git** : Installé via apt ET brew (version brew prioritaire dans le PATH)


- **Sudo** : Le mot de passe sudo est mis en cache pendant 15 minutes
- **Passphrase age** : Demandée une seule fois au début du bootstrap
- **Passphrases SSH** : Demandées seulement si tu lances `task ssh:add:keys`
- **Redémarrage terminal** : Nécessaire après le bootstrap pour activer Zsh

## 🤝 Contribution

Pour ajouter de nouveaux packages, édite la section `packages:install` dans le Taskfile.
Ce projet est personnel mais les suggestions sont bienvenues via issues ou pull requests.

## 📜 Licence

Libre d'utilisation - Fait avec ❤️ et Task.dev
































#######################################

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

### Configuration Zsh

- **Histfile** : `~/.histfile`
- **Shell par défaut** : `/home/linuxbrew/.linuxbrew/bin/zsh`
- **Plugins zinit** : Installés automatiquement au premier lancement de Zsh














```bash
# 1. Clone le repo
git clone https://github.com/ton-user/ton-repo.git
cd ton-repo

# 2. Lance le bootstrap
task

# 🔑 [sudo] password: ****
# ✅ Accès sudo accordé

# 📦 ✅ Clé age chiffrée trouvée dans le repo

# 🔑 Déchiffrement de la clé age...
# Enter passphrase: ****
# ✅ Clé age déchiffrée

# 📦 Installation Homebrew...
# ✅ Homebrew installé
# ✅ Télémétrie Homebrew désactivée

# 📦 Installation des packages...
# ✅ 40+ packages installés (age, sops, yq, argocd, helm, kubectl, zsh, zellij, etc.)

# 🔓 Déchiffrement clés SSH...
# ✅ Clé GitLab restaurée
# ✅ Clé Seedbox restaurée
# ✅ SSH config restauré

# ✅ Configuration Git appliquée
# 📥 Clonage de mathod95...
# 📥 Clonage de wsl...
# ✅ Dépôts GitHub synchronisés

# 🔗 Création symlinks helm/kubectl...
# ✅ Symlinks créés
# 📦 Installation des extensions VS Code...
# ✅ Extensions installées
# ✅ Commande 'code' disponible globalement

# ⚙️ Configuration de WSL...
# ✅ systemd activé

# 📝 Création de ~/.histfile...
# ✅ .zshrc copié
# 📝 Copie des abbreviations...
# ✅ Abbreviations copiées
# 📦 Installation des plugins Zinit...
# ✅ Plugins Zinit installés
# 🐚 Changement du shell par défaut vers ZSH...
# ✅ ZSH défini comme shell par défaut

# 📝 Copie de la configuration Zellij...
# ✅ config.kdl copié
# ✅ dracula.kdl copié

# ✅ Bootstrap terminé !
# 🔒 Secrets automatiquement verrouillés
```