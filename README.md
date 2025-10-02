# VaBadger

## Disclaimer

**Important :** La quasi-totalité de ce projet a été générée par une IA

## 📋 Description

VaBadger est un outil d'alerte visuelle et sonore pour Windows qui affiche un message plein écran sur tous vos moniteurs. Conçu pour créer des rappels impossibles à ignorer !

## ✨ Fonctionnalités

- 🖥️ **Multi-écrans** : Affichage simultané sur tous les moniteurs connectés
- 🔴 **Alerte visuelle** : Écran rouge clignotant avec le message "VA BADGER !"
- 🔊 **Signal sonore** : Bip d'alerte pour attirer l'attention
- ⌨️ **Sortie simple** : Appuyez sur Échap pour fermer l'alerte
- 📅 **Planification** : Configuration facile pour des alertes quotidiennes ou ponctuelles
- 🔒 **Sécurité** : Timeout automatique après 5 minutes

## 🚀 Installation

1. Clonez ou téléchargez ce dépôt
2. Assurez-vous que PowerShell est installé (inclus par défaut dans Windows)
3. C'est tout ! Aucune dépendance externe nécessaire

## 📖 Utilisation

### Lancer une alerte immédiate

```powershell
.\Alerte.ps1
```

L'alerte s'affichera immédiatement. Appuyez sur **Échap** pour la fermer.

### Configurer des alertes planifiées

```powershell
.\config.ps1
```

Le script de configuration vous guidera à travers les étapes suivantes :

1. **Élévation des privilèges** : Le script demandera les droits administrateur (nécessaires pour créer une tâche planifiée)
2. **Choix du mode** :
   - Option 1 : Exécution unique aujourd'hui à une heure précise
   - Option 2 : Exécution quotidienne à une heure fixe
3. **Définition de l'heure** : Saisissez l'heure au format HH:MM (ex: 14:30)

Le script créera automatiquement une tâche dans le Planificateur de tâches Windows nommée `VaBadger_DailyAlert`.

### Supprimer les alertes planifiées

```powershell
.\cleanup.ps1
```

Ce script :

- Recherche la tâche planifiée VaBadger
- Affiche ses détails
- Demande confirmation avant suppression
- Nécessite les droits administrateur

## 📁 Structure du projet

VaBadger/
│
├── Alerte.ps1      # Script principal d'alerte visuelle
├── config.ps1      # Script de configuration des tâches planifiées
├── cleanup.ps1     # Script de suppression des tâches planifiées
└── README.md       # Ce fichier

## 🔧 Détails techniques

### Alerte.ps1

- Utilise Windows Forms pour l'affichage graphique
- Appelle l'API Win32 `GetAsyncKeyState` pour la détection des touches
- Gère plusieurs écrans via `System.Windows.Forms.Screen`
- Boucle d'affichage avec détection continue de la touche Échap
- Timeout de sécurité de 5 minutes

### config.ps1

- Crée une tâche dans le Planificateur de tâches Windows
- Gère l'élévation automatique des privilèges
- Validation des formats d'heure (HH:MM)
- Support des exécutions uniques et quotidiennes
- Double vérification de la création de la tâche

### cleanup.ps1

- Supprime la tâche planifiée VaBadger
- Demande confirmation avant suppression
- Gère l'élévation automatique des privilèges

## ⚙️ Configuration avancée

Vous pouvez modifier manuellement la tâche planifiée via :

- **Planificateur de tâches Windows** (`taskschd.msc`)
- Recherchez la tâche `VaBadger_DailyAlert`

### Personnalisation de l'alerte

Dans `Alerte.ps1`, vous pouvez modifier :

- **Le message** : Ligne 45 - `$label.Text = "VA BADGER !"`
- **La couleur** : Ligne 37 - `$form.BackColor = 'Red'`
- **L'opacité** : Ligne 38 - `$form.Opacity = 0.7`
- **La taille de police** : Ligne 46 - `New-Object System.Drawing.Font("Arial", 72, ...)`
- **Le son** : Ligne 86 - `[console]::beep(1000, 300)` (fréquence, durée)
- **Le timeout** : Ligne 133 - `[TimeSpan]::FromMinutes(5)`

## ⚠️ Prérequis

- **OS** : Windows 7 ou supérieur
- **PowerShell** : Version 5.1 ou supérieure
- **Droits** : Administrateur requis uniquement pour config.ps1 et cleanup.ps1

## 🐛 Dépannage

### L'alerte ne se ferme pas avec Échap

- Cliquez sur la fenêtre d'alerte pour lui donner le focus
- Appuyez ensuite sur Échap
- Le timeout de 5 minutes fermera automatiquement l'alerte en dernier recours

### La tâche planifiée ne s'exécute pas

- Vérifiez dans le Planificateur de tâches que la tâche est active
- Assurez-vous que votre ordinateur est allumé à l'heure prévue
- Vérifiez les paramètres d'alimentation (la tâche peut s'exécuter sur batterie)

### Erreur de droits administrateur

- Faites un clic droit sur PowerShell et choisissez "Exécuter en tant qu'administrateur"
- Ou laissez le script demander l'élévation automatiquement

## 📝 Licence

Ce projet a utilise la licence MIT. Consultez le fichier LICENSE pour plus de détails.

## 👤 Auteur

Créé pour ceux qui ont besoin de rappels impossibles à ignorer ! 🦡

---

**Note** : Utilisez cet outil de manière responsable. Les alertes plein écran peuvent être perturbantes !
