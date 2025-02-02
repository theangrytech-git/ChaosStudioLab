/*******************************************************************************

PROJECT NAME:       AZURE-CHAOS-STUDIO
CREATED BY:         THEANGRYTECH-GIT
REPO:
DESCRIPTION:        This project sets up an Azure environment in UK South which 
will deploy in each region: VM's in an Availability Set, VM Scale Sets, NSG's, 
Key Vaults, Traffic Manager, Firewall, Route Table, Storage Accounts, Load 
Balancers, Application Insights, Managed Identities, Function Apps, App Service 
Plans, Service Buses, Event Hubs, Log Analytics,  and some Chaos Studio 
experiments.

*******************************************************************************/

/*******************************************************************************
Notes:
Chaos Studio is only available in select regions:
https://azure.microsoft.com/en-gb/explore/global-infrastructure/products-by-region/?products=chaos-studio#products-by-region_tab5
My environment is only available in UK South - this will be expanded in future
to cover regions if needed for large-scale experiments.
*******************************************************************************/

/*******************************************************************************
********************************************************************************
                          CREATE LAB ENVIRONMENT
/*******************************************************************************
*******************************************************************************/



/*******************************************************************************
                         CREATE LOCAL VARIABLES
*******************************************************************************/
data "azurerm_subscription" "current" {}
output "current_subscription_display_name" {
value = data.azurerm_subscription.current
}

data "external" "get_public_ip" {
  program = ["python", "${path.module}/get_public_ip.py"]
}

output "public_ip" {
  value = data.external.get_public_ip.result["public_ip"]
}

locals {
  days_to_hours = var.days_to_expire * 24
  expiration_date = timeadd(formatdate("YYYY-MM-DD'T'HH:mm:ssZ", timestamp()), "${local.days_to_hours}h")
flattened_collections = merge([
    for db_name, db in var.cosmos_databases : {
      for collection in db.collections : "${db_name}-${collection}" => {
        database_name  = db_name
        collection_name = collection
      }
    }
  ]...)
}

/*******************************************************************************
                         CREATE RANDOM GENERATOR
*******************************************************************************/

resource "random_string" "random" {
  length           = 3
  lower = true
  upper = false
  numeric = true
  special          = false
}

resource "random_id" "kvname" {
  byte_length = 5
  prefix      = "keyvault"
}

resource "random_password" "vmpassword" {
  length  = 20
  special = true
}

resource "random_id" "dns-name" {
  byte_length = 4
}

/*******************************************************************************
                         CREATE RESOURCE GROUPS
*******************************************************************************/
resource "azurerm_resource_group" "uks" {
  name     = "rg-${var.labname}-${var.uks}-01"
  location = var.uks
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

output "id" {
  value = azurerm_resource_group.uks.id
}

/*******************************************************************************
                         CREATE VIRTUAL NETWORKS
*******************************************************************************/
resource "azurerm_virtual_network" "uks-hub1" {
  name                = "vnet-${var.labname}-${var.uks}-hub01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.uks.name
  address_space       = [cidrsubnet("${var.ukscidr}", 2, 0)]
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

/*******************************************************************************
                         CREATE SUBNETS
*******************************************************************************/
resource "azurerm_subnet" "uks-hub1-subnet" {
  name                 = "snethost-${var.labname}-${var.uks}-01"
  resource_group_name  = azurerm_resource_group.uks.name
  virtual_network_name = azurerm_virtual_network.uks-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukscidr}", 5, 0)]
  service_endpoints = ["Microsoft.KeyVault"]
}
resource "azurerm_subnet" "uks-hub1-subnetlb" {
  name                 = "snetlb-${var.labname}-${var.uks}-01"
  resource_group_name  = azurerm_resource_group.uks.name
  virtual_network_name = azurerm_virtual_network.uks-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukscidr}", 5, 1)]
}
resource "azurerm_subnet" "uks-hub1-subnetfw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.uks.name
  virtual_network_name = azurerm_virtual_network.uks-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukscidr}", 5, 2)]
}
resource "azurerm_subnet" "uks-hub1-subnetfwman" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.uks.name
  virtual_network_name = azurerm_virtual_network.uks-hub1.name
  address_prefixes     = [cidrsubnet("${var.ukscidr}", 5, 3)]
}

/*******************************************************************************
                         CREATE NETWORK PEERINGS
*******************************************************************************/
# To be added in another time - need to look at doing this in another region.

/*******************************************************************************
                         CREATE NETWORK SECURITY GROUPS
*******************************************************************************/
resource "azurerm_network_security_group" "uks-nsg1" {
  name                = "nsg-${var.labname}-${var.uks}-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.uks.name

  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_subnet_network_security_group_association" "uks-hub" {
  subnet_id                 = azurerm_subnet.uks-hub1-subnet.id
  network_security_group_id = azurerm_network_security_group.uks-nsg1.id
}

