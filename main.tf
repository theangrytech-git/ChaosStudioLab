# Resource Groups
resource "azurerm_resource_group" "rg1" {
  name     = "rg-${var.region1}-${var.labname}-01"
  location = var.region1
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "azurerm_resource_group" "rg2" {
  name     = "rg-${var.region2}-${var.labname}-01"
  location = var.region2
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}



# VNETs
resource "azurerm_virtual_network" "region1-hub1" {
  name                = "vnet-${var.region1}-hub-01"
  location            = var.region1
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = [cidrsubnet("${var.region1cidr}", 2, 0)]
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_virtual_network" "region2-hub1" {
  name                = "vnet-${var.region2}-hub-01"
  location            = var.region2
  resource_group_name = azurerm_resource_group.rg2.name
  address_space       = [cidrsubnet("${var.region2cidr}", 2, 0)]
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

# Subnets
# Region 1
resource "azurerm_subnet" "region1-hub1-subnet" {
  name                 = "snethost-${var.region1}-vnet-hub-01"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.region1-hub1.name
  address_prefixes     = [cidrsubnet("${var.region1cidr}", 5, 0)]
}
resource "azurerm_subnet" "region1-hub1-subnetlb" {
  name                 = "snetlb-${var.region1}-vnet-hub-01"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.region1-hub1.name
  address_prefixes     = [cidrsubnet("${var.region1cidr}", 5, 1)]
}
resource "azurerm_subnet" "region1-hub1-subnetfw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.region1-hub1.name
  address_prefixes     = [cidrsubnet("${var.region1cidr}", 5, 2)]
}
resource "azurerm_subnet" "region1-hub1-subnetfwman" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.region1-hub1.name
  address_prefixes     = [cidrsubnet("${var.region1cidr}", 5, 3)]
}

# Region 2
resource "azurerm_subnet" "region2-hub1-subnet" {
  name                 = "snet-${var.region2}-vnet-hub-01"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.region2-hub1.name
  address_prefixes     = [cidrsubnet("${var.region2cidr}", 5, 0)]
}
resource "azurerm_subnet" "region2-hub1-subnetlb" {
  name                 = "snetlb-${var.region2}-vnet-hub-01"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.region2-hub1.name
  address_prefixes     = [cidrsubnet("${var.region2cidr}", 5, 1)]
}
resource "azurerm_subnet" "region2-hub1-subnetfw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.region2-hub1.name
  address_prefixes     = [cidrsubnet("${var.region2cidr}", 5, 2)]
}
resource "azurerm_subnet" "region2-hub1-subnetfwman" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.region2-hub1.name
  address_prefixes     = [cidrsubnet("${var.region2cidr}", 5, 3)]
}

# Peerings
resource "azurerm_virtual_network_peering" "hub1-to-hub2" {
  name                      = "${var.region1}-hub-to-${var.region2}-hub"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = azurerm_virtual_network.region1-hub1.name
  remote_virtual_network_id = azurerm_virtual_network.region2-hub1.id
}
resource "azurerm_virtual_network_peering" "hub2-to-hub1" {
  name                      = "${var.region2}-hub-to-${var.region1}-hub"
  resource_group_name       = azurerm_resource_group.rg2.name
  virtual_network_name      = azurerm_virtual_network.region2-hub1.name
  remote_virtual_network_id = azurerm_virtual_network.region1-hub1.id
}

# NSGs
resource "azurerm_network_security_group" "region1-nsg1" {
  name                = "nsg-snet-${var.region1}-vnet-hub-01"
  location            = var.region1
  resource_group_name = azurerm_resource_group.rg1.name

  tags = {
    Environment = var.environment_tag
  }
}
resource "azurerm_subnet_network_security_group_association" "region1-hub" {
  subnet_id                 = azurerm_subnet.region1-hub1-subnet.id
  network_security_group_id = azurerm_network_security_group.region1-nsg1.id
}

resource "azurerm_network_security_group" "region2-nsg1" {
  name                = "nsg-snet-${var.region2}-vnet-hub-01"
  location            = var.region2
  resource_group_name = azurerm_resource_group.rg2.name

  tags = {
    Environment = var.environment_tag
  }
}
resource "azurerm_subnet_network_security_group_association" "region2-hub" {
  subnet_id                 = azurerm_subnet.region2-hub1-subnet.id
  network_security_group_id = azurerm_network_security_group.region2-nsg1.id
}


