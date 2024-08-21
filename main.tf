locals {
  days_to_hours = var.days_to_expire * 24
  expiration_date = timeadd(formatdate("YYYY-MM-DD'T'HH:mm:ssZ", timestamp()), "${local.days_to_hours}h")
}

# Resource Groups
resource "azurerm_resource_group" "uks" {
  name     = "rg-${var.uks}-${var.labname}-01"
  location = var.uks
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "azurerm_resource_group" "ukw" {
  name     = "rg-${var.ukw}-${var.labname}-01"
  location = var.ukw
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}



# VNETs
resource "azurerm_virtual_network" "uks-hub1" {
  name                = "vnet-${var.uks}-hub-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = [cidrsubnet("${var.ukscidr}", 2, 0)]
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_virtual_network" "ukw-hub1" {
  name                = "vnet-${var.ukw}-hub-01"
  location            = var.ukw
  resource_group_name = azurerm_resource_group.rg2.name
  address_space       = [cidrsubnet("${var.ukwcidr}", 2, 0)]
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

# Subnets
# Region 1
resource "azurerm_subnet" "uks-hub1-subnet" {
  name                 = "snethost-${var.uks}-vnet-hub-01"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.uks-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukscidr}", 5, 0)]
}
resource "azurerm_subnet" "uks-hub1-subnetlb" {
  name                 = "snetlb-${var.uks}-vnet-hub-01"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.uks-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukscidr}", 5, 1)]
}
resource "azurerm_subnet" "uks-hub1-subnetfw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.uks-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukscidr}", 5, 2)]
}
resource "azurerm_subnet" "uks-hub1-subnetfwman" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.uks-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukscidr}", 5, 3)]
}

# Region 2
resource "azurerm_subnet" "ukw-hub1-subnet" {
  name                 = "snet-${var.ukw}-vnet-hub-01"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.ukw-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukwcidr}", 5, 0)]
}
resource "azurerm_subnet" "ukw-hub1-subnetlb" {
  name                 = "snetlb-${var.ukw}-vnet-hub-01"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.ukw-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukwcidr}", 5, 1)]
}
resource "azurerm_subnet" "ukw-hub1-subnetfw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.ukw-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukwcidr}", 5, 2)]
}
resource "azurerm_subnet" "ukw-hub1-subnetfwman" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.ukw-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukwcidr}", 5, 3)]
}

# Peerings
resource "azurerm_virtual_network_peering" "hub1-to-hub2" {
  name                      = "${var.uks}-hub-to-${var.ukw}-hub"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = azurerm_virtual_network.uks-hub1.name
  remote_virtual_network_id = azurerm_virtual_network.ukw-hub1.id
}
resource "azurerm_virtual_network_peering" "hub2-to-hub1" {
  name                      = "${var.ukw}-hub-to-${var.uks}-hub"
  resource_group_name       = azurerm_resource_group.rg2.name
  virtual_network_name      = azurerm_virtual_network.ukw-hub1.name
  remote_virtual_network_id = azurerm_virtual_network.uks-hub1.id
}

# NSGs
resource "azurerm_network_security_group" "uks-nsg1" {
  name                = "nsg-snet-${var.uks}-vnet-hub-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.rg1.name

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_subnet_network_security_group_association" "uks-hub" {
  subnet_id                 = azurerm_subnet.uks-hub1-subnet.id
  network_security_group_id = azurerm_network_security_group.uks-nsg1.id
}

resource "azurerm_network_security_group" "ukw-nsg1" {
  name                = "nsg-snet-${var.ukw}-vnet-hub-01"
  location            = var.ukw
  resource_group_name = azurerm_resource_group.rg2.name

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_subnet_network_security_group_association" "ukw-hub" {
  subnet_id                 = azurerm_subnet.ukw-hub1-subnet.id
  network_security_group_id = azurerm_network_security_group.ukw-nsg1.id
}