/*******************************************************************************
                         CREATE ROUTE TABLES
*******************************************************************************/
resource "azurerm_route_table" "uks-rt1" {
  name                = "rtbl-${var.labname}-${var.uks}-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.uks.name

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

/*******************************************************************************
                         CREATE KEY VAULT
*******************************************************************************/

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv1" {
  depends_on                  = [azurerm_resource_group.uks]
  name                        = "${random_id.kvname.hex}uks"
  location                    = var.uks
  resource_group_name         = azurerm_resource_group.uks.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  #soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = concat(
      [azurerm_subnet.uks-hub1-subnet.id]
    )
    ip_rules = [
      data.external.get_public_ip.result["public_ip"],
      "67.208.52.129",
      "88.97.161.207",
      "141.170.17.195",
      "80.169.189.194",
      "88.97.160.245",
    ]
  }

  sku_name = "standard"

  access_policy {
    # Access policy for the current user
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = ["Get"]

    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
    ]

    storage_permissions = ["Get"]
  }

  access_policy {
    # Access policy for Function App's managed identity
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_linux_function_app.uks-fa.identity[0].principal_id
    secret_permissions = ["Get", "List"]
  }

  tags = {
    Owner       = var.owner_tag
    Environment = var.environment_tag
  }
}

/*******************************************************************************
                         CREATE ACCESS POLICIES
*******************************************************************************/

resource "azurerm_key_vault_access_policy" "kv1_vmsa_access" {
  key_vault_id = azurerm_key_vault.kv1.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_windows_virtual_machine.uks-vmsa[0].identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_access_policy" "kv1_vmsb_access" {
  key_vault_id = azurerm_key_vault.kv1.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_windows_virtual_machine.uks-vmsb[0].identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

/*******************************************************************************
                         CREATE KEY VAULT SECRETS
*******************************************************************************/
resource "azurerm_key_vault_secret" "vmpassword1" {
  name         = "vmpassword1"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.kv1.id
  content_type = "uks VM Password Secret"
  expiration_date = local.expiration_date
}

resource "azurerm_key_vault_secret" "vmpassword2" {
  name         = "vmpassword2"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.kv1.id
  content_type = "ukw VM Password Secret"
  expiration_date = local.expiration_date
}

/*******************************************************************************
                         CREATE APP CONFIGS
*******************************************************************************/

resource "azurerm_app_configuration" "uks-config" {
  name                = "appcfg-${var.labname}-${var.uks}-01"
  resource_group_name = azurerm_resource_group.uks.name
  location            = var.uks

  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
    Health = var.health_tag
  }
}

resource "azurerm_app_configuration_key" "ck1" {
  configuration_store_id = azurerm_app_configuration.uks-config.id
  key                    = "key1"
  type                   = "kv"
  label                  = "appsecret1"
  value = random_password.vmpassword.result

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}
resource "azurerm_app_configuration_key" "ck2" {
  configuration_store_id = azurerm_app_configuration.uks-config.id
  key                    = "key2"
  type                   = "kv"
  label                  = "appsecret2"
  value    = random_password.vmpassword.result

  depends_on = [
    azurerm_role_assignment.appconf_dataowner
  ]
}