# Route Tables
resource "azurerm_route_table" "region1-rt1" {
  name                = "rtbl-${var.region1}-01"
  location            = var.region1
  resource_group_name = azurerm_resource_group.rg1.name

  route {
    name                   = "route1"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.region1-fw1.ip_configuration[0].private_ip_address
  }
}
resource "azurerm_subnet_route_table_association" "region1" {
  subnet_id      = azurerm_subnet.region1-hub1-subnet.id
  route_table_id = azurerm_route_table.region1-rt1.id
}

resource "azurerm_route_table" "region2-rt1" {
  name                = "rtbl-${var.region2}-01"
  location            = var.region2
  resource_group_name = azurerm_resource_group.rg2.name

  route {
    name                   = "route1"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.region2-fw1.ip_configuration[0].private_ip_address
  }
}
resource "azurerm_subnet_route_table_association" "region2" {
  subnet_id      = azurerm_subnet.region2-hub1-subnet.id
  route_table_id = azurerm_route_table.region2-rt1.id
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
  location                    = var.region1
  resource_group_name         = azurerm_resource_group.rg1.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

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
    Environment = var.environment_tag
  }
}
resource "random_password" "vmpassword" {
  length  = 20
  special = true
}
resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.kv1.id
  depends_on   = [azurerm_key_vault.kv1]
}

# NICs
resource "azurerm_network_interface" "region1-anics" {
  count               = var.servercounta
  name                = "nic-${var.region1}-a-${count.index}"
  location            = var.region1
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "${var.region1}-nic-a-${count.index}-ipconfig"
    subnet_id                     = azurerm_subnet.region1-hub1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Environment = var.environment_tag
  }
}
resource "azurerm_network_interface" "region1-bnics" {
  count               = var.servercountb
  name                = "nic-${var.region1}-b-${count.index}"
  location            = var.region1
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "${var.region1}-nic-b-${count.index}-ipconfig"
    subnet_id                     = azurerm_subnet.region1-hub1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Environment = var.environment_tag
  }
}

resource "azurerm_network_interface" "region2-anics" {
  count               = var.servercounta
  name                = "nic-${var.region2}-a-${count.index}"
  location            = var.region2
  resource_group_name = azurerm_resource_group.rg2.name

  ip_configuration {
    name                          = "${var.region2}-nic-a-${count.index}-ipconfig"
    subnet_id                     = azurerm_subnet.region2-hub1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Environment = var.environment_tag
  }
}
resource "azurerm_network_interface" "region2-bnics" {
  count               = var.servercountb
  name                = "nic-${var.region2}-b-${count.index}"
  location            = var.region2
  resource_group_name = azurerm_resource_group.rg2.name

  ip_configuration {
    name                          = "${var.region2}-nic-b-${count.index}-ipconfig"
    subnet_id                     = azurerm_subnet.region2-hub1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Environment = var.environment_tag
  }
}

# Availability Sets
resource "azurerm_availability_set" "region1-asa" {
  name                        = "as-${var.region1}-a"
  location                    = var.region1
  resource_group_name         = azurerm_resource_group.rg1.name
  platform_fault_domain_count = 2

  tags = {
    Environment = var.environment_tag
  }
}
resource "azurerm_availability_set" "region1-asb" {
  name                        = "as-${var.region1}-b"
  location                    = var.region1
  resource_group_name         = azurerm_resource_group.rg1.name
  platform_fault_domain_count = 2

  tags = {
    Environment = var.environment_tag
  }
}

resource "azurerm_availability_set" "region2-asa" {
  name                        = "as-${var.region2}-a"
  location                    = var.region2
  resource_group_name         = azurerm_resource_group.rg2.name
  platform_fault_domain_count = 2

  tags = {
    Environment = var.environment_tag
  }
}
resource "azurerm_availability_set" "region2-asb" {
  name                        = "as-${var.region2}-b"
  location                    = var.region2
  resource_group_name         = azurerm_resource_group.rg2.name
  platform_fault_domain_count = 2

  tags = {
    Environment = var.environment_tag
  }
}


