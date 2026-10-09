output "public_ip_address" {
  description = "Adresse IP publique de la VM."
  value       = azurerm_public_ip.pip.ip_address
}

output "ssh_command" {
  description = "Commande de connexion SSH."
  value       = "ssh -i ${local_sensitive_file.private_key.filename} ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

output "private_key_path" {
  description = "Chemin local de la clé privée SSH."
  value       = local_sensitive_file.private_key.filename
}