resource "azurerm_role_assignment" "appconf_dataowner" {
  scope                = azurerm_app_configuration.uks-config.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

/*******************************************************************************
                         CREATE NICS
*******************************************************************************/
resource "azurerm_network_interface" "uks-anics" {
  count               = var.servercounta
  name                = "nic-${var.labname}-${var.uks}-a-${count.index}"
  location            = var.uks
  resource_group_name = azurerm_resource_group.uks.name

  ip_configuration {
    name                          = "nic-${var.labname}-${var.uks}-a-${count.index}-ipconfig"
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
  name                = "nic-${var.labname}-${var.uks}-b-${count.index}"
  location            = var.uks
  resource_group_name = azurerm_resource_group.uks.name

  ip_configuration {
    name                          = "nic-${var.labname}-${var.uks}-b-${count.index}-ipconfig"
    subnet_id                     = azurerm_subnet.uks-hub1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

/*******************************************************************************
                         CREATE AVAILABILITY SETS
*******************************************************************************/
resource "azurerm_availability_set" "uks-asa" {
  name                        = "as-${var.labname}-${var.uks}-01"
  location                    = var.uks
  resource_group_name         = azurerm_resource_group.uks.name
  platform_fault_domain_count = 2

 tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_availability_set" "uks-asb" {
  name                        = "as-${var.labname}-${var.uks}-02"
  location                    = var.uks
  resource_group_name         = azurerm_resource_group.uks.name
  platform_fault_domain_count = 2

 tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

/*******************************************************************************
                    CREATE VIRTUAL MACHINE SCALE SETS
*******************************************************************************/

resource "azurerm_windows_virtual_machine_scale_set" "uks-vmssa" {
  count               = var.vmsscounta
  name                = "vmss-${var.ukscode}-${count.index}"
  resource_group_name = azurerm_resource_group.uks.name
  location            = var.uks
  sku                 = "Standard_B1ms"
  instances           = 6
  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword1.value
  upgrade_mode        = "Automatic"
  zones = ["1","2","3"]

  rolling_upgrade_policy {
    max_unhealthy_instance_percent          = 20   # Max percentage of instances that can be unhealthy during upgrade
    max_batch_instance_percent             = 20   # Max percentage of instances to upgrade in each batch
    max_unhealthy_upgraded_instance_percent = 20   # Max percentage of upgraded instances that can be unhealthy
    pause_time_between_batches             = "PT10M"  # Wait 10 minutes between batches
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

  network_interface {
    name    = "win-vmss-nic-${random_string.random.result}"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.uks-hub1-subnet.id
    }
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.uks-vm1.primary_blob_endpoint
  }
  identity {
    type = "SystemAssigned"
  }

  tags = {
    Owner       = var.owner_tag
    Environment = var.environment_tag
    Health      = var.health_tag
  }
}

data "azurerm_virtual_machine_scale_set" "availability_zone_vmss" {
  for_each            = toset(["1", "2"])
  name = "az-vmss"
  resource_group_name = azurerm_resource_group.uks.name
  depends_on = [azurerm_linux_virtual_machine_scale_set.vmss]
}

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  count               = length(azurerm_windows_virtual_machine_scale_set.uks-vmssa)
  name                = "${azurerm_windows_virtual_machine_scale_set.uks-vmssa[count.index].name}-autoscale"
  resource_group_name = azurerm_resource_group.uks.name
  location            = var.uks
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.uks-vmssa[count.index].id
  enabled             = true

  profile {
    name = "AutoScaleProfile"

    capacity {
      minimum = "1"  # Minimum number of instances
      maximum = "10"  # Maximum number of instances
      default = "6"  # Start with 6 instances
    }

    # Rule to scale out (add 1 VM) when CPU usage is above 50%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.uks-vmssa[count.index].id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = 50
        time_grain         = "PT1M"
        time_window        = "PT5M"
        time_aggregation = "Average"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"  # Add 1 VM every minute
      }
    }

    # Rule to scale in (remove 1 VM) when CPU usage is below 50%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.uks-vmssa[count.index].id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = 50
        time_grain         = "PT1M"
        time_window        = "PT5M"
        time_aggregation = "Average"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"  # Remove 1 VM every minute
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = false
      send_to_subscription_co_administrator = false
    }
  }
}


/*******************************************************************************
                         CREATE VIRTUAL MACHINES
*******************************************************************************/
/***
need to add in a custom ext script to install Hyper-V, IIS, and potentially create a VM within HyperV for testing.
***/

resource "azurerm_windows_virtual_machine" "uks-vmsa" {
  count               = var.servercounta
  name                = "vm-${var.labname}-${var.uks}-a-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.uks.name
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
    Health  = var.health_tag
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
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.uks-vm1.primary_blob_endpoint
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_windows_virtual_machine" "uks-vmsb" {
  count               = var.servercountb
  name                = "vm-${var.labname}-${var.uks}-b-${count.index}"
  depends_on          = [azurerm_key_vault.kv1]
  resource_group_name = azurerm_resource_group.uks.name
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
    Health  = var.health_tag
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
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.uks-vm1.primary_blob_endpoint
  }
  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_virtual_machine" "availability_zone_vms" {
  for_each            = toset(["1", "2"])
  name = "az-vm"
  resource_group_name = azurerm_resource_group.uks.name
  depends_on = [azurerm_linux_virtual_machine_scale_set.vmss]
}

/*******************************************************************************
                         CREATE PUBLIC IP
*******************************************************************************/

resource "azurerm_public_ip" "uks-fwpip" {
  name                = "pip-fw-${var.uks}-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.uks.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "pip-${var.ukscode}-${random_id.dns-name.hex}"
    tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}
