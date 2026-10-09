# ============================================================
# VM Ubuntu Server 24.04 LTS — machine virtuelle (sans cloud-init)
# ============================================================

# Clé SSH générée par Terraform et sauvegardée en local
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = "${path.module}/${var.vm_name}_rsa"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = "${path.module}/${var.vm_name}_rsa.pub"
  file_permission = "0644"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]
  tags                  = var.tags

  disable_password_authentication = true
  secure_boot_enabled             = true
  vtpm_enabled                    = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
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
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = 0
  caching            = "ReadWrite"
}

# Formatage (ext4) et montage persistant dans /etc/fstab, exécutés par l'agent Azure
resource "azurerm_virtual_machine_extension" "mount_data_disk" {
  count                      = var.data_disk_size_gb > 0 ? 1 : 0
  name                       = "mount-data-disk"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  protected_settings = jsonencode({
    script = base64encode(templatefile("${path.module}/scripts/mount-data-disk.sh.tftpl", {
      mount_point    = var.data_disk_mount_point
      admin_username = var.admin_username
    }))
  })

  depends_on = [azurerm_virtual_machine_data_disk_attachment.data]
}
