# VM Ubuntu Server 24.04 LTS sur Azure avec Terraform

Déploiement propre d'**une** VM, **sans cloud-init** ni script de provisionnement.
Même structure que les deux autres projets (Ubuntu / Windows client / Windows Server) : les trois peuvent coexister, leurs réseaux (`10.10`, `10.20`, `10.30`) ne se chevauchent pas.

## Ce qui est déployé

| Ressource | Valeur |
|---|---|
| Resource Group | `OpenLab-Ubuntu-RG` |
| Région | `swedencentral` |
| Nom de la VM | `OpenLab-Ubuntu` |
| Image | Ubuntu Server 24.04 LTS (Canonical, Gen2, Trusted Launch) |
| Taille | `Standard_B2s_v2` (2 vCPU / 8 Go) |
| Authentification | Clé SSH RSA 4096 générée par Terraform, mot de passe désactivé |
| Port ouvert | 22 (SSH) |
| Réseau | VNet `10.10.0.0/16`, IP publique Standard statique, NSG |
| Disque de données | Optionnel (`data_disk_size_gb`, 0 par défaut) |
| Providers | `azurerm ~> 4.0`, `tls`, `local` |

## Fichiers

```
.
├── versions.tf               # Terraform + providers
├── variables.tf              # Toutes les variables (valeurs par défaut incluses)
├── main.tf                   # Resource Group, réseau, IP publique, NSG, NIC
├── vm.tf                     # La machine virtuelle (+ disque de données optionnel)
├── outputs.tf                # IP, commande de connexion
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

Par défaut le port 22 (SSH) est ouvert à tout Internet (`allowed_source_cidr = "*"`), pratique pour un lab mais exposé aux scans. Recommandé :

```bash
cp terraform.tfvars.example terraform.tfvars
# puis décommenter : allowed_source_cidr = "<votre-ip>/32"
```

Pour ouvrir d'autres ports : `extra_inbound_ports = [80, 443]`.

## Connexion

```bash
terraform output -raw ssh_command   # affiche la commande complète
ssh -i OpenLab-Ubuntu_rsa labadmin@<IP>
```

Depuis Cloud Shell, récupérez la clé avec `download ./OpenLab-Ubuntu_rsa`, puis sous Windows :

```powershell
ssh -i "C:\\Users\\vous\\Downloads\\OpenLab-Ubuntu_rsa" labadmin@<IP>
```

La VM est **nue** : Ubuntu 24.04 à jour de l'image, rien d'autre. Installez ensuite ce dont vous avez besoin (`sudo apt update && sudo apt install ...`).

### Disque de données (si `data_disk_size_gb > 0`)

Le disque est attaché mais non formaté :

```bash
lsblk                                  # repérer le disque (souvent sdc), sans partition
sudo mkfs.ext4 /dev/disk/azure/scsi1/lun0
sudo mkdir /data
echo "UUID=$(sudo blkid -s UUID -o value /dev/disk/azure/scsi1/lun0) /data ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo mount -a
```

## State distant (optionnel)

Par défaut le state est local. Pour le stocker dans Azure Blob Storage :

```bash
chmod +x setup-backend.sh
./setup-backend.sh      # crée le Storage Account et génère backend.tf
terraform init
```

> Le state contient la clé privée SSH : ne le publiez jamais et ne le committez pas (`.gitignore` fourni).

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
