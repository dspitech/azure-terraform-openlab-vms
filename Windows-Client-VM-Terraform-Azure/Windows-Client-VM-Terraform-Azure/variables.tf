variable "subscription_id" {
  description = "ID de l'abonnement Azure (null = variable d'environnement ARM_SUBSCRIPTION_ID)."
  type        = string
  default     = null
}

variable "location" {
  description = "Région Azure."
  type        = string
  default     = "swedencentral"
}

variable "rg_name" {
  description = "Nom du Resource Group."
  type        = string
  default     = "OpenLab-WinClient-RG"
}

variable "vm_name" {
  description = "Nom de la VM (et préfixe des ressources associées)."
  type        = string
  default     = "OpenLab-WinCli"

  validation {
    condition     = length(var.vm_name) <= 15
    error_message = "Windows limite le nom de machine à 15 caractères."
  }
}

variable "vm_size" {
  description = "Taille de la VM."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "admin_username" {
  description = "Compte administrateur local."
  type        = string
  default     = "labadmin"
}

variable "os_disk_type" {
  description = "Type de disque OS : Premium_LRS, StandardSSD_LRS ou Standard_LRS."
  type        = string
  default     = "Premium_LRS"
}

variable "data_disk_size_gb" {
  description = "Taille du disque de données en Go. 0 = pas de disque de données."
  type        = number
  default     = 0
}

variable "address_space" {
  description = "Plage d'adresses du réseau virtuel."
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_prefix" {
  description = "Plage d'adresses du sous-réseau."
  type        = string
  default     = "10.20.1.0/24"
}

variable "allowed_source_cidr" {
  description = "IP/CIDR autorisée à joindre la VM en RDP. \"*\" = tout Internet (déconseillé hors lab). Exemple : \"203.0.113.10/32\"."
  type        = string
  default     = "*"
}

variable "extra_inbound_ports" {
  description = "Ports TCP supplémentaires à ouvrir (ex. [80, 443])."
  type        = list(number)
  default     = []
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources."
  type        = map(string)
  default = {
    project    = "OpenLab"
    managed_by = "terraform"
  }
}

variable "timezone" {
  description = "Fuseau horaire Windows."
  type        = string
  default     = "Romance Standard Time" # Paris
}

variable "image_offer" {
  type    = string
  default = "windows-11"
}

variable "image_sku" {
  description = "SKU Windows 11 (génération 2). Lister : az vm image list-skus -l swedencentral -p MicrosoftWindowsDesktop -f windows-11 -o table"
  type        = string
  default     = "win11-24h2-pro"
}

variable "license_type" {
  description = "Windows_Client = droits d'hébergement multi-locataire (Windows 11 Azure exige une licence éligible : Microsoft 365 E3/E5/F3, A3/A5, Windows VDA ou Visual Studio)."
  type        = string
  default     = "Windows_Client"
}
