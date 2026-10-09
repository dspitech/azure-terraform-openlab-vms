output "public_ip_address" {
  description = "Adresse IP publique de la VM."
  value       = azurerm_public_ip.pip.ip_address
}

output "rdp_command" {
  description = "Commande de connexion RDP (Windows : cmd ou Win+R)."
  value       = "mstsc /v:${azurerm_public_ip.pip.ip_address}"
}

output "admin_username" {
  description = "Compte administrateur local."
  value       = var.admin_username
}

output "admin_password" {
  description = "Mot de passe administrateur : terraform output -raw admin_password"
  value       = random_password.admin.result
  sensitive   = true
}
