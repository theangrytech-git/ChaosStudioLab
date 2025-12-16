resource "azurerm_public_ip_prefix" "uks_vmss_win_pip" {
  name                = "${var.name}-pip-prefix"
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = 30
  sku                 = "Standard"
}

resource "azurerm_windows_virtual_machine_scale_set" "uks_win_vmss" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku                         = var.vm_sku
  instances                   = var.instance_count
  admin_username              = var.admin_username
  admin_password              = var.admin_password
  computer_name_prefix        = var.computer_name_prefix
  upgrade_mode                = "Manual"

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.name}-nic"
    primary = true

    ip_configuration {
      name                                   = "${var.name}-ipconfig"
      primary                                = true
      subnet_id                              = var.subnet_id

      public_ip_address {
        name                = "${var.name}-pip"
        domain_name_label   = "${var.name}-vmss"
      }
    }
  }

  tags = var.tags
}