# Route Tables
resource "azurerm_route_table" "uks-rt1" {
  name                = "rtbl-${var.uks}-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.rg1.name

  route {
    name                   = "route1"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.uks-fw1.ip_configuration[0].private_ip_address
  }
}
resource "azurerm_subnet_route_table_association" "uks" {
  subnet_id      = azurerm_subnet.uks-hub1-subnet.id
  route_table_id = azurerm_route_table.uks-rt1.id
}

resource "azurerm_route_table" "ukw-rt1" {
  name                = "rtbl-${var.ukw}-01"
  location            = var.ukw
  resource_group_name = azurerm_resource_group.rg2.name

  route {
    name                   = "route1"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.ukw-fw1.ip_configuration[0].private_ip_address
  }
}
resource "azurerm_subnet_route_table_association" "ukw" {
  subnet_id      = azurerm_subnet.ukw-hub1-subnet.id
  route_table_id = azurerm_route_table.ukw-rt1.id
}

# Key Vault
resource "random_id" "kvname" {
  byte_length = 5
  prefix      = "keyvault"
}
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv1" {
  depends_on                  = [azurerm_resource_group.rg1]
  name                        = random_id.kvname.hex
  location                    = var.uks
  resource_group_name         = azurerm_resource_group.rg1.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  network_acls {
    default_action = "Deny"
    bypass = "AzureServices"
    #virtual_network_subnet_ids = [azurerm_subnet.uks-hub1-subnet,azurerm_subnet.ukw-hub1-subnet, azurerm_network_interface.uks-anics[count.index].id, azurerm_network_interface.ukw-anics[count.index].id ]
    virtual_network_subnet_ids = concat(
      [azurerm_subnet.uks-hub1-subnet.id, azurerm_subnet.ukw-hub1-subnet.id],
      azurerm_network_interface.uks-anics[*].id,
      azurerm_network_interface.ukw-anics[*].id
    )
  }

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
    ]

    storage_permissions = [
      "Get",
    ]
  }
tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "random_password" "vmpassword" {
  length  = 20
  special = true
}
resource "azurerm_key_vault_secret" "vmpassword1" {
  name         = "vmpassword1"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.kv1.id
  content_type = "uks VM Password Secret"
  expiration_date = local.expiration_date
  depends_on   = [azurerm_key_vault.kv1]
}

resource "azurerm_key_vault_secret" "vmpassword2" {
  name         = "vmpassword2"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.kv1.id
  content_type = "ukw VM Password Secret"
  expiration_date = local.expiration_date
  depends_on   = [azurerm_key_vault.kv1]
}

