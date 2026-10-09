# OpenLab - VM Azure avec Terraform 

Trois déploiements Terraform indépendants pour créer rapidement une VM propre sur Azure : **Ubuntu**, **Windows 11** et **Windows Server**. Aucune VM n'utilise cloud-init : les machines sont livrées nues, prêtes à être configurées.

## Les trois VM

| | Ubuntu | Windows client | Windows Server |
|---|---|---|---|
| **Dossier** | `Ubuntu-VM-Terraform-Azure` | `Windows-Client-VM-Terraform-Azure` | `Windows-Server-VM-Terraform-Azure` |
| **Système** | Ubuntu Server 24.04 LTS | Windows 11 Pro 24H2 | Windows Server 2025 Datacenter |
| **Taille** | `Standard_B2s_v2` | `Standard_B2s_v2` | `Standard_D2s_v5` |
| **Connexion** | SSH (port 22) | RDP (port 3389) | RDP (port 3389) |
| **Authentification** | Clé SSH générée | Mot de passe généré | Mot de passe généré |
| **Réseau** | `10.10.0.0/16` | `10.20.0.0/16` | `10.30.0.0/16` |
| **Resource Group** | `OpenLab-Ubuntu-RG` | `OpenLab-WinClient-RG` | `OpenLab-WinServer-RG` |

Les réseaux ne se chevauchent pas : les trois VM peuvent être déployées en même temps.

## Caractéristiques communes

- Région `swedencentral`, IP publique statique (SKU Standard), disque OS Premium
- NSG minimal : un seul port ouvert, extensible via `extra_inbound_ports`
- Disque de données optionnel (`data_disk_size_gb`, désactivé par défaut)
- Démarrage sécurisé et vTPM (Trusted Launch)
- State local par défaut, backend Azure Storage optionnel (`setup-backend.sh`)
- Tags `project` et `managed_by` sur toutes les ressources

## Structure d'un projet

```
├── versions.tf               # Terraform et providers
├── variables.tf              # Variables et valeurs par défaut
├── main.tf                   # Resource Group, réseau, IP publique, NSG
├── vm.tf                     # Machine virtuelle
├── outputs.tf                # IP et informations de connexion
├── terraform.tfvars.example  # Exemple de personnalisation
├── backend.tf.example        # Backend distant (optionnel)
└── setup-backend.sh          # Création du backend (optionnel)
```

## Prérequis

- Un abonnement Azure avec le rôle Contributor
- Azure Cloud Shell, ou Terraform ≥ 1.5 avec `az login`
- Hors Cloud Shell : `export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)`

## Déploiement

Depuis le dossier de la VM souhaitée :

```bash
terraform init  && terraform validate && terraform plan && terraform apply -auto-approve
```

Connexion :

```bash
# Ubuntu
terraform output -raw ssh_command

# Windows (client ou serveur)
terraform output public_ip_address
terraform output -raw admin_password      # utilisateur : labadmin
```

Suppression : `terraform destroy -auto-approve`

## Points d'attention

- **Sécurité** : par défaut, le port d'administration est ouvert à tout Internet. Restreignez-le avec `allowed_source_cidr = "<votre-ip>/32"` dans `terraform.tfvars`.
- **Windows 11** : le déploiement sur Azure nécessite une licence éligible (Microsoft 365 E3/E5/F3, Windows VDA ou Visual Studio).
- **State** : il contient la clé SSH ou le mot de passe administrateur. Ne le publiez pas (`.gitignore` fourni).
