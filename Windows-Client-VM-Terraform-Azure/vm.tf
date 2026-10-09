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
# Créé, attaché, puis initialisé et monté automatiquement
# par l'extension de script ci-dessous (aucune action manuelle).
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

# Initialisation GPT + partition + formatage NTFS, exécutés par l'agent Azure (PowerShell)
resource "azurerm_virtual_machine_extension" "mount_data_disk" {
  count                      = var.data_disk_size_gb > 0 ? 1 : 0
  name                       = "mount-data-disk"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(templatefile("${path.module}/scripts/mount-data-disk.ps1.tftpl", { drive_letter = var.data_disk_drive_letter }), "UTF-16LE")}"
  })

  depends_on = [azurerm_virtual_machine_data_disk_attachment.data]
}
