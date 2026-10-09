# VM Windows Server 2025 Datacenter sur Azure avec Terraform

Déploiement Terraform **reproductible et minimal** d'une VM Windows Server 2025 Datacenter sur Azure : réseau dédié, IP publique statique, NSG restreint à un seul port, et **disque de données optionnel formaté et monté automatiquement par Terraform**.
Aucun cloud-init : la VM est livrée propre, sans rôle ni logiciel supplémentaire.

> Ce dossier fait partie d'un ensemble de trois projets indépendants (Ubuntu, Windows 11, Windows Server). Leurs réseaux (`10.10`, `10.20`, `10.30`) ne se chevauchent pas : les trois VM peuvent coexister.

## Sommaire

1. [Ressources déployées](#ressources-déployées)
2. [Prérequis](#prérequis)
3. [Déploiement pas à pas](#déploiement-pas-à-pas)
4. [Connexion](#connexion)
5. [Disque de données (montage automatique)](#disque-de-données-montage-automatique)
6. [Variables principales](#variables-principales)
7. [State distant (optionnel)](#state-distant-optionnel)
8. [Destruction](#destruction)
9. [Dépannage](#dépannage)
10. [Structure du projet](#structure-du-projet)

## Ressources déployées

| Ressource | Valeur |
|---|---|
| Resource Group | `OpenLab-WinServer-RG` |
| Région | `swedencentral` |
| Nom de la VM | `OpenLab-WinSrv` |
| Image | Windows Server 2025 Datacenter Azure Edition (Gen2, Trusted Launch) |
| Taille | `Standard_D2s_v5` (2 vCPU / 8 Go) |
| Authentification | Compte `labadmin` + mot de passe généré (24 caractères) |
| Port ouvert | 3389 (RDP) |
| Licence | Incluse (paiement à l'usage) ; Hybrid Benefit via `license_type = "Windows_Server"` |
| Mises à jour | Hotpatch activé (`patch_mode = "AutomaticByPlatform"`) |
| Réseau | VNet `10.30.0.0/16`, IP publique Standard statique, NSG |
| Disque de données | Optionnel : `data_disk_size_gb` (0 par défaut) → créé, attaché, formaté et monté automatiquement |
| Providers | `azurerm ~> 4.0`, `random` |

## Prérequis

- Un abonnement Azure avec le rôle **Contributor**
- **Azure Cloud Shell** (Terraform et Azure CLI déjà installés), ou en local : Terraform ≥ 1.5 et Azure CLI

Hors Cloud Shell, connectez-vous et exportez l'abonnement :

```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

## Déploiement pas à pas

### 1. Se placer dans le dossier du projet

```bash
cd Windows-Server-VM-Terraform-Azure
```

### 2. Créer le fichier de configuration

```bash
cp terraform.tfvars.example terraform.tfvars
```

Toutes les lignes du fichier sont commentées : les valeurs par défaut fonctionnent telles quelles. Deux réglages sont toutefois recommandés.

**Restreindre l'accès à votre IP publique** (fortement conseillé : sans cela, le port RDP (3389) est ouvert à tout Internet) :

```bash
sed -i "s|^# allowed_source_cidr.*|allowed_source_cidr = \"$(curl -4 -s ifconfig.me)/32\"|" terraform.tfvars
```

**Activer un disque de données** (ici 64 Go) :

```bash
sed -i 's|^# data_disk_size_gb.*|data_disk_size_gb = 64|' terraform.tfvars
```

Vous pouvez aussi éditer le fichier à la main (`nano terraform.tfvars`) et décommenter les lignes voulues.

### 3. Déployer

```bash
terraform fmt && terraform init && terraform validate && terraform plan && terraform apply -auto-approve
```

| Étape | Rôle |
|---|---|
| `terraform fmt` | Formate les fichiers `.tf` |
| `terraform init` | Télécharge les providers |
| `terraform validate` | Vérifie la syntaxe et la cohérence de la configuration |
| `terraform plan` | Affiche les ressources qui vont être créées |
| `terraform apply -auto-approve` | Crée l'infrastructure **sans demander de confirmation** |

Durée habituelle : 3 à 5 minutes (1 à 2 minutes de plus si un disque de données est activé).
Pour relire le plan avant de l'appliquer, remplacez la dernière commande par `terraform apply`.

### 4. Récupérer les informations de connexion

```bash
terraform output
```

## Connexion

```bash
terraform output public_ip_address
terraform output -raw admin_password      # utilisateur : labadmin
```

Puis :

- Windows : `mstsc /v:<IP>`
- macOS : application *Microsoft Remote Desktop*
- Linux : `xfreerdp /v:<IP> /u:labadmin`

Serveur **nu** : aucun rôle installé. Exemple, ajouter un rôle :

```powershell
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
```

## Disque de données (montage automatique)

Si `data_disk_size_gb > 0`, Terraform :

1. crée un disque managé vide et l'attache à la VM (LUN 0) ;
2. exécute une extension Azure (`mount-data-disk`) qui initialise le disque en GPT, crée la partition, la formate en **NTFS** (étiquette `Data`) et lui attribue la lettre de lecteur choisie. Pratique, par exemple, pour NTDS/SYSVOL d'un contrôleur de domaine.

Aucune action manuelle n'est nécessaire. Le script est **idempotent** : il ne reformate jamais un disque déjà formaté, et un `terraform apply` ultérieur ne détruit pas les données.

Lettre de lecteur configurable : `data_disk_drive_letter = "F"` (défaut `F`, de `E` à `Z`).

Vérification :

```powershell
Get-Volume -DriveLetter F
```



## Variables principales

| Variable | Défaut | Description |
|---|---|---|
| `vm_name` | `OpenLab-WinSrv` | Nom de la VM (15 caractères max) |
| `vm_size` | `Standard_D2s_v5` | Taille de la VM |
| `data_disk_size_gb` | `0` | Taille du disque de données en Go (0 = aucun) |
| `data_disk_drive_letter` | `F` | Lettre du lecteur du disque de données |
| `enable_hotpatch` | `true` | Hotpatching (voir ci-dessous) |
| `license_type` | `null` | `Windows_Server` pour Azure Hybrid Benefit |
| `allowed_source_cidr` | `*` | IP/CIDR autorisée à joindre la VM (ex. `203.0.113.10/32`) |
| `extra_inbound_ports` | `[]` | Ports TCP supplémentaires à ouvrir (ex. `[80, 443]`) |
| `tags` | `project`, `managed_by` | Tags appliqués à toutes les ressources |

La liste complète, avec descriptions, se trouve dans `variables.tf`.

## State distant (optionnel)

Par défaut le state est local. Pour le stocker dans Azure Blob Storage :

```bash
chmod +x setup-backend.sh
./setup-backend.sh      # crée le Storage Account et génère backend.tf
terraform init
```

> Le state contient le mot de passe administrateur : ne le publiez jamais et ne le committez pas (`.gitignore` fourni).

## Destruction

```bash
terraform destroy -auto-approve
```

Le Resource Group du backend (`OpenLab-TFState-RG`) n'est pas concerné ; supprimez-le à la main si besoin :
`az group delete -n OpenLab-TFState-RG --yes --no-wait`

## Dépannage

| Problème | Solution |
|---|---|
| `subscription_id is a required provider property` | `export ARM_SUBSCRIPTION_ID=...` ou renseigner `subscription_id` dans `terraform.tfvars` |
| `SkuNotAvailable` | Changer `vm_size` ou `location` (`az vm list-skus -l swedencentral --size Standard_D2s_v5 -o table`) |
| SKU d'image introuvable | Lister avec la commande indiquée dans `variables.tf` et ajuster `image_sku` |
| Connexion impossible | Votre IP a changé : mettre à jour `allowed_source_cidr`, puis `terraform apply` |
| `Resource Group already exists` | Changer `rg_name` ou supprimer le RG existant |
| `"patch_mode" must always be set to "AutomaticByPlatform"... hotpatch enabled image` | Déjà corrigé : les images *Azure Edition* sont compatibles hotpatch, la VM utilise donc `AutomaticByPlatform`. Si vous changez `image_sku` pour une image qui n'est pas *Azure Edition*, ajoutez `enable_hotpatch = false` |
| Disque non monté | Consulter `C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\` sur la VM, puis `terraform apply` pour relancer |

## Structure du projet

```
.
├── versions.tf               # Terraform + providers
├── variables.tf              # Variables et valeurs par défaut
├── main.tf                   # Resource Group, réseau, IP publique, NSG, NIC
├── vm.tf                     # VM, disque de données et extension de montage automatique
├── outputs.tf                # IP et informations de connexion
├── scripts/
│   └── mount-data-disk.ps1.tftpl  # Script de montage du disque (modèle Terraform)
├── terraform.tfvars.example  # Exemple de personnalisation
├── backend.tf.example        # Backend distant (optionnel)
├── setup-backend.sh          # Crée le backend distant (optionnel)
└── .gitignore
```
