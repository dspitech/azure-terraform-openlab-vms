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
  default     = "OpenLab-WinServer-RG"
}

variable "vm_name" {
  description = "Nom de la VM (et préfixe des ressources associées)."
  type        = string
  default     = "OpenLab-WinSrv"

  validation {
    condition     = length(var.vm_name) <= 15
    error_message = "Windows limite le nom de machine à 15 caractères."
  }
}

variable "vm_size" {
  description = "Taille de la VM."
  type        = string
  default     = "Standard_D2s_v5"
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

variable "data_disk_drive_letter" {
  description = "Lettre du lecteur du disque de données (créé automatiquement). Éviter C et D (réservées à Windows et au disque temporaire)."
  type        = string
  default     = "F"

  validation {
    condition     = can(regex("^[E-Z]$", var.data_disk_drive_letter))
    error_message = "Utilisez une lettre de E à Z (majuscule)."
  }
}

variable "address_space" {
  description = "Plage d'adresses du réseau virtuel."
  type        = string
  default     = "10.30.0.0/16"
}

variable "subnet_prefix" {
  description = "Plage d'adresses du sous-réseau."
  type        = string
  default     = "10.30.1.0/24"
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

variable "image_sku" {
  description = "SKU Windows Server (génération 2). Lister : az vm image list-skus -l swedencentral -p MicrosoftWindowsServer -f WindowsServer -o table"
  type        = string
  default     = "2025-datacenter-azure-edition"
}

variable "license_type" {
  description = "null = licence incluse (paiement à l'usage). Windows_Server = Azure Hybrid Benefit (si vous avez Software Assurance)."
  type        = string
  default     = null
}

variable "enable_hotpatch" {
  description = "Active le hotpatching (mises à jour sans redémarrage). À mettre à false si vous choisissez une image_sku qui n'est pas de type Azure Edition."
  type        = bool
  default     = true
}
