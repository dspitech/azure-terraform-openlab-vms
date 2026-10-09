# ============================================================
# VM Windows 11 Pro (client) — machine virtuelle (sans cloud-init)
# ============================================================

# Mot de passe administrateur généré (récupérable via terraform output)
resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!#%*-_=+"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.vm_name
  computer_name         = var.vm_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = random_password.admin.result
  network_interface_ids = [azurerm_network_interface.nic.id]
  license_type          = var.license_type
  timezone              = var.timezone
  tags                  = var.tags

  patch_mode          = "AutomaticByOS"
  secure_boot_enabled = true
  vtpm_enabled        = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = var.image_offer
    sku       = var.image_sku
    version   = "latest"
  }

  boot_diagnostics {}
}

# ------------------------------------------------------------
# Disque de données optionnel (data_disk_size_gb > 0)
# Non formaté : à initialiser depuis le système (voir README)
# ------------------------------------------------------------
resource "azurerm_managed_disk" "data" {
  count                = var.data_disk_size_gb > 0 ? 1 : 0
  name                 = "${var.vm_name}-datadisk"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = var.os_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = var.data_disk_size_gb > 0 ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.data[0].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = 0
  caching            = "ReadWrite"
}