resource "azurerm_public_ip" "uks-fwmanpip" {
  name                = "pip-fwman-${var.uks}-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.uks.name
  allocation_method   = "Static"
  sku                 = "Standard"
    tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

/*******************************************************************************
                         CREATE FIREWALLS
*******************************************************************************/
resource "azurerm_firewall" "uks-fw1" {
  name                = "fw-${var.labname}-${var.uks}-01"
  location            = var.uks
  resource_group_name = azurerm_resource_group.uks.name
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
  tags = {
   Owner = var.owner_tag
   Environment = var.environment_tag
  }
}

/*******************************************************************************
                         CREATE FIREWALL RULES
*******************************************************************************/
resource "azurerm_firewall_network_rule_collection" "uks-outbound" {
  name                = "${var.uks}-outbound"
  azure_firewall_name = azurerm_firewall.uks-fw1.name
  resource_group_name = azurerm_resource_group.uks.name
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

/*******************************************************************************
                         CREATE NAT RULES
*******************************************************************************/
resource "azurerm_firewall_nat_rule_collection" "uks-nat" {
  name                = "${var.uks}-nat1"
  azure_firewall_name = azurerm_firewall.uks-fw1.name
  resource_group_name = azurerm_resource_group.uks.name
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

/*******************************************************************************
                         CREATE LOAD BALANCERS
*******************************************************************************/
resource "azurerm_lb" "uks-lb" {
  name                = "lb-int-${var.uks}"
  location            = var.uks
  resource_group_name = azurerm_resource_group.uks.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "fip-lb-int-${var.uks}"
    subnet_id                     = azurerm_subnet.uks-hub1-subnetlb.id
    private_ip_address            = cidrhost("${var.ukscidr}", 260)
    private_ip_address_allocation = "static"
  }
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

/*******************************************************************************
                         CREATE LB PROBES
*******************************************************************************/
resource "azurerm_lb_probe" "uks-probe" {
  loadbalancer_id     = azurerm_lb.uks-lb.id
  name                = "http-probe"
  port                = 80
  protocol            = "Http"
  interval_in_seconds = 60
  request_path        = "/"
}

/*******************************************************************************
                         CREATE LB BACKEND POOLS
*******************************************************************************/
resource "azurerm_lb_backend_address_pool" "uks-pool" {
  loadbalancer_id = azurerm_lb.uks-lb.id
  name            = "BackEndAddressPool"
}

/*******************************************************************************
                         CREATE LB NIC ASSOCIATION
*******************************************************************************/
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

/*******************************************************************************
                         CREATE LB RULES
*******************************************************************************/
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

/*******************************************************************************
                         CREATE TRAFFIC MANAGER
*******************************************************************************/
resource "azurerm_traffic_manager_profile" "tm1" {
  name                   = "tm-${var.labname}-${var.uks}-01"
  resource_group_name    = azurerm_resource_group.uks.name
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

/*******************************************************************************
                         CREATE STORAGE ACCOUNTS
*******************************************************************************/

/***
This section is to report on the VM's activity. Will be used as part of the
env to simulate a FA relying on a VM to be up and running.
***/

resource "azurerm_storage_account" "uks-sa1" {
  name                     = "sa${var.uks}${random_string.random.result}01"
  resource_group_name      = azurerm_resource_group.uks.name
  location                 = azurerm_resource_group.uks.location
  account_tier             = var.uksaccounttier
  account_replication_type = var.uksart
  min_tls_version = "TLS1_2"
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "azurerm_storage_account" "uks-vm1" {
  name                     = "sa${var.uks}vmdiag${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.uks.name
  location                 = azurerm_resource_group.uks.location
  account_tier             = var.uksaccounttier
  account_replication_type = var.uksart
  min_tls_version = "TLS1_2"
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "azurerm_storage_management_policy" "uks_vm1_policy" {
  storage_account_id = azurerm_storage_account.uks-vm1.id
  rule {
    name    = "DeleteOldBlobs"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        # delete {
        #   days_after_modification_greater_than = 30
        # }
      }
    }
  }
  
}

/*******************************************************************************
                         CREATE LOG ANALYTICS
*******************************************************************************/
resource "azurerm_log_analytics_workspace" "vm_fa_logging" {
  name                = "uks-vm-fa-logs"
  resource_group_name = azurerm_resource_group.uks.name
  location            = azurerm_resource_group.uks.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_workspace" "db_bus_logging" {
  name                = "uks-db-bus-logs"
  resource_group_name = azurerm_resource_group.uks.name
  location            = azurerm_resource_group.uks.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_workspace" "other_logging" {
  name                = "uks-other-logs"
  resource_group_name = azurerm_resource_group.uks.name
  location            = azurerm_resource_group.uks.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

/*******************************************************************************
                    CREATE MONITORING AND DIAGNOSTICS
*******************************************************************************/
resource "azurerm_monitor_diagnostic_setting" "vm_fa_diag" {
  name                       = "vm-fa-diagnostics"
  target_resource_id         = azurerm_storage_account.uks-vm1.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.vm_fa_logging.id

  enabled_log {
    category = "Transaction"
  }
}

resource "azurerm_monitor_diagnostic_setting" "db_bus_diag" {
  name                       = "db-bus-diagnostics"
  target_resource_id         = azurerm_storage_account.uks-vm1.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.db_bus_logging.id

  enabled_log {
    category = "Transaction"
  }
}

resource "azurerm_monitor_diagnostic_setting" "other_diag" {
  name                       = "other-diagnostics"
  target_resource_id         = azurerm_storage_account.uks-vm1.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.other_logging.id

  enabled_log {
    category = "Transaction"
  }
}

/*******************************************************************************
                         CREATE APP SERVICE PLAN
*******************************************************************************/
resource "azurerm_service_plan" "uks-asp" {
  name                = "asp-${var.labname}-${var.uks}-01"
  resource_group_name      = azurerm_resource_group.uks.name
  location                 = azurerm_resource_group.uks.location
  os_type             = var.uks-asp-os
  sku_name            = var.uks-asp-sku
  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

/*******************************************************************************
                         CREATE FUNCTION APP
*******************************************************************************/
resource "azurerm_linux_function_app" "uks-fa" {
  name                       = "fa-${var.labname}-${var.uks}-${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.uks.name
  location                 = azurerm_resource_group.uks.location
  service_plan_id        = azurerm_service_plan.uks-asp.id
  storage_account_name       = azurerm_storage_account.uks-sa1.name
  storage_account_access_key = azurerm_storage_account.uks-sa1.primary_access_key
  https_only = "true"
  site_config {
    #linux_fx_version = "Python|3.10"  # Specifies Python 3.10 as the runtime
  }
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "PYTHON_VERSION"           = "3.10"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    # Adding secrets from Key Vault
    "appsecret1" = "${azurerm_app_configuration_key.ck1.value}"
    "appsecret2" = "${azurerm_app_configuration_key.ck2.value})"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Owner = var.owner_tag
    Environment = var.environment_tag
    Health = var.health_tag
  }
}

resource "azurerm_function_app_function" "cosmos_trigger" {
  name            = "cosmosTrigger"
  function_app_id = azurerm_linux_function_app.uks-fa.id
  config_json     = <<EOT
{
  "bindings": [
    {
      "type": "cosmosDBTrigger",
      "name": "cosmosTrigger",
      "direction": "in",
      "connection": "${azurerm_cosmosdb_account.cs_cosmosdb.primary_key}",
      "databaseName": "super_secret_stuff",
      "collectionName": "users",
      "leaseCollectionName": "leases",
      "createLeaseCollectionIfNotExists": true
    },
    {
      "type": "serviceBus",
      "name": "serviceBusQueue",
      "direction": "out",
      "queueName": "task_processing",
      "connection": "${azurerm_servicebus_namespace.cs_servicebus_ns.default_primary_connection_string}"
    },
    {
      "type": "eventHub",
      "name": "eventHubOutput",
      "direction": "out",
      "eventHubName": "event_alerts",
      "connection": "${azurerm_eventhub_namespace.cs_eventhub_ns.default_primary_connection_string}"
    }
  ]
}
EOT
}

data "azurerm_linux_function_app" "uks-fa" {
  name = azurerm_linux_function_app.uks-fa.name
  resource_group_name = azurerm_linux_function_app.uks-fa.resource_group_name
}

/*******************************************************************************
                            CREATE COSMOS DB
*******************************************************************************/

resource "azurerm_cosmosdb_account" "cs_cosmosdb" {
  name                = "cosmos-${var.labname}-${var.uks}-01"
  location            = azurerm_resource_group.uks.location
  resource_group_name = azurerm_resource_group.uks.name
  offer_type          = "Standard"
  kind               = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  capabilities {
    name = "EnableServerless"
  }
  geo_location {
    location          = var.uks
    failover_priority = 0  # Must be (total regions - 1)
  }
}

resource "azurerm_cosmosdb_mongo_database" "databases" {
  for_each            = var.cosmos_databases
  name                = each.key
  resource_group_name = azurerm_resource_group.uks.name
  account_name        = azurerm_cosmosdb_account.cs_cosmosdb.name
}

resource "azurerm_cosmosdb_mongo_collection" "collections" {
  for_each            = local.flattened_collections 
  name                = each.value.collection_name
  database_name       = each.value.database_name
  resource_group_name = azurerm_resource_group.uks.name
  account_name        = azurerm_cosmosdb_account.cs_cosmosdb.name


  default_ttl_seconds = 777
  shard_key           = "uniqueKey"
  throughput          = 400

  index {
    keys   = ["_id"]
    unique = true
  }
}
/*******************************************************************************
                            CREATE EVENT HUB
*******************************************************************************/
resource "azurerm_eventhub_namespace" "cs_eventhub_ns" {
  name                = "eh-${var.labname}-${var.uks}-01"
  location            = azurerm_resource_group.uks.location
  resource_group_name = azurerm_resource_group.uks.name
  sku                 = "Standard"
  capacity            = 2
}

resource "azurerm_eventhub" "cs_event_hubs" {
  for_each            = var.event_hubs
  name                = each.key
  namespace_id      = azurerm_eventhub_namespace.cs_eventhub_ns.id
  partition_count     = each.value.partitions
  message_retention   = 1
}

/*******************************************************************************
                            CREATE SERVICE BUS
*******************************************************************************/
resource "azurerm_servicebus_namespace" "cs_servicebus_ns" {
  name                = "sb-${var.labname}-${var.uks}-01"
  location            = azurerm_resource_group.uks.location
  resource_group_name = azurerm_resource_group.uks.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "servicebus_queues" {
  for_each            = var.servicebus_queues
  name                = each.key
  namespace_id      = azurerm_servicebus_namespace.cs_servicebus_ns.id
  max_delivery_count  = each.value.max_delivery_count
}

/*******************************************************************************
                         CREATE MANAGED IDENTITY
*******************************************************************************/
resource "azurerm_user_assigned_identity" "uai-uks" {
  location            = azurerm_resource_group.uks.location
  name                = "UAI-${var.uks}"
  resource_group_name = azurerm_resource_group.uks.name
}

/*******************************************************************************
                         CREATE ROLE ASSIGNMENTS
*******************************************************************************/

resource "azurerm_role_assignment" "chaos_contributor" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "redis" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Redis Cache Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "domainname" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Classic Virtual Machine Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "vm_operator" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "akscluster" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "cosmosdb" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Cosmos DB Operator"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "autoscale" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Web Plan Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "key_vault" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Key Vault Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "nsg" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Network Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "fa" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Website Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "servicebus" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Azure Service Bus Data Owner"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "eventhub" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Azure Event Hubs Data Owner"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "loadtest" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Load Test Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "storage_blob_data_reader" {
  principal_id   = azurerm_user_assigned_identity.uai-uks.principal_id
  role_definition_name = "Storage Account Contributor"
  scope          = azurerm_resource_group.uks.id
}

resource "azurerm_role_assignment" "function_cosmosdb_role" {
  principal_id         = azurerm_linux_function_app.uks-fa.identity[0].principal_id
  role_definition_name = "Cosmos DB Account Contributor"
  scope               = azurerm_cosmosdb_account.cs_cosmosdb.id
}

resource "azurerm_role_assignment" "function_servicebus_role" {
  principal_id         = azurerm_linux_function_app.uks-fa.identity[0].principal_id
  role_definition_name = "Azure Service Bus Data Sender"
  scope               = azurerm_servicebus_namespace.cs_servicebus_ns.default_primary_connection_string
}

resource "azurerm_role_assignment" "function_eventhub_role" {
  principal_id         = azurerm_linux_function_app.uks-fa.identity[0].principal_id
  role_definition_name = "Azure Event Hubs Data Sender"
  scope               = azurerm_eventhub_namespace.cs_eventhub_ns.default_primary_connection_string
}

/*******************************************************************************
********************************************************************************
                          CHAOS STUDIO SECTION
/*******************************************************************************
*******************************************************************************/

/*******************************************************************************
                      REGISTER AZURE CHAOS PROVIDER
*******************************************************************************/

resource "null_resource" "register_chaos_provider" {
  provisioner "local-exec" {
    command = "az provider register --namespace Microsoft.Chaos"
  }

  # Ensure this runs only once by using a trigger
    triggers = {
    always_run = "${timestamp()}"
  }
}

/********************************************************************************
                            CREATE SERVICE PRINCIPAL
********************************************************************************/
resource "azuread_application" "cs_app" {
  display_name = "chaos-studio-sp"
}

resource "azuread_service_principal" "cs_sp" {
  client_id = azuread_application.cs_app.client_id
}

resource "azuread_service_principal_password" "cs_sp_pw" {
  service_principal_id = azuread_service_principal.cs_sp.id
  end_date             = local.expiration_date
}

output "client_id" {
  value = azuread_service_principal.cs_sp.client_id
}
output "client_secret" {
  value = azuread_service_principal_password.cs_sp_pw.value
  sensitive = true
}

/********************************************************************************
                           SERVICE PRINCIPAL ROLES
********************************************************************************/
resource "azurerm_role_assignment" "chaos_contributor_sp" {
  principal_id   = azuread_service_principal.cs_sp.object_id
  role_definition_name = "Chaos Studio Experiment Contributor"
  scope = azurerm_resource_group.uks.id
}

/********************************************************************************
                 ADD AGENT-BASED TARGETS TO CHAOS STUDIO
********************************************************************************/
resource "azurerm_chaos_studio_target" "tgt-uks_vmsa" {
  count               = var.servercounta
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_windows_virtual_machine.uks-vmsa[count.index].id
  target_type         = "Microsoft-VirtualMachine"
}

resource "azurerm_chaos_studio_target" "tgt-uks_vmsb" {
  count               = var.servercounta
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_windows_virtual_machine.uks-vmsb[count.index].id
  target_type         = "Microsoft-VirtualMachine"
}

resource "azurerm_chaos_studio_target" "tgt_uks_vmss" {
  count               = var.vmsscounta
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.uks-vmssa[count.index].id
  target_type         = "Microsoft-VirtualMachineScaleSet"
}

/********************************************************************************
                 ADD SERVICE-BASED TARGETS TO CHAOS STUDIO
********************************************************************************/
resource "azurerm_chaos_studio_target" "tgt-key_vault_target" {
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_key_vault.kv1.id
  target_type         = "Microsoft-KeyVault"
}

resource "azurerm_chaos_studio_target" "tgt-app_service_target" {
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_linux_function_app.uks-fa.id
  target_type         = "Microsoft-AppService"
}

resource "azurerm_chaos_studio_target" "tgt-servicebus" {
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_servicebus_namespace.cs_servicebus_ns.id
  target_type         = "Microsoft.ServiceBus"
}

resource "azurerm_chaos_studio_target" "tgt-cosmosdb" {
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_cosmosdb_account.cs_cosmosdb.id
  target_type         = "Microsoft.DocumentDB"
}

resource "azurerm_chaos_studio_target" "tgt-eventhub" {
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_eventhub_namespace.cs_eventhub_ns.id
  target_type         = "Microsoft.EventHub"
}

resource "azurerm_chaos_studio_target" "tgt-vms" {
  for_each            = data.azurerm_virtual_machine.availability_zone_vms
  location            = azurerm_resource_group.uks.location
  target_resource_id  = each.value.id
  target_type         = "Microsoft-VirtualMachine"
}

resource "azurerm_chaos_studio_target" "tgt-vmss" {
  for_each            = data.azurerm_virtual_machine_scale_set.availability_zone_vmss
  location            = azurerm_resource_group.uks.location
  target_resource_id  = each.value.id
  target_type         = "Microsoft-VirtualMachineScaleSet"
}

resource "azurerm_chaos_studio_target" "tgt-azurestorage" {
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_storage_account.chaos_exp_logs.id
  target_type         = "Microsoft.Storage"
}

resource "azurerm_chaos_studio_target" "tgt-uks-sa1" {
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_storage_account.uks-sa1.id
  target_type         = "Microsoft.Storage"
}

resource "azurerm_chaos_studio_target" "tgt-uks-vm1" {
  location            = azurerm_resource_group.uks.location
  target_resource_id  = azurerm_storage_account.uks-vm1.id
  target_type         = "Microsoft.Storage"
}

# resource "azurerm_chaos_studio_target" "tgt-sqldb" {
#   location            = azurerm_resource_group.uks.location
#   target_resource_id  = azurerm_mssql_database.sqldb.id
#   target_type         = "Microsoft.Sql"
# }

/********************************************************************************
                     ADD CHAOS STUDIO CAPABILITIES
********************************************************************************/

resource "azurerm_chaos_studio_capability" "cap_vm_shutdown" {
  for_each                = azurerm_chaos_studio_target.tgt-vms
  capability_type        = "Shutdown-1.0"
  chaos_studio_target_id = each.value.id
}

resource "azurerm_chaos_studio_capability" "cap_vm_redeploy" {
  for_each                = azurerm_chaos_studio_target.tgt-vms
  capability_type        = "Redeploy-1.0"
  chaos_studio_target_id = each.value.id
}

resource "azurerm_chaos_studio_capability" "cap_vmss_shutdown" {
  for_each                = azurerm_chaos_studio_target.tgt-vmss
  capability_type        = "Shutdown-1.0"
  chaos_studio_target_id = each.value.id
}

resource "azurerm_chaos_studio_capability" "cap_vmss_redeploy" {
  for_each                = azurerm_chaos_studio_target.tgt-vmss
  capability_type        = "Shutdown-2.0"
  chaos_studio_target_id = each.value.id
}

resource "azurerm_chaos_studio_capability" "cap_servicebus_latency" {
  capability_type        = "LatencyInjection-1.0"
  chaos_studio_target_id = azurerm_chaos_studio_target.tgt-servicebus.id
}

resource "azurerm_chaos_studio_capability" "cap_cosmosdb_failover" {
  capability_type        = "Failover-1.0"
  chaos_studio_target_id = azurerm_chaos_studio_target.tgt-cosmosdb.id
}

resource "azurerm_chaos_studio_capability" "cap_eventhub_throttle" {
  capability_type        = "Throttling-1.0"
  chaos_studio_target_id = azurerm_chaos_studio_target.tgt-eventhub.id
}

resource "azurerm_chaos_studio_capability" "cap_storage_unavailable" {
  capability_type        = "StorageUnavailable-1.0"
  chaos_studio_target_id = azurerm_chaos_studio_target.tgt-azurestorage.id
}

# resource "azurerm_chaos_studio_capability" "cap_sqldb_failover" {
#   capability_type        = "Failover-1.0"
#   chaos_studio_target_id = azurerm_chaos_studio_target.tgt-sqldb.id
# }

/********************************************************************************
                     ADD CHAOS STUDIO EXPERIMENTS SCENARIOS
********************************************************************************/

/********************************************************************************
Notes:
This entire section will be used to add in Real World scenarions based off PIR's
from Microsoft.

********************************************************************************/


/********************************************************************************
Notes:
This is going to replicate an Azure VM Disruption event from PIR 2LZ0-3DG,
dated 16-SEPT-23.

A power issue disrupted the scale units within a single Availability Zone within
East US, causing compute nodes to become unhealthy. While a majority rebooted
successfully, a subset did not. This led to failures and timeouts for Azure SQL
Databases, impacting several services including Virtual Machines, SQL DBs, and
Event Hubs.
********************************************************************************/

resource "azurerm_chaos_studio_experiment" "pir_2lz0_3dg" {
  name                = "pir-2lz0-3dg"
  resource_group_name = azurerm_resource_group.uks.name
  location            = azurerm_resource_group.uks.location

  identity {
    type = "SystemAssigned"
  }

  selectors {
    name                    = "Selector1"
    chaos_studio_target_ids = concat(
      [azurerm_chaos_studio_target.tgt-servicebus.id],
      [azurerm_chaos_studio_target.tgt-cosmosdb.id],
      [azurerm_chaos_studio_target.tgt-eventhub.id],
      values(azurerm_chaos_studio_target.tgt-vms)[*].id,
      values(azurerm_chaos_studio_target.tgt-vmss)[*].id
    )
  }

  steps {
    name = "VMDisruptionStep"
    branch {
      name = "Branch1"
      actions {
        urn           = join("",values(azurerm_chaos_studio_capability.cap_vm_shutdown)[*].urn)
        selector_name = "Selector1"
        parameters = {
          abruptShutdown = "false"
        }
        action_type = "continuous"
        duration    = "PT15M"
      }
      actions {
        urn = join("", values(azurerm_chaos_studio_capability.cap_vmss_shutdown)[*].urn)
        selector_name = "Selector1"
        parameters = {
          abruptShutdown = "false"
        }
        action_type = "continuous"
        duration    = "PT15M"
      }
    }
  }

  steps {
    name = "ServiceDisruptionStep"
    branch {
      name = "Branch2"
      actions {
        urn           = azurerm_chaos_studio_capability.cap_servicebus_latency.urn
        selector_name = "Selector1"
        parameters = {
          duration = "PT15M"
        }
        action_type = "continuous"
      }
      actions {
        urn           = azurerm_chaos_studio_capability.cap_eventhub_throttle.urn
        selector_name = "Selector1"
        parameters = {
          duration = "PT15M"
        }
        action_type = "continuous"
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "chaos_experiment_logging_ex1" {
  name                       = "pir-2lz03dg-chaos-experiment-logging"
  target_resource_id         = azurerm_chaos_studio_experiment.pir_2lz0_3dg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chaos_logging.id

  enabled_log {
    category = "ChaosEvents"
  }

  metric {
    category = "AllMetrics"
  }
  depends_on = [ azurerm_storage_account.chaos_exp_logs, azurerm_log_analytics_workspace.chaos_logging, azurerm_monitor_diagnostic_setting.chaos_exp_diag ]
}

/********************************************************************************
Notes:
This is going to replicate an Azure Outage event from PIR 1K90-N_8
dated 18-JUL-24.

A misconfiguration in Azure's Central US region disrupted backend communication
between compute and storage clusters, causing widespread service outages for
Azure Storage, SQL Database, Cosmos DB, Teams, and other services.
********************************************************************************/

resource "azurerm_chaos_studio_experiment" "pir_1k90_n8" {
  name                = "pir-1k90-n8"
  resource_group_name = azurerm_resource_group.uks.name
  location            = azurerm_resource_group.uks.location

  identity {
    type = "SystemAssigned"
  }

  selectors {
    name                    = "Selector1"
    chaos_studio_target_ids = concat(
      [azurerm_chaos_studio_target.tgt-servicebus.id],
      [azurerm_chaos_studio_target.tgt-cosmosdb.id],
      [azurerm_chaos_studio_target.tgt-eventhub.id],
      [azurerm_chaos_studio_target.tgt-azurestorage.id],
      # [azurerm_chaos_studio_target.tgt-sqldb.id],  # Uncomment when needed
      values(azurerm_chaos_studio_target.tgt-vms)[*].id,
      values(azurerm_chaos_studio_target.tgt-vmss)[*].id
    )
  }

  steps {
    name = "ComputeAndStorageDisruption"
    branch {
      name = "Branch1"
      actions {
        urn           = azurerm_chaos_studio_capability.cap_storage_unavailable.urn
        selector_name = "Selector1"
        parameters = {
          duration = "PT15M"
        }
        action_type = "continuous"
      }
      actions {
        urn           = azurerm_chaos_studio_capability.cap_cosmosdb_failover.urn
        selector_name = "Selector1"
        parameters = {
          duration = "PT15M"
        }
        action_type = "continuous"
      }
    }
  }

  steps {
    name = "ServiceDisruption"
    branch {
      name = "Branch2"
      actions {
        urn           = azurerm_chaos_studio_capability.cap_servicebus_latency.urn
        selector_name = "Selector1"
        parameters = {
          duration = "PT15M"
        }
        action_type = "continuous"
      }
      actions {
        urn           = azurerm_chaos_studio_capability.cap_eventhub_throttle.urn
        selector_name = "Selector1"
        parameters = {
          duration = "PT15M"
        }
        action_type = "continuous"
      }
    }
  }

  steps {
    name = "VMDisruption"
    branch {
      name = "Branch3"
      actions {
        urn           = join("",values(azurerm_chaos_studio_capability.cap_vm_shutdown)[*].urn)
        selector_name = "Selector1"
        parameters = {
          abruptShutdown = "false"
        }
        action_type = "continuous"
        duration    = "PT15M"
      }
      actions {
        urn = join("", values(azurerm_chaos_studio_capability.cap_vmss_shutdown)[*].urn)
        selector_name = "Selector1"
        parameters = {
          abruptShutdown = "false"
        }
        action_type = "continuous"
        duration    = "PT15M"
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "chaos_experiment_logging_ex2" {
  name                       = "pir-1k90n8-chaos-experiment-logging"
  target_resource_id         = azurerm_chaos_studio_experiment.pir_1k90_n8.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chaos_logging.id

  enabled_log {
    category = "ChaosEvents"
  }

  metric {
    category = "AllMetrics"
  }
  depends_on = [ azurerm_storage_account.chaos_exp_logs, azurerm_log_analytics_workspace.chaos_logging, azurerm_monitor_diagnostic_setting.chaos_exp_diag ]
}


/*******************************************************************************
                    CREATE CHAOS STUDIO LOGGING AND METRICS
*******************************************************************************/
resource "azurerm_storage_account" "chaos_exp_logs" {
  name                     = "ukschaosstoragelogs"
  resource_group_name       = azurerm_resource_group.uks.name
  location                 = azurerm_resource_group.uks.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_log_analytics_workspace" "chaos_logging" {
  name                = "uks-chaos-logs"
  resource_group_name = azurerm_resource_group.uks.name
  location            = azurerm_resource_group.uks.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "chaos_exp_diag" {
  name                       = "chaos-experiment-diagnostics"
  target_resource_id         = azurerm_storage_account.chaos_exp_logs.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chaos_logging.id

  enabled_log {
    category = "ChaosEvents"
  }
}

/********************************************************************************
                     ADD CHAOS STUDIO EXPERIMENTS (UK South Outages)
********************************************************************************/

/********************************************************************************
Notes:
This section will be used to create smaller issues based within UK South and
Global Resources designed to test failovers and outages. This will include things
like AAD outages, App Service Plan and VM Resource failures, Zonal outages, etc.

I will need to be able to gather resources dynamically, and create scenarios
that will be randomised (ie random availability zone failures, VM failures, etc)
so that no one scenario will be the same. This will be created within Azure and
can be extracted via ARM template for future use if needed.

********************************************************************************/
#