# NICs
resource "azurerm_network_interface" "uks-anics" {
  count               = var.servercounta
  name                = "nic-${var.uks}-a-${count.index}"
  location            = var.uks
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "${var.uks}-nic-a-${count.index}-ipconfig"
    subnet_id                     = azurerm_subnet.uks-hub1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_network_interface" "uks-bnics" {
  count               = var.servercountb
  name                = "nic-${var.uks}-b-${count.index}"
  location            = var.uks
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "${var.uks}-nic-b-${count.index}-ipconfig"
    subnet_id                     = azurerm_subnet.uks-hub1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "azurerm_network_interface" "ukw-anics" {
  count               = var.servercounta
  name                = "nic-${var.ukw}-a-${count.index}"
  location            = var.ukw
  resource_group_name = azurerm_resource_group.rg2.name

  ip_configuration {
    name                          = "${var.ukw}-nic-a-${count.index}-ipconfig"
    subnet_id                     = azurerm_subnet.ukw-hub1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_network_interface" "ukw-bnics" {
  count               = var.servercountb
  name                = "nic-${var.ukw}-b-${count.index}"
  location            = var.ukw
  resource_group_name = azurerm_resource_group.rg2.name

  ip_configuration {
    name                          = "${var.ukw}-nic-b-${count.index}-ipconfig"
    subnet_id                     = azurerm_subnet.ukw-hub1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

# Availability Sets
resource "azurerm_availability_set" "uks-asa" {
  name                        = "as-${var.uks}-a"
  location                    = var.uks
  resource_group_name         = azurerm_resource_group.rg1.name
  platform_fault_domain_count = 2

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_availability_set" "uks-asb" {
  name                        = "as-${var.uks}-b"
  location                    = var.uks
  resource_group_name         = azurerm_resource_group.rg1.name
  platform_fault_domain_count = 2

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "azurerm_availability_set" "ukw-asa" {
  name                        = "as-${var.ukw}-a"
  location                    = var.ukw
  resource_group_name         = azurerm_resource_group.rg2.name
  platform_fault_domain_count = 2

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_availability_set" "ukw-asb" {
  name                        = "as-${var.ukw}-b"
  location                    = var.ukw
  resource_group_name         = azurerm_resource_group.rg2.name
  platform_fault_domain_count = 2

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}


# Virtual Machines 
# NTS - I need to add in a custom ext script to install Hyper-V, IIS, and potentially create a VM within HyperV for testing.
resource "azurerm_windows_virtual_machine" "uks-vmsa" {
  count               = var.servercounta
  name                = "vm-${var.ukscode}-a-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.uks
  size                = "Standard_D2s_v4"
  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword1.value
  availability_set_id = azurerm_availability_set.uks-asa.id
  network_interface_ids = [
    azurerm_network_interface.uks-anics[count.index].id,
  ]

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "uks-vmsb" {
  count               = var.servercountb
  name                = "vm-${var.ukscode}-b-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.uks
  size                = "Standard_D2s_v4"
  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword2.value
  availability_set_id = azurerm_availability_set.uks-asb.id
  network_interface_ids = [
    azurerm_network_interface.uks-bnics[count.index].id,
  ]

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "ukw-avms" {
  count               = var.servercounta
  name                = "vm-${var.ukwcode}-a-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.rg2.name
  location            = var.ukw
  size                = "Standard_D2s_v4"
  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword2.value
  availability_set_id = azurerm_availability_set.ukw-asa.id
  network_interface_ids = [
    azurerm_network_interface.ukw-anics[count.index].id,
  ]

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}
resource "azurerm_windows_virtual_machine" "ukw-bvms" {
  count               = var.servercountb
  name                = "vm-${var.ukwcode}-b-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.rg2.name
  location            = var.ukw
  size                = "Standard_D2s_v4"
  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword2.value
  availability_set_id = azurerm_availability_set.ukw-asb.id
  network_interface_ids = [
    azurerm_network_interface.ukw-bnics[count.index].id,
  ]

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}


#Public IPs
resource "random_id" "dns-name" {
  byte_length = 4
}
resource "azurerm_public_ip" "uks-fwpip" {
  name                = "pip-fw-${var.uks}-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "pip-${var.ukscode}-${random_id.dns-name.hex}"
}
resource "azurerm_public_ip" "uks-fwmanpip" {
  name                = "pip-fwman-${var.uks}-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_public_ip" "ukw-fwpip" {
  name                = "pip-fw-${var.ukw}-01"
  location            = var.ukw
  resource_group_name = azurerm_resource_group.rg2.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "pip-${var.ukwcode}-${random_id.dns-name.hex}"
}
resource "azurerm_public_ip" "ukw-fwmanpip" {
  name                = "pip-fwman-${var.ukw}-01"
  location            = var.ukw
  resource_group_name = azurerm_resource_group.rg2.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Firewalls
resource "azurerm_firewall" "uks-fw1" {
  name                = "fw-${var.uks}-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.rg1.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  threat_intel_mode   = "Off"

  ip_configuration {
    name                 = "ipconfig-fw-${var.uks}"
    subnet_id            = azurerm_subnet.uks-hub1-subnetfw.id
    public_ip_address_id = azurerm_public_ip.uks-fwpip.id
  }

  management_ip_configuration {
    name                 = "ipconfig-fwman-${var.uks}"
    subnet_id            = azurerm_subnet.uks-hub1-subnetfwman.id
    public_ip_address_id = azurerm_public_ip.uks-fwmanpip.id
  }

}
resource "azurerm_firewall" "ukw-fw1" {
  name                = "fw-${var.ukw}-01"
  location            = var.ukw
  resource_group_name = azurerm_resource_group.rg2.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  threat_intel_mode   = "Off"

  ip_configuration {
    name                 = "ipconfig-fw-${var.ukw}"
    subnet_id            = azurerm_subnet.ukw-hub1-subnetfw.id
    public_ip_address_id = azurerm_public_ip.ukw-fwpip.id
  }

  management_ip_configuration {
    name                 = "ipconfig-fwman-${var.ukw}"
    subnet_id            = azurerm_subnet.ukw-hub1-subnetfwman.id
    public_ip_address_id = azurerm_public_ip.ukw-fwmanpip.id
  }

}

# Firewall Rules
resource "azurerm_firewall_network_rule_collection" "uks-outbound" {
  name                = "${var.uks}-outbound"
  azure_firewall_name = azurerm_firewall.uks-fw1.name
  resource_group_name = azurerm_resource_group.rg1.name
  priority            = 100
  action              = "Allow"
  rule {
    name                  = "${var.uks}-outbound"
    source_addresses      = [var.ukscidr]
    destination_addresses = ["*"]
    destination_ports     = ["*"]
    protocols             = ["Any"]
  }
}
resource "azurerm_firewall_network_rule_collection" "ukw-outbound" {
  name                = "${var.ukw}-outbound"
  azure_firewall_name = azurerm_firewall.ukw-fw1.name
  resource_group_name = azurerm_resource_group.rg2.name
  priority            = 100
  action              = "Allow"
  rule {
    name                  = "${var.ukw}-outbound"
    source_addresses      = [var.ukwcidr]
    destination_addresses = ["*"]
    destination_ports     = ["*"]
    protocols             = ["Any"]
  }
}

# NAT Rules
resource "azurerm_firewall_nat_rule_collection" "uks-nat" {
  name                = "${var.uks}-nat1"
  azure_firewall_name = azurerm_firewall.uks-fw1.name
  resource_group_name = azurerm_resource_group.rg1.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "${var.uks}-nat1"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "80",
    ]

    destination_addresses = [
      azurerm_public_ip.uks-fwpip.ip_address
    ]

    translated_port = 80

    translated_address = azurerm_lb.uks-lb.frontend_ip_configuration[0].private_ip_address

    protocols = [
      "TCP",
    ]
  }
}
resource "azurerm_firewall_nat_rule_collection" "ukw-nat" {
  name                = "${var.ukw}-nat1"
  azure_firewall_name = azurerm_firewall.ukw-fw1.name
  resource_group_name = azurerm_resource_group.rg2.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "${var.ukw}-nat1"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "80",
    ]

    destination_addresses = [
      azurerm_public_ip.ukw-fwpip.ip_address
    ]

    translated_port = 80

    translated_address = azurerm_lb.ukw-lb.frontend_ip_configuration[0].private_ip_address

    protocols = [
      "TCP",
    ]
  }
}

# LBs
resource "azurerm_lb" "uks-lb" {
  name                = "lb-int-${var.uks}"
  location            = var.uks
  resource_group_name = azurerm_resource_group.rg1.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "fip-lb-int-${var.uks}"
    subnet_id                     = azurerm_subnet.uks-hub1-subnetlb.id
    private_ip_address            = cidrhost("${var.ukscidr}", 260)
    private_ip_address_allocation = "static"
  }
}
resource "azurerm_lb" "ukw-lb" {
  name                = "lb-int-${var.ukw}"
  location            = var.ukw
  resource_group_name = azurerm_resource_group.rg2.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "fip-lb-int-${var.uks}"
    subnet_id                     = azurerm_subnet.ukw-hub1-subnetlb.id
    private_ip_address            = cidrhost("${var.ukwcidr}", 260)
    private_ip_address_allocation = "static"
  }
}
# Probes
resource "azurerm_lb_probe" "uks-probe" {
  loadbalancer_id     = azurerm_lb.uks-lb.id
  name                = "http-probe"
  port                = 80
  protocol            = "Http"
  interval_in_seconds = 60
  request_path        = "/"
}
resource "azurerm_lb_probe" "ukw-probe" {
  loadbalancer_id     = azurerm_lb.ukw-lb.id
  name                = "http-probe"
  port                = 80
  protocol            = "Http"
  interval_in_seconds = 60
  request_path        = "/"
}
# Backend Pool
resource "azurerm_lb_backend_address_pool" "uks-pool" {
  loadbalancer_id = azurerm_lb.uks-lb.id
  name            = "BackEndAddressPool"
}
resource "azurerm_lb_backend_address_pool" "ukw-pool" {
  loadbalancer_id = azurerm_lb.ukw-lb.id
  name            = "BackEndAddressPool"
}
# NIC Association
resource "azurerm_network_interface_backend_address_pool_association" "uks-a" {
  count                   = var.servercounta
  network_interface_id    = azurerm_network_interface.uks-anics[count.index].id
  ip_configuration_name   = "${var.uks}-nic-a-${count.index}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.uks-pool.id
}
resource "azurerm_network_interface_backend_address_pool_association" "uks-b" {
  count                   = var.servercountb
  network_interface_id    = azurerm_network_interface.uks-bnics[count.index].id
  ip_configuration_name   = "${var.uks}-nic-b-${count.index}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.uks-pool.id
}
resource "azurerm_network_interface_backend_address_pool_association" "ukw-a" {
  count                   = var.servercounta
  network_interface_id    = azurerm_network_interface.ukw-anics[count.index].id
  ip_configuration_name   = "${var.ukw}-nic-a-${count.index}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ukw-pool.id
}
resource "azurerm_network_interface_backend_address_pool_association" "ukw-b" {
  count                   = var.servercountb
  network_interface_id    = azurerm_network_interface.ukw-bnics[count.index].id
  ip_configuration_name   = "${var.ukw}-nic-b-${count.index}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ukw-pool.id
}
# Rules
resource "azurerm_lb_rule" "uks-rule" {
  loadbalancer_id                = azurerm_lb.uks-lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.uks-lb.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.uks-probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.uks-pool.id]
}
resource "azurerm_lb_rule" "ukw-rule" {
  loadbalancer_id                = azurerm_lb.ukw-lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.uks-lb.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.ukw-probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ukw-pool.id]
}

# Traffic Manager
resource "azurerm_traffic_manager_profile" "tm1" {
  name                   = "tm-${var.labname}"
  resource_group_name    = azurerm_resource_group.rg1.name
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "${var.labname}-${random_id.dns-name.hex}"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }

tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_traffic_manager_azure_endpoint" "uks-tme1" {
  name               = "${var.uks}-endpoint"
  profile_id         = azurerm_traffic_manager_profile.tm1.id
  weight             = 100
  target_resource_id = azurerm_public_ip.uks-fwpip.id
}
resource "azurerm_traffic_manager_azure_endpoint" "ukw-tme1" {
  name               = "${var.ukw}-endpoint"
  profile_id         = azurerm_traffic_manager_profile.tm1.id
  weight             = 100
  target_resource_id = azurerm_public_ip.ukw-fwpip.id
}

# This section is to report on the VM's activity. Will be used as part of the env to simulate a FA relying on a VM to be up and running

# Storage Account
resource "azurerm_storage_account" "uks-sa1" {
  name                     = "${var.uks}sa01"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = var.uksaccounttier
  account_replication_type = var.uksart
  min_tls_version = "TLS1_2"
}

# App Service Plan
resource "azurerm_service_plan" "uks-asp" {
  name                = "${var.uks}-asp-01"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  os_type             = var.uks-asp-os
  sku_name            = var.uks-asp-sku
}

# Function App
resource "azurerm_linux_function_app" "uks-fa" {
  name                       = "${var.uks}-fa01"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  service_plan_id        = azurerm_service_plan.uks-asp.id
  storage_account_name       = azurerm_storage_account.uks-sa1.name
  storage_account_access_key = azurerm_storage_account.uks-sa1.primary_access_key
  https_only = "true"
  site_config {}
}