# Virtual Machines 
resource "azurerm_windows_virtual_machine" "region1-vmsa" {
  count               = var.servercounta
  name                = "vm-${var.region1code}-a-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.region1
  size                = "Standard_D2s_v4"
  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword.value
  availability_set_id = azurerm_availability_set.region1-asa.id
  network_interface_ids = [
    azurerm_network_interface.region1-anics[count.index].id,
  ]

  tags = {
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

resource "azurerm_windows_virtual_machine" "region1-vmsb" {
  count               = var.servercountb
  name                = "vm-${var.region1code}-b-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.region1
  size                = "Standard_D2s_v4"
  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword.value
  availability_set_id = azurerm_availability_set.region1-asb.id
  network_interface_ids = [
    azurerm_network_interface.region1-bnics[count.index].id,
  ]

  tags = {
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

resource "azurerm_windows_virtual_machine" "region2-avms" {
  count               = var.servercounta
  name                = "vm-${var.region2code}-a-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.rg2.name
  location            = var.region2
  size                = "Standard_D2s_v4"
  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword.value
  availability_set_id = azurerm_availability_set.region2-asa.id
  network_interface_ids = [
    azurerm_network_interface.region2-anics[count.index].id,
  ]

  tags = {
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
resource "azurerm_windows_virtual_machine" "region2-bvms" {
  count               = var.servercountb
  name                = "vm-${var.region2code}-b-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.rg2.name
  location            = var.region2
  size                = "Standard_D2s_v4"
  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword.value
  availability_set_id = azurerm_availability_set.region2-asb.id
  network_interface_ids = [
    azurerm_network_interface.region2-bnics[count.index].id,
  ]

  tags = {
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
resource "azurerm_public_ip" "region1-fwpip" {
  name                = "pip-fw-${var.region1}-01"
  location            = var.region1
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "pip-${var.region1code}-${random_id.dns-name.hex}"
}
resource "azurerm_public_ip" "region1-fwmanpip" {
  name                = "pip-fwman-${var.region1}-01"
  location            = var.region1
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_public_ip" "region2-fwpip" {
  name                = "pip-fw-${var.region2}-01"
  location            = var.region2
  resource_group_name = azurerm_resource_group.rg2.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "pip-${var.region2code}-${random_id.dns-name.hex}"
}
resource "azurerm_public_ip" "region2-fwmanpip" {
  name                = "pip-fwman-${var.region2}-01"
  location            = var.region2
  resource_group_name = azurerm_resource_group.rg2.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Firewalls
resource "azurerm_firewall" "region1-fw1" {
  name                = "fw-${var.region1}-01"
  location            = var.region1
  resource_group_name = azurerm_resource_group.rg1.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  threat_intel_mode   = "Off"

  ip_configuration {
    name                 = "ipconfig-fw-${var.region1}"
    subnet_id            = azurerm_subnet.region1-hub1-subnetfw.id
    public_ip_address_id = azurerm_public_ip.region1-fwpip.id
  }

  management_ip_configuration {
    name                 = "ipconfig-fwman-${var.region1}"
    subnet_id            = azurerm_subnet.region1-hub1-subnetfwman.id
    public_ip_address_id = azurerm_public_ip.region1-fwmanpip.id
  }

}
resource "azurerm_firewall" "region2-fw1" {
  name                = "fw-${var.region2}-01"
  location            = var.region2
  resource_group_name = azurerm_resource_group.rg2.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  threat_intel_mode   = "Off"

  ip_configuration {
    name                 = "ipconfig-fw-${var.region2}"
    subnet_id            = azurerm_subnet.region2-hub1-subnetfw.id
    public_ip_address_id = azurerm_public_ip.region2-fwpip.id
  }

  management_ip_configuration {
    name                 = "ipconfig-fwman-${var.region2}"
    subnet_id            = azurerm_subnet.region2-hub1-subnetfwman.id
    public_ip_address_id = azurerm_public_ip.region2-fwmanpip.id
  }

}

# Firewall Rules
resource "azurerm_firewall_network_rule_collection" "region1-outbound" {
  name                = "${var.region1}-outbound"
  azure_firewall_name = azurerm_firewall.region1-fw1.name
  resource_group_name = azurerm_resource_group.rg1.name
  priority            = 100
  action              = "Allow"
  rule {
    name                  = "${var.region1}-outbound"
    source_addresses      = [var.region1cidr]
    destination_addresses = ["*"]
    destination_ports     = ["*"]
    protocols             = ["Any"]
  }
}
resource "azurerm_firewall_network_rule_collection" "region2-outbound" {
  name                = "${var.region2}-outbound"
  azure_firewall_name = azurerm_firewall.region2-fw1.name
  resource_group_name = azurerm_resource_group.rg2.name
  priority            = 100
  action              = "Allow"
  rule {
    name                  = "${var.region2}-outbound"
    source_addresses      = [var.region2cidr]
    destination_addresses = ["*"]
    destination_ports     = ["*"]
    protocols             = ["Any"]
  }
}

# NAT Rules
resource "azurerm_firewall_nat_rule_collection" "region1-nat" {
  name                = "${var.region1}-nat1"
  azure_firewall_name = azurerm_firewall.region1-fw1.name
  resource_group_name = azurerm_resource_group.rg1.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "${var.region1}-nat1"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "80",
    ]

    destination_addresses = [
      azurerm_public_ip.region1-fwpip.ip_address
    ]

    translated_port = 80

    translated_address = azurerm_lb.region1-lb.frontend_ip_configuration[0].private_ip_address

    protocols = [
      "TCP",
    ]
  }
}
resource "azurerm_firewall_nat_rule_collection" "region2-nat" {
  name                = "${var.region2}-nat1"
  azure_firewall_name = azurerm_firewall.region2-fw1.name
  resource_group_name = azurerm_resource_group.rg2.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "${var.region2}-nat1"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "80",
    ]

    destination_addresses = [
      azurerm_public_ip.region2-fwpip.ip_address
    ]

    translated_port = 80

    translated_address = azurerm_lb.region2-lb.frontend_ip_configuration[0].private_ip_address

    protocols = [
      "TCP",
    ]
  }
}

# LBs
resource "azurerm_lb" "region1-lb" {
  name                = "lb-int-${var.region1}"
  location            = var.region1
  resource_group_name = azurerm_resource_group.rg1.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "fip-lb-int-${var.region1}"
    subnet_id                     = azurerm_subnet.region1-hub1-subnetlb.id
    private_ip_address            = cidrhost("${var.region1cidr}", 260)
    private_ip_address_allocation = "static"
  }
}
resource "azurerm_lb" "region2-lb" {
  name                = "lb-int-${var.region2}"
  location            = var.region2
  resource_group_name = azurerm_resource_group.rg2.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "fip-lb-int-${var.region1}"
    subnet_id                     = azurerm_subnet.region2-hub1-subnetlb.id
    private_ip_address            = cidrhost("${var.region2cidr}", 260)
    private_ip_address_allocation = "static"
  }
}
# Probes
resource "azurerm_lb_probe" "region1-probe" {
  loadbalancer_id     = azurerm_lb.region1-lb.id
  name                = "http-probe"
  port                = 80
  protocol            = "Http"
  interval_in_seconds = 60
  request_path        = "/"
}
resource "azurerm_lb_probe" "region2-probe" {
  loadbalancer_id     = azurerm_lb.region2-lb.id
  name                = "http-probe"
  port                = 80
  protocol            = "Http"
  interval_in_seconds = 60
  request_path        = "/"
}
# Backend Pool
resource "azurerm_lb_backend_address_pool" "region1-pool" {
  loadbalancer_id = azurerm_lb.region1-lb.id
  name            = "BackEndAddressPool"
}
resource "azurerm_lb_backend_address_pool" "region2-pool" {
  loadbalancer_id = azurerm_lb.region2-lb.id
  name            = "BackEndAddressPool"
}
# NIC Association
resource "azurerm_network_interface_backend_address_pool_association" "region1-a" {
  count                   = var.servercounta
  network_interface_id    = azurerm_network_interface.region1-anics[count.index].id
  ip_configuration_name   = "${var.region1}-nic-a-${count.index}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.region1-pool.id
}
resource "azurerm_network_interface_backend_address_pool_association" "region1-b" {
  count                   = var.servercountb
  network_interface_id    = azurerm_network_interface.region1-bnics[count.index].id
  ip_configuration_name   = "${var.region1}-nic-b-${count.index}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.region1-pool.id
}
resource "azurerm_network_interface_backend_address_pool_association" "region2-a" {
  count                   = var.servercounta
  network_interface_id    = azurerm_network_interface.region2-anics[count.index].id
  ip_configuration_name   = "${var.region2}-nic-a-${count.index}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.region2-pool.id
}
resource "azurerm_network_interface_backend_address_pool_association" "region2-b" {
  count                   = var.servercountb
  network_interface_id    = azurerm_network_interface.region2-bnics[count.index].id
  ip_configuration_name   = "${var.region2}-nic-b-${count.index}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.region2-pool.id
}
# Rules
resource "azurerm_lb_rule" "region1-rule" {
  loadbalancer_id                = azurerm_lb.region1-lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.region1-lb.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.region1-probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.region1-pool.id]
}
resource "azurerm_lb_rule" "region2-rule" {
  loadbalancer_id                = azurerm_lb.region2-lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.region1-lb.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.region2-probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.region2-pool.id]
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
    environment = var.environment_tag
  }
}
resource "azurerm_traffic_manager_azure_endpoint" "region1-tme1" {
  name               = "${var.region1}-endpoint"
  profile_id         = azurerm_traffic_manager_profile.tm1.id
  weight             = 100
  target_resource_id = azurerm_public_ip.region1-fwpip.id
}
resource "azurerm_traffic_manager_azure_endpoint" "region2-tme1" {
  name               = "${var.region2}-endpoint"
  profile_id         = azurerm_traffic_manager_profile.tm1.id
  weight             = 100
  target_resource_id = azurerm_public_ip.region2-fwpip.id
}