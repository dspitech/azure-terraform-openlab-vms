# VM Windows 11 Pro (client) sur Azure avec Terraform

Déploiement propre d'**une** VM, **sans cloud-init** ni script de provisionnement.
Même structure que les deux autres projets (Ubuntu / Windows client / Windows Server) : les trois peuvent coexister, leurs réseaux (`10.10`, `10.20`, `10.30`) ne se chevauchent pas.

## Ce qui est déployé

| Ressource | Valeur |
|---|---|
| Resource Group | `OpenLab-WinClient-RG` |
| Région | `swedencentral` |
| Nom de la VM | `OpenLab-WinCli` |
| Image | Windows 11 Pro 24H2 (Gen2, Trusted Launch) |
| Taille | `Standard_B2s_v2` (2 vCPU / 8 Go) |
| Authentification | Compte `labadmin` + mot de passe généré (24 caractères) |
| Port ouvert | 3389 (RDP) |
| Licence | `Windows_Client` (voir l'avertissement ci-dessous) |
| Réseau | VNet `10.20.0.0/16`, IP publique Standard statique, NSG |
| Disque de données | Optionnel (`data_disk_size_gb`, 0 par défaut) |
| Providers | `azurerm ~> 4.0`, `random` |

## Fichiers

```
.
├── versions.tf               # Terraform + providers
├── variables.tf              # Toutes les variables (valeurs par défaut incluses)
├── main.tf                   # Resource Group, réseau, IP publique, NSG, NIC
├── vm.tf                     # La machine virtuelle (+ disque de données optionnel)
├── outputs.tf                # IP, commande de connexion, mot de passe
├── terraform.tfvars.example  # Exemple de personnalisation
├── backend.tf.example        # Backend distant (optionnel)
├── setup-backend.sh          # Crée le backend distant (optionnel)
└── .gitignore
```

## Prérequis

- Un abonnement Azure (rôle Contributor)
- Azure Cloud Shell (Terraform et Azure CLI déjà présents), ou Terraform ≥ 1.5 + `az login`
- Hors Cloud Shell : `export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)`

## Déploiement

```bash
terraform init
terraform fmt && terraform validate
terraform plan
terraform apply
```

### Sécurité : restreindre l'accès

Par défaut le port 3389 (RDP) est ouvert à tout Internet (`allowed_source_cidr = "*"`), pratique pour un lab mais exposé aux scans. Recommandé :

```bash
cp terraform.tfvars.example terraform.tfvars
# puis décommenter : allowed_source_cidr = "<votre-ip>/32"
```

Pour ouvrir d'autres ports : `extra_inbound_ports = [80, 443]`.

> **Licence Windows 11 sur Azure** : Windows 11 n'est déployable sur Azure que si vous avez une licence éligible (Microsoft 365 E3/E5/F3, A3/A5, Windows VDA, ou abonnement Visual Studio / Dev-Test). Sans cela, le déploiement peut échouer et surtout vous ne seriez pas en règle. Si votre licence l'autorise, aucune action ; sinon utilisez la VM Windows Server.

## Connexion

```bash
terraform output public_ip_address
terraform output -raw admin_password
```

Puis `mstsc /v:<IP>` (Windows), ou Microsoft Remote Desktop (macOS), ou `xfreerdp /v:<IP> /u:labadmin` (Linux).
Utilisateur : `labadmin`.

### Disque de données (si `data_disk_size_gb > 0`)

Disque attaché mais brut : *Gestion des disques* (`diskmgmt.msc`) → initialiser (GPT) → nouveau volume simple, ou en PowerShell :

```powershell
Get-Disk | Where PartitionStyle -eq 'RAW' | Initialize-Disk -PartitionStyle GPT -PassThru |
  New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel Data
```

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
terraform destroy
```

Le Resource Group du backend (`OpenLab-TFState-RG`) n'est pas concerné ; supprimez-le à la main si besoin : `az group delete -n OpenLab-TFState-RG --yes --no-wait`.

## Dépannage

| Problème | Solution |
|---|---|
| `subscription_id is a required provider property` | `export ARM_SUBSCRIPTION_ID=...` ou renseigner `subscription_id` dans `terraform.tfvars` |
| `SkuNotAvailable` | Changer `vm_size` ou `location` (`az vm list-skus -l swedencentral --size Standard_B2s_v2 -o table`) |
| SKU d'image introuvable | Lister avec la commande indiquée dans `variables.tf` et ajuster `image_sku` |
| Connexion impossible | Votre IP a changé : mettre à jour `allowed_source_cidr` puis `terraform apply` |
| `Resource Group already exists` | Changer `rg_name` ou supprimer le RG existant |
