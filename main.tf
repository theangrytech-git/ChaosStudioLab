/*******************************************************************************

PROJECT NAME:       AZURE-CHAOS-STUDIO
CREATED BY:         THEANGRYTECH-GIT
REPO:
DESCRIPTION:        This project sets up an Azure environment in UK South and
will deploy in each region: VM's in an Availability Set,
VM Scale Sets, NSG's, Key Vaults, Traffic Manager, Firewall, Route Table,
Storage Accounts, Load Balancers, Application Insights, Managed Identities,
Function Apps, App Service Plans, and some Chaos Studio experiments.

*******************************************************************************/

/*******************************************************************************
Notes:
Chaos Studio is only available in select regions:
https://azure.microsoft.com/en-gb/explore/global-infrastructure/products-by-region/?products=chaos-studio#products-by-region_tab5
My environment is only available in UK South - to use this environment in
another Region, please either replace any references to UK South (UKS) to a
region that you want to use that's supported by Chaos Studio, or copy the
blocks and adjust the TFVARS file to include your additional Region.
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
value = data.azurerm_subscription.current.display_name
}
data "azurerm_client_config" "current" {}
locals {
  days_to_hours   = var.days_to_expire * 24
  expiration_date = timeadd(
    formatdate("YYYY-MM-DD'T'HH:mm:ssZ", timestamp()),
    "${local.days_to_hours}h"
  )
  nic_ids_a = [for m in module.vm_uks_1 : m.nic_id]
  nic_ids_b = [for m in module.vm_uks_2 : m.nic_id]
  ipconfs_a = try([for m in module.vm_uks_1 : m.ip_configuration_name], [])
  ipconfs_b = try([for m in module.vm_uks_2 : m.ip_configuration_name], [])

  nic_assoc_a = [
    for i, id in local.nic_ids_a : {
      nic_id                = id
      ip_configuration_name = try(local.ipconfs_a[i], "ipconfig1") # fallback if missing
    }
  ]
  nic_assoc_b = [
    for i, id in local.nic_ids_b : {
      nic_id                = id
      ip_configuration_name = try(local.ipconfs_b[i], "ipconfig1")
    }
  ]
  chaos_location_1 = module.rg_uks_1.location
  chaos_location_2 = module.rg_uks_2.location
  chaos_location_3 = module.rg_uks_3.location
  chaos_vm_targets = merge(
    { for idx, m in module.vm_uks_1 : "vmsa_${idx}" => m.vm_id },
    { for idx, m in module.vm_uks_2 : "vmsb_${idx}" => m.vm_id }
  )
  chaos_vmss_targets = {
    "vmss_0" = module.vmss_uks_1.id
  }
  chaos_fa_targets = {
    fa1 = module.fa_linux_1.id
    fa2 = module.fa_linux_2.id
    fa3 = module.fa_linux_3.id
  }

  storage_targets = {
    sa_gen = module.sa_uks_general.id
    sa_diag = module.sa_uks_diag.id
    sa_fa = module.sa_uks_fa.id
  }
  chaos_experiment_principals = {
    pir_2lz0_3dg = azurerm_chaos_studio_experiment.pir_2lz0_3dg.identity[0].principal_id
    pir_1k90_n8  = azurerm_chaos_studio_experiment.pir_1k90_n8.identity[0].principal_id
  }
  chaos_scopes = {
    servicebus = module.servicebus.namespace_id
    eventhub = module.eventhub_ns.id
    cosmos     = module.cosmosdb.id

    vms = concat(
      [for m in module.vm_uks_1 : m.vm_id],
      [for m in module.vm_uks_2 : m.vm_id]
    )
    vmss = [
      module.vmss_uks_1.id
    ]
  }
}

/*******************************************************************************
                         CREATE RANDOM GENERATOR
*******************************************************************************/
resource "random_string" "random" {
  length           = 3
  numeric = true
  special          = false
  lower = true
  upper = false
}

resource "random_string" "number" {
  length           = 3
  numeric = true
  special          = false
  lower = false
  upper = false
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
module "rg_uks_1" {
  source   = "./modules/resource_group"
  name     = "rg-uks-cs-main-01"
  location = "uksouth"
  tags = {
    environment = "training"
  }
}

module "rg_uks_2" {
  source   = "./modules/resource_group"
  name     = "rg-uks-cs-compute-01"
  location = "uksouth"
  tags = {
    environment = "training"
  }
}

module "rg_uks_3" {
  source   = "./modules/resource_group"
  name     = "rg-uks-cs-config-01"
  location = "uksouth"
  tags = {
    environment = "training"
  }
}


/*******************************************************************************
                         CREATE VIRTUAL NETWORKS
*******************************************************************************/
module "vnet_uks_main" {
  source              = "./modules/vnet"
  name                = "vnet-uks-main"
  location            = "uksouth"
  resource_group_name = module.rg_uks_1.name
  address_space       = ["10.150.0.0/19"]

  subnets = [
    {
      name             = "sn-uks-hub1-host-01"
      address_prefixes = ["10.150.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    },
    {
      name             = "sn-uks-hub1-lb-01"
      address_prefixes = ["10.150.2.0/24"]
      service_endpoints = []
    },
    {
      name             = "AzureFirewallSubnet"
      address_prefixes = ["10.150.3.0/24"]
      service_endpoints = []
    },
    {
      name             = "AzureFirewallManagementSubnet"
      address_prefixes = ["10.150.4.0/24"]
      service_endpoints = []
    },
  ]

  tags = {
    environment = "training"
  }
}

/*******************************************************************************
                         CREATE NETWORK SECURITY GROUPS
*******************************************************************************/
module "nsg_uks_1" {
  source              = "./modules/nsg"
  name                = "nsg-snet-uks-vnet-hub-01"
  location            = module.rg_uks_1.location
  resource_group_name = module.rg_uks_1.name

  subnet_ids = {
    "sn-uks-hub1-host-01" = module.vnet_uks_main.subnet_ids["sn-uks-hub1-host-01"]
  }

  security_rules = [
    {
      name                       = "AllowHTTP"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowSSH"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowRDP"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHTTPOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]
  tags = {
    environment = "training"
    owner       = "op9"
  }
}

# resource "azurerm_subnet_network_security_group_association" "uks-hub" {
#   subnet_id                 = module.vnet_uks_main.subnet_ids["sn-uks-hub1-host-01"]
#   network_security_group_id = module.nsg_uks_1.id
# }
# /*******************************************************************************
#                          CREATE FIREWALL
# *******************************************************************************/
module "firewall_uks" {
  source              = "./modules/firewall"
  name                = "fw-uks-01"
  location            = module.rg_uks_1.location
  resource_group_name = module.rg_uks_1.name

  ip_configurations = [
    {
      name      = "configuration"
      subnet_id = module.vnet_uks_main.subnet_ids["AzureFirewallSubnet"]
    }
  ]

  network_rule_collections = {
    allow-internal = {
      name     = "AllowInternal"
      priority = 100
      action   = "Allow"
      rules = [
        {
          name                  = "AllowAllInternal"
          source_addresses      = ["10.150.0.0/19"]
          destination_addresses = ["10.150.0.0/19"]
          destination_ports     = ["*"]
          protocols             = ["TCP", "UDP"]
        }
      ]
    }
  }

  application_rule_collections = {
    allow-web = {
      name     = "AllowWeb"
      priority = 200
      action   = "Allow"
      rules = [
        {
          name             = "AllowMicrosoft"
          source_addresses = ["10.150.0.0/19"]
          target_fqdns     = ["*.microsoft.com"]
          protocols = [
            { type = "Http",  port = 80 },
            { type = "Https", port = 443 }
          ]
        }
      ]
    }
  }

  nat_rule_collections = {
    rdp-nat = {
      name     = "AllowRDP"
      priority = 300
      action   = "Dnat"
      rules = [
        {
          name                 = "RDP"
          source_addresses     = ["*"]
          # destination_addresses omitted on purpose > module fills with its PIP
          destination_ports    = ["3389"]
          translated_address   = "10.150.1.4"
          translated_port      = "3389"
          protocols            = ["TCP"]
        }
      ]
    }
  }
}

# /*******************************************************************************
#                          CREATE ROUTE TABLES
# *******************************************************************************/
module "route_table_uks" {
  source              = "./modules/route_table"
  name                = "rtbl-uks-01"
  location            = module.rg_uks_1.location
  resource_group_name = module.rg_uks_1.name

  routes = [
    {
      name                   = "route-default"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall_uks.private_ip_address
    }
  ]

  subnet_ids = {
    "sn-uks-hub1-host-01" = module.vnet_uks_main.subnet_ids["sn-uks-hub1-host-01"]
  }

  tags = {
    environment = "training"
  }
}

# /*******************************************************************************
#                          CREATE KEY VAULT
# *******************************************************************************/
module "keyvault_1" {
  source              = "./modules/keyvault"
  name                = "kv-uks-${random_string.random.result}"
  location            = module.rg_uks_3.location
  resource_group_name = module.rg_uks_3.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = true

  access_policies = [
    {
      tenant_id               = data.azurerm_client_config.current.tenant_id
      object_id               = data.azurerm_client_config.current.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "Set", "List"]
      certificate_permissions = []
      storage_permissions     = []
    }
  ]

  tags = {
    environment = "training"
  }
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = module.keyvault_1.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_crypto_officer" {
  scope                = module.keyvault_1.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# /*******************************************************************************
#                          CREATE KEY VAULT SECRETS
# *******************************************************************************/

resource "azurerm_key_vault_secret" "vmpassword1" {
  depends_on   = [module.keyvault_1,azurerm_role_assignment.kv_secrets_officer]
  name         = "vmpass1-${random_string.random.result}"
  value        = random_password.vmpassword.result
  key_vault_id = module.keyvault_1.id
  content_type = "uks VM Password Secret"
  expiration_date = local.expiration_date
}

resource "azurerm_key_vault_secret" "vmpassword2" {
  depends_on   = [module.keyvault_1,azurerm_role_assignment.kv_secrets_officer]
  name         = "vmpass2-${random_string.random.result}"
  value        = random_password.vmpassword.result
  key_vault_id = module.keyvault_1.id
  content_type = "uks VM Password Secret"
  expiration_date = local.expiration_date
}

# /*******************************************************************************
#                       CREATE PRIVATE ENDPOINT FOR KV
# *******************************************************************************/
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-${module.keyvault_1.name}"
  location            = module.rg_uks_3.location
  resource_group_name = module.rg_uks_3.name
  subnet_id           = module.vnet_uks_main.subnet_ids["sn-uks-hub1-host-01"]

  private_service_connection {
    name                           = "psc-${module.keyvault_1.name}"
    private_connection_resource_id = module.keyvault_1.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  depends_on = [module.keyvault_1]
}

# /*******************************************************************************
#                          CREATE APP CONFIGS
# *******************************************************************************/
module "appconfig_uks" {
  source              = "./modules/appconfig"
  name                = "appcfg-uks-${random_string.random.result}-01"
  location            = module.rg_uks_1.location
  resource_group_name = module.rg_uks_1.name
  sku                 = "standard"
  tags = {
    Environment = "training"
    Health      = "healthy"
  }

  # Key-values using generated VM password
  key_values = {
    "appconfig1" = {
      value = random_password.vmpassword.result
    },
    "appconfig2" = {
      value = random_password.vmpassword.result
    }
  }
  principal_id = data.azurerm_client_config.current.object_id
  depends_on = [module.keyvault_1]
}

# resource "azurerm_role_assignment" "appconf_dataowner" {
#   scope                = module.appconfig_uks.id
#   role_definition_name = "App Configuration Data Owner"
#   principal_id         = data.azurerm_client_config.current.object_id
# }

# /*******************************************************************************
#                          CREATE AVAILABILITY SETS
# *******************************************************************************/
resource "azurerm_availability_set" "uks-asa" {
  name                        = "as-uks-a"
  location                    = module.rg_uks_2.location
  resource_group_name         = module.rg_uks_2.name
  platform_fault_domain_count = 2
  tags = {
    environment = "training"
  }
}

# /*******************************************************************************
#                     CREATE VIRTUAL MACHINE SCALE SETS
# *******************************************************************************/
module "vmss_uks_1" {
  source              = "./modules/vmss_win"
  name                = "uks-${random_string.random.result}"
  location            = module.rg_uks_2.location
  resource_group_name = module.rg_uks_2.name

  vm_sku          = "Standard_B1ms"
  instance_count  = 5
  admin_username  = "azureadmin"
  admin_password  = azurerm_key_vault_secret.vmpassword1.value
  computer_name_prefix = "winvmss"

  subnet_id = module.vnet_uks_main.subnet_ids["sn-uks-hub1-host-01"]

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = "training"
  }

  depends_on = [azurerm_key_vault_secret.vmpassword1]
}

# resource "azurerm_virtual_machine_scale_set_extension" "iis_install_vmss" {
#   name                         = "iis-on-vmss"
#   virtual_machine_scale_set_id = module.vmss_uks_1.id  # <-- your module must output this
#   publisher                    = "Microsoft.Compute"
#   type                         = "CustomScriptExtension"
#   type_handler_version         = "1.10"
#   auto_upgrade_minor_version = true

#   settings = jsonencode({
#     commandToExecute = "powershell Add-WindowsFeature Web-Server"
#   })
#   depends_on = [module.vmss_uks_1]
# }

# /*******************************************************************************
#                          CREATE VIRTUAL MACHINES
# *******************************************************************************/
# /***
# need to add in a custom ext script to install Hyper-V, IIS, and potentially create a VM within HyperV for testing.
# ***/

module "vm_uks_1" {
  source              = "./modules/vm_win"
  count               = var.servercounta
  name                = "vm-uks-a-${count.index}-${random_string.random.result}"
  location            = module.rg_uks_2.location
  resource_group_name = module.rg_uks_2.name
  vm_size             = "Standard_D2s_v4"

  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword1.value
  availability_set_id = azurerm_availability_set.uks-asa.id
  subnet_id           = module.vnet_uks_main.subnet_ids["sn-uks-hub1-host-01"]

  public_ip_enabled = false

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = "training"
  }

  depends_on = [azurerm_key_vault_secret.vmpassword1]
}
module "vm_uks_2" {
  source              = "./modules/vm_win"
  count               = var.servercountb
  name                = "vm-uks-b-${count.index}-${random_string.random.result}"
  location            = module.rg_uks_2.location
  resource_group_name = module.rg_uks_2.name
  vm_size             = "Standard_B1ms"

  admin_username      = "azureadmin"
  admin_password      = azurerm_key_vault_secret.vmpassword2.value
  availability_set_id = azurerm_availability_set.uks-asa.id
  subnet_id           = module.vnet_uks_main.subnet_ids["sn-uks-hub1-host-01"]

  public_ip_enabled = false

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = {
  environment = "training"
  }

  depends_on = [azurerm_key_vault_secret.vmpassword2]
}

# /*******************************************************************************
#                          CREATE FIREWALLS
# *******************************************************************************/


# /*******************************************************************************
#                           CREATE FIREWALL POLICY
# *******************************************************************************/


# /*******************************************************************************
#                          CREATE LOAD BALANCERS
# *******************************************************************************/
module "uks_lb_1" {
  source              = "./modules/load_balancer"

  location            = module.rg_uks_2.location
  resource_group_name = module.rg_uks_2.name
  subnet_id           = module.vnet_uks_main.subnet_ids["sn-uks-hub1-lb-01"]

  vnet_cidr           = module.vnet_uks_main.subnet_prefixes["sn-uks-hub1-lb-01"][0]
  lb_offset           = 20

  lb_name        = "lb-uks-int-01"
  frontend_name  = "fip-lb-uks-int-01"

  probe_name         = "http-probe"
  probe_protocol     = "Http"
  probe_port         = 80
  probe_interval     = 60
  probe_request_path = "/"

  backend_pool_name = "BackEndAddressPool"

  rule_name       = "LBRule"
  rule_protocol   = "Tcp"
  frontend_port   = 80
  backend_port    = 80

  nic_associations = concat(local.nic_assoc_a, local.nic_assoc_b)
}

# /*******************************************************************************
#                          CREATE TRAFFIC MANAGER
# *******************************************************************************/
module "tm_profile" {
  source = "./modules/traffic_mgr"

  profile_name         = "tm-uks-${random_string.random.result}"
  resource_group_name  = module.rg_uks_3.name
  traffic_routing_method = "Weighted"

  # DNS label:"<labname>-ab12.trafficmanager.net"
  relative_name = "dns-uks-${random_string.random.result}"
  ttl           = 100

  monitor_protocol                     = "HTTP"
  monitor_port                         = 80
  monitor_path                         = "/"
  monitor_interval_in_seconds          = 30
  monitor_timeout_in_seconds           = 10
  monitor_tolerated_number_of_failures = 3

  tags = {
    Environment = "training"
  }

  create_public_ip       = true
  public_ip_name         = "pip-uks-fw"
  public_ip_location     = "uksouth"
  public_ip_sku          = "Standard"
  public_ip_allocation   = "Static"
  public_ip_zones        = null
  public_ip_dns_label  = "fw-uks-${lower(random_string.random.result)}"

  managed_endpoint_name   = "tfm-uks-endpoint"
  managed_endpoint_weight = 100

  azure_endpoints = []
}

output "tm_fqdn"       { value = module.tm_profile.fqdn }
output "tm_public_ip"  { value = module.tm_profile.public_ip_address }

# /*******************************************************************************
#                          CREATE STORAGE ACCOUNTS
# *******************************************************************************/

module "sa_uks_general" {
  source              = "./modules/storage"
  name                = "sauksgeneral${random_string.number.result}"
  resource_group_name = module.rg_uks_1.name
  location            = module.rg_uks_1.location

  account_tier         = "Standard"
  replication_type     = "GRS"
  account_kind         = "StorageV2"
  access_tier          = "Hot"

  min_tls_version                   = "TLS1_2"
  enable_https_traffic_only         = true
  public_network_access_enabled     = true
  shared_access_key_enabled         = true
  infrastructure_encryption_enabled = true

  blob_soft_delete_days             = 7
  container_delete_retention_days   = 7
  versioning_enabled                = true
  change_feed_enabled               = true

  network_default_action = "Deny"
  network_bypass         = ["AzureServices"]
  ip_rules               = []                       # add admin IPs here if needed
  subnet_ids             = [
    module.vnet_uks_main.subnet_ids["sn-uks-hub1-host-01"]
  ]

  tags = {
    Environment = "training"
  }
}

module "sa_uks_diag" {
  source              = "./modules/storage"
  name                = "savmdiag${random_string.number.result}"
  resource_group_name = module.rg_uks_1.name
  location            = module.rg_uks_1.location

  account_tier         = "Standard"
  replication_type     = "GRS"
  account_kind         = "StorageV2"
  access_tier          = "Hot"

  min_tls_version                   = "TLS1_2"
  enable_https_traffic_only         = true
  public_network_access_enabled     = false
  shared_access_key_enabled         = true
  infrastructure_encryption_enabled = true

  blob_soft_delete_days             = 7
  container_delete_retention_days   = 7
  versioning_enabled                = true
  change_feed_enabled               = true

  network_default_action = "Deny"
  network_bypass         = ["AzureServices"]
  ip_rules               = []                       # add admin IPs here if needed
  subnet_ids             = []                       # or private endpoints VNets (if you go that route)

  tags = {
    Environment = "training"
  }
}

module "sa_uks_fa" {
  source              = "./modules/storage"
  name                = "safalin${random_string.number.result}"
  resource_group_name = module.rg_uks_1.name
  location            = module.rg_uks_1.location

  account_tier         = "Standard"
  replication_type     = "GRS"
  account_kind         = "StorageV2"
  access_tier          = "Hot"

  # security defaults
  min_tls_version                   = "TLS1_2"
  enable_https_traffic_only         = true
  public_network_access_enabled     = false
  shared_access_key_enabled         = true
  infrastructure_encryption_enabled = true

  # blob hygiene
  blob_soft_delete_days             = 7
  container_delete_retention_days   = 7
  versioning_enabled                = true
  change_feed_enabled               = true

  # network
  network_default_action = "Deny"
  network_bypass         = ["AzureServices"]
  ip_rules               = []                       # add admin IPs here if needed
  subnet_ids             = []                       # or private endpoints VNets (if you go that route)

  tags = {
    Environment = "training"
  }
}

# /*******************************************************************************
#                          CREATE APP SERVICE PLAN
# *******************************************************************************/

module "uks_asp" {
  source              = "./modules/asp"
  name                = "asp-uks-S1-${random_string.random.result}-01"
  resource_group_name = module.rg_uks_2.name
  location            = module.rg_uks_2.location

  os_type  = "Linux"
  sku_name = "S1"

  tags = {
    Environment  = "training"
  }
}

# /*******************************************************************************
#                          CREATE FUNCTION APP
# *******************************************************************************/
module "fa_linux_1" {
  source = "./modules/fa_linux"

  name                 = "fa-uks-fa01"
  location             = module.rg_uks_2.location
  resource_group_name  = module.rg_uks_2.name
  app_service_plan_id  = module.uks_asp.id
  storage_account_name = module.sa_uks_fa.name
  storage_account_access_key = module.sa_uks_fa.primary_access_key

  runtime          = "python"
  runtime_version  = "3.10"

  https_only                    = true
  public_network_access_enabled = false
  identity_type                 = "SystemAssigned"

  app_settings = {
    # Worker/runtime
    "PYTHON_VERSION"           = "3.10"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "appconfig1" = module.appconfig_uks.key_values["appconfig1"].value
    "appsecret1" = azurerm_key_vault_secret.vmpassword1.value #Need to add this into KV
    "appsecret2" = azurerm_key_vault_secret.vmpassword2.value #Need to add this into KV
  }

  tags = {
    Environment  = "training"
  }
}

module "fa_linux_2" {
  source = "./modules/fa_linux"

  name                 = "fa-uks-fa02"
  location             = module.rg_uks_2.location
  resource_group_name  = module.rg_uks_2.name
  app_service_plan_id  = module.uks_asp.id
  storage_account_name = module.sa_uks_fa.name
  storage_account_access_key = module.sa_uks_fa.primary_access_key

  runtime          = "python"
  runtime_version  = "3.10"

  https_only                    = true
  public_network_access_enabled = false
  identity_type                 = "SystemAssigned"

  app_settings = {
    # Worker/runtime
    "PYTHON_VERSION"           = "3.10"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "appconfig1" = module.appconfig_uks.key_values["appconfig1"].value
    "appsecret1" = azurerm_key_vault_secret.vmpassword1.value #Need to add this into KV
    "appsecret2" = azurerm_key_vault_secret.vmpassword2.value #Need to add this into KV
  }

  tags = {
    Environment  = "training"
  }
}

module "fa_linux_3" {
  source = "./modules/fa_linux"

  name                 = "fa-uks-fa03"
  location             = module.rg_uks_2.location
  resource_group_name  = module.rg_uks_2.name
  app_service_plan_id  = module.uks_asp.id
  storage_account_name = module.sa_uks_fa.name
  storage_account_access_key = module.sa_uks_fa.primary_access_key

  runtime          = "python"
  runtime_version  = "3.10"

  https_only                    = true
  public_network_access_enabled = false
  identity_type                 = "SystemAssigned"

  app_settings = {
    # Worker/runtime
    "PYTHON_VERSION"           = "3.10"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "appconfig1" = module.appconfig_uks.key_values["appconfig1"].value
    "appsecret1" = azurerm_key_vault_secret.vmpassword1.value #Need to add this into KV
    "appsecret2" = azurerm_key_vault_secret.vmpassword2.value #Need to add this into KV
  }

  tags = {
    Environment  = "training"
  }
}

# /*******************************************************************************
#                             CREATE SERVICE BUS
# *******************************************************************************/
module "servicebus" {
  source = "./modules/servicebus"

  name                = "cs-servicebus-ns-${random_string.number.result}"
  location            = module.rg_uks_1.location
  resource_group_name = module.rg_uks_1.name
  sku                 = "Standard"

  public_network_access_enabled = false
  minimum_tls_version           = "1.2"

  identity_type = "SystemAssigned"

  queues = [
    { name = "ingress_queue", partitioning_enabled = true },
    { name = "egress_queue",  partitioning_enabled = true }
  ]

  topics = [
    { name = "updates_topic", partitioning_enabled = true }
  ]

  tags = {
    Environment = "training"
  }
}

# /*******************************************************************************
#                             CREATE COSMOS_DB
# *******************************************************************************/
module "cosmosdb" {
  source = "./modules/cosmosdb"

  account_name                = "db-uks-cosmosdb-${random_string.number.result}"
  location            = module.rg_uks_1.location
  resource_group_name = module.rg_uks_1.name
  kind                = "GlobalDocumentDB"

  public_network_access_enabled       = false
  is_virtual_network_filter_enabled   = true

  consistency_level = "Session"

  geo_locations = [
    {
      location          = module.rg_uks_1.location
      failover_priority = 0
    },
    {
      location          = "North Europe"
      failover_priority = 1
    }
  ]

  local_authentication_disabled = true

  key_vault_key_id = join("/", slice(split("/", azurerm_key_vault_key.cosmosdb_key.id), 0, 5))

  tags = {
    Environment = "training"
  }
  depends_on = [
    azurerm_key_vault_key.cosmosdb_key,
    azurerm_role_assignment.kv_crypto_user_cosmosdb,
  ]
}

resource "azurerm_key_vault_key" "cosmosdb_key" {
  depends_on = [module.keyvault_1,azurerm_role_assignment.kv_crypto_officer]
  name         = "cosmos-cmk-${random_string.random.result}"
  key_vault_id = module.keyvault_1.id
  # checkov:skip=CKV_AZURE_112 reason="Not using HSM-backed key by design"
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]
  expiration_date = local.expiration_date
  lifecycle {
    # prevent_destroy = true
    ignore_changes = [
      expiration_date,
    ]
  }
}

resource "azurerm_role_assignment" "kv_crypto_user_cosmosdb" {
  scope                = module.keyvault_1.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = "66aa1adf-65c7-4a4b-bf6a-84ef5852fb03"
}

# /*******************************************************************************
#                             CREATE EVENT HUB
# *******************************************************************************/
module "eventhub_ns" {
  source              = "./modules/eventhub"
  name                = "eh-uks-namespace-01"
  location            = module.rg_uks_2.location
  resource_group_name = module.rg_uks_2.name

  sku      = "Standard"
  capacity = 1

  kafka_enabled            = false
  auto_inflate_enabled     = true
  maximum_throughput_units = 20
  public_network_access_enabled = true
  minimum_tls_version      = "1.2"

  tags = {
    env = "training"
  }
}

output "eh_ns_primary_cs" {
  value     = module.eventhub_ns.namespace_primary_connection_string
  sensitive = true
}

# /*******************************************************************************
#                           CREATE LOG ANALYTICS
# *******************************************************************************/
module "log_analytics" {
  source              = "./modules/log_analytics"
  name                = "logging"
  location            = module.rg_uks_1.location
  resource_group_name = module.rg_uks_1.name

  sku               = "PerGB2018"
  retention_in_days = 30
  daily_quota_gb    = 0.1

  tags = {
    env = "training"
  }
}

module "la_diag" {
  source = "./modules/la_diag"

  log_analytics_workspace_id = module.log_analytics.id

  default_log_categories    = []
  default_metric_categories = ["AllMetrics"]

  diagnostic_map = merge(

    {
      cosmosdb = {
        name               = "cosmosdb-diag"
        target_resource_id = module.cosmosdb.id
        log_categories     = ["DataPlaneRequests"]
        metric_categories  = ["AllMetrics"]
      }
    },

    {
      servicebus = {
        name               = "servicebus-diag-01"
        target_resource_id = module.servicebus.id
        log_categories     = ["OperationalLogs"]
        metric_categories  = ["AllMetrics"]
      }
    },

    {
      eventhub = {
        name               = "eventhub-diag-01"
        target_resource_id = module.eventhub_ns.id
        log_categories     = ["OperationalLogs"]
        metric_categories  = ["AllMetrics"]
      }
    },

    {
      keyvault = {
        name               = "diag-kv"
        target_resource_id = module.keyvault_1.id
        log_categories     = ["AuditEvent"]
        metric_categories  = ["AllMetrics"]
      }
    },

    {
      functionapp1 = {
        name               = "diag-fa-1"
        target_resource_id = module.fa_linux_1.id
        metric_categories  = ["AllMetrics"]
      }
    },
    {
      functionapp2 = {
        name               = "diag-fa-2"
        target_resource_id = module.fa_linux_2.id
        metric_categories  = ["AllMetrics"]
      }
    },
    {
      functionapp3 = {
        name               = "diag-fa-3"
        target_resource_id = module.fa_linux_3.id
        metric_categories  = ["AllMetrics"]
      }
    },

    {
      storagegen = {
        name               = "diag-storage-01"
        target_resource_id = module.sa_uks_general.id
        metric_categories  = ["AllMetrics"]
      },
      storagediag = {
        name               = "diag-storage-01"
        target_resource_id = module.sa_uks_diag.id
        metric_categories  = ["AllMetrics"]
      },
      storagefa = {
        name               = "diag-storage-01"
        target_resource_id = module.sa_uks_fa.id
        metric_categories  = ["AllMetrics"]
      }
    },

    {
    for k, vm_id in merge(
      { for idx, m in module.vm_uks_1 : "vmsa_${idx}" => m.vm_id },
      { for idx, m in module.vm_uks_2 : "vmsb_${idx}" => m.vm_id }
    ) :
    k => {
      name               = "diag-${k}"
      target_resource_id = vm_id
      metric_categories  = ["AllMetrics"]
      }
    },

    {
      for k, vmss in { "vmss_0" = module.vmss_uks_1.id } :
      k => {
        name               = "diag-${k}"
        target_resource_id = vmss
        metric_categories  = ["AllMetrics"]
      }
    }
  )
}

module "chaos" {
  source              = "./modules/log_analytics"
  name                = "chaos-logging"
  location            = module.rg_uks_1.location
  resource_group_name = module.rg_uks_1.name

  sku               = "PerGB2018"
  retention_in_days = 30
  daily_quota_gb    = 0.1

  tags = {
    env = "training"
  }
}


# /*******************************************************************************
# ********************************************************************************
#                           CHAOS STUDIO SECTION
# /*******************************************************************************
# *******************************************************************************/

# /*******************************************************************************
#                       REGISTER AZURE CHAOS PROVIDER
# *******************************************************************************/

# # This is handled in the ADO pipeline

# /********************************************************************************
#                  ADD AGENT-BASED TARGETS TO CHAOS STUDIO
# ********************************************************************************/


# /********************************************************************************
#                  ADD SERVICE-BASED TARGETS TO CHAOS STUDIO
# ********************************************************************************/
resource "azurerm_chaos_studio_target" "tgt-key_vault_target" {
  location            = local.chaos_location_3
  target_resource_id  = module.keyvault_1.id
  target_type         = "Microsoft-KeyVault"
}

resource "azurerm_chaos_studio_target" "tgt-servicebus" {
  location            = local.chaos_location_1
  target_resource_id  = module.servicebus.id
  target_type         = "Microsoft-ServiceBus"
}

resource "azurerm_chaos_studio_target" "tgt-cosmosdb" {
  location            = local.chaos_location_1
  target_resource_id  = module.cosmosdb.id
  target_type         = "Microsoft-CosmosDB"
}

resource "azurerm_chaos_studio_target" "tgt-eventhub" {
  location            = local.chaos_location_2
  target_resource_id  = module.eventhub_ns.id
  target_type         = "Microsoft-EventHub"
}

resource "azurerm_chaos_studio_target" "tgt-vms" {
  for_each           = local.chaos_vm_targets
  location           = local.chaos_location_2
  target_resource_id = each.value
  target_type          = "Microsoft-VirtualMachine"
}

resource "azurerm_chaos_studio_target" "tgt-vmss" {
  for_each           = local.chaos_vmss_targets
  location           = local.chaos_location_2
  target_resource_id = each.value
  target_type        = "Microsoft-VirtualMachineScaleSet"
}

resource "azurerm_chaos_studio_target" "nsg_uks_1" {
  location           = module.rg_uks_1.location
  target_resource_id = module.nsg_uks_1.id
  target_type        = "Microsoft-NetworkSecurityGroup"
}

resource "azurerm_chaos_studio_target" "tgt_sa_all" {
  for_each           = local.storage_targets
  location           = module.rg_uks_1.location
  target_resource_id = each.value
  target_type        = "Microsoft-StorageAccount"
}

resource "azurerm_chaos_studio_target" "tgt_appservice" {
  for_each           = local.chaos_fa_targets
  location           = local.chaos_location_2
  target_resource_id = each.value
  target_type        = "Microsoft-AppService"
}

# /********************************************************************************
#                      ADD CHAOS STUDIO CAPABILITIES
# ********************************************************************************/

resource "azurerm_chaos_studio_capability" "cap_vm_shutdown" {
  for_each           = azurerm_chaos_studio_target.tgt-vms
  capability_type        = "Shutdown-1.0"
  chaos_studio_target_id = each.value.id
}

resource "azurerm_chaos_studio_capability" "cap_vm_redeploy" {
  for_each           = azurerm_chaos_studio_target.tgt-vms
  capability_type        = "Redeploy-1.0"
  chaos_studio_target_id = each.value.id
}

resource "azurerm_chaos_studio_capability" "cap_vmss_shutdown" {
  for_each                = azurerm_chaos_studio_target.tgt-vmss
  capability_type        = "Shutdown-2.0"
  chaos_studio_target_id = each.value.id
}

resource "azurerm_chaos_studio_capability" "cap_servicebus_queue_state" {
  capability_type        = "ChangeQueueState-1.0" #Latency isn't available for Sb - setting this will mimic queues being unavailable
  chaos_studio_target_id = azurerm_chaos_studio_target.tgt-servicebus.id
}

resource "azurerm_chaos_studio_capability" "cap_appsvc_latency" {
  for_each           = azurerm_chaos_studio_target.tgt_appservice
  capability_type         = "Stop-1.0"
  chaos_studio_target_id = each.value.id
}

resource "azurerm_chaos_studio_capability" "cap_cosmosdb_failover" {
  capability_type        = "Failover-1.0"
  chaos_studio_target_id = azurerm_chaos_studio_target.tgt-cosmosdb.id
}

resource "azurerm_chaos_studio_capability" "cap_eventhub_state" {
  capability_type        = "ChangeEventHubState-1.0"
  chaos_studio_target_id = azurerm_chaos_studio_target.tgt-eventhub.id
}

resource "azurerm_chaos_studio_capability" "cap_storage_unavailable_all" {
  for_each               = azurerm_chaos_studio_target.tgt_sa_all
  capability_type        = "Failover-1.0"
  chaos_studio_target_id = each.value.id
}

resource "azurerm_chaos_studio_capability" "nsg_security_rule" {
  chaos_studio_target_id = azurerm_chaos_studio_target.nsg_uks_1.id
  capability_type        = "SecurityRule-1.0"
}

# /********************************************************************************
#                      ADD CHAOS STUDIO EXPERIMENTS SCENARIOS
# ********************************************************************************/

# /********************************************************************************
# Notes:
# This entire section will be used to add in Real World scenarions based off PIR's
# from Microsoft.

# ********************************************************************************/


# /********************************************************************************
# Notes:
# This is going to replicate an Azure VM Disruption event from PIR 2LZ0-3DG,
# dated 16-SEPT-23.

# A power issue disrupted the scale units within a single Availability Zone within
# East US, causing compute nodes to become unhealthy. While a majority rebooted
# successfully, a subset did not. This led to failures and timeouts for Azure SQL
# Databases, impacting several services including Virtual Machines, SQL DBs, and
# Event Hubs.

# Chaos experiment simulating compute and messaging service outages without impacting
# data persistence.
#
# - Shuts down Virtual Machines and VM Scale Set instances for a fixed duration.
# - Disables all Service Bus queues to simulate messaging interruption.
# - Disables all Event Hubs to simulate event ingestion disruption.
#
# This experiment is used to validate application resilience to compute loss and
# messaging layer outages while leaving the data layer (Cosmos DB, Storage) untouched.
# ********************************************************************************/

resource "azurerm_chaos_studio_experiment" "pir_2lz0_3dg" {
  name                = "pir-2lz0-3dg"
  resource_group_name = module.rg_uks_3.name
  location            = module.rg_uks_3.location

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
        dynamic "actions" {
        for_each = azurerm_chaos_studio_capability.cap_vm_shutdown
        content {
          urn           = actions.value.urn
          selector_name = "Selector1"
          parameters = {
            abruptShutdown = "false"
          }
          action_type = "continuous"
          duration    = "PT15M"
          }
        }
        dynamic "actions" {
        for_each = azurerm_chaos_studio_capability.cap_vmss_shutdown
        content {
          urn           = actions.value.urn
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

  steps {
    name = "ServiceDisruptionStep"
    branch {
      name = "Branch2"
      actions {
        urn           = azurerm_chaos_studio_capability.cap_servicebus_queue_state.urn
        selector_name = "Selector1"
        action_type = "discrete"
        parameters = {
          desiredState = "Disabled"
          queues       = "*"
        }
      }
      actions {
        urn           = azurerm_chaos_studio_capability.cap_eventhub_state.urn
        selector_name = "Selector1"
        action_type = "discrete"
        parameters = {
          desiredState = "Disabled"
          eventHubs    = "*"
        }

      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "chaos_experiment_logging_ex1" {
  name                       = "pir-2lz03dg-chaos-experiment-logging"
  target_resource_id         = azurerm_chaos_studio_experiment.pir_2lz0_3dg.id
  log_analytics_workspace_id = module.chaos.id

  enabled_log {
    category = "ExperimentOrchestration"
  }

  # metric {
  #   category = "AllMetrics"
  # }
  # depends_on = [ azurerm_storage_account.chaos_exp_logs, azurerm_log_analytics_workspace.chaos_logging ]
}

# /********************************************************************************
# Notes:
# This is going to replicate an Azure Outage event from PIR 1K90-N_8
# dated 18-JUL-24.
#
# A misconfiguration in Azure's Central US region disrupted backend communication
# between compute and storage clusters, causing widespread service outages for
# Azure Storage, SQL Database, Cosmos DB, Teams, and other services.
#
# Chaos experiment simulating a full-stack application failure scenario.
#
# - Forces a Cosmos DB failover to a secondary read region to validate data-layer
# resilience.
# - Disables all Service Bus queues to simulate messaging outages.
# - Disables all Event Hubs to simulate event ingestion disruption.
# - Shuts down Virtual Machines and VM Scale Set instances for a fixed duration.
#
# This experiment is designed to test end-to-end application resilience, including
# data failover behaviour, messaging recovery, and compute restart scenarios.
#
# NOTE:
# - Cosmos DB failover is a long-running control-plane operation and may cause
#   Terraform apply timeouts; the experiment may be created successfully even
#   if Terraform reports a context deadline exceeded.
# ********************************************************************************/

resource "azurerm_chaos_studio_experiment" "pir_1k90_n8" {
  name                = "pir-1k90-n8"
  resource_group_name = module.rg_uks_3.name
  location            = module.rg_uks_3.location

  identity {
    type = "SystemAssigned"
  }
  selectors {
    name = "CosmosSelector"
    chaos_studio_target_ids = [
      azurerm_chaos_studio_target.tgt-cosmosdb.id
    ]
  }
  selectors {
    name = "ServiceBusSelector"
    chaos_studio_target_ids = [
      azurerm_chaos_studio_target.tgt-servicebus.id
    ]
  }
  selectors {
    name = "EventHubSelector"
    chaos_studio_target_ids = [
      azurerm_chaos_studio_target.tgt-eventhub.id
    ]
  }
  selectors {
    name = "VMSelector"
    chaos_studio_target_ids = values(azurerm_chaos_studio_target.tgt-vms)[*].id
  }
  selectors {
    name = "VMSSSelector"
    chaos_studio_target_ids = values(azurerm_chaos_studio_target.tgt-vmss)[*].id
  }

  # --- STEP 1: Compute + “Storage” disruption ---
  steps {
    name = "ComputeAndStorageDisruption"

    branch {
      name = "Branch1"

      actions {
        urn           = azurerm_chaos_studio_capability.cap_cosmosdb_failover.urn
        selector_name = "CosmosSelector"
        action_type   = "continuous"
        duration      = "PT15M"
        parameters = {
          readRegion = "North Europe"
        }
      }
    }
  }

  # --- STEP 2: ServiceBus + Event Hub disruption ---
  steps {
    name = "ServiceDisruptionStep"

    branch {
      name = "Branch2"

      actions {
        urn           = azurerm_chaos_studio_capability.cap_servicebus_queue_state.urn
        selector_name = "ServiceBusSelector"
        action_type   = "discrete"

        parameters = {
          desiredState = "Disabled"
          queues       = "*"
        }
      }

      actions {
        urn           = azurerm_chaos_studio_capability.cap_eventhub_state.urn
        selector_name = "EventHubSelector"
        action_type   = "discrete"

        parameters = {
          desiredState = "Disabled"
          eventhubs    = "[\"*\"]"
        }
      }
    }
  }

  # --- STEP 3: VM + VMSS disruption ---
  steps {
    name = "VMDisruption"

    branch {
      name = "Branch3"

      dynamic "actions" {
        for_each = azurerm_chaos_studio_capability.cap_vm_shutdown
        content {
          urn           = actions.value.urn
          selector_name = "VMSelector"
          action_type   = "continuous"
          duration      = "PT15M"
          parameters = {
            abruptShutdown = "false"
          }
        }
      }

      dynamic "actions" {
        for_each = azurerm_chaos_studio_capability.cap_vmss_shutdown
        content {
          urn           = actions.value.urn
          selector_name = "VMSSSelector"
          action_type   = "continuous"
          duration      = "PT15M"
          parameters = {
            abruptShutdown = "false"
          }
        }
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "chaos_experiment_logging_ex2" {
  name                       = "pir-1k90n8-chaos-experiment-logging"
  target_resource_id         = azurerm_chaos_studio_experiment.pir_1k90_n8.id
  log_analytics_workspace_id = module.chaos.id

  enabled_log {
    category = "ExperimentOrchestration"
  }
}

# /********************************************************************************
#                      ADD CHAOS STUDIO EXPERIMENTS (UK South Outages)
# ********************************************************************************/




# /********************************************************************************
#                      ADD CHAOS STUDIO PERMISSIONS
# ********************************************************************************/
resource "azurerm_role_assignment" "chaos_nsg_network_contrib" {
  for_each             = local.chaos_experiment_principals
  scope                = module.nsg_uks_1.id
  role_definition_name = "Network Contributor"
  principal_id         = each.value

  name = uuidv5("url", "chaos|nsg|${each.key}|${module.nsg_uks_1.id}")
}
resource "azurerm_role_assignment" "chaos_sb_data_owner" {
  for_each             = local.chaos_experiment_principals
  scope                = local.chaos_scopes.servicebus
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = each.value

  name = uuidv5("url", "chaos|sb|${each.key}|${local.chaos_scopes.servicebus}")
}

resource "azurerm_role_assignment" "chaos_eh_data_owner" {
  for_each             = local.chaos_experiment_principals
  scope                = local.chaos_scopes.eventhub
  role_definition_name = "Azure Event Hubs Data Owner"
  principal_id         = each.value

  name = uuidv5("url", "chaos|eh|${each.key}|${local.chaos_scopes.eventhub}")
}

resource "azurerm_role_assignment" "chaos_cosmos_operator" {
  for_each             = local.chaos_experiment_principals
  scope                = local.chaos_scopes.cosmos
  role_definition_name = "Cosmos DB Operator"
  principal_id         = each.value

  name = uuidv5("url", "chaos|cosmos|${each.key}|${local.chaos_scopes.cosmos}")
}

resource "azurerm_role_assignment" "chaos_vm_contributor" {
  for_each = {
    for item in flatten([
      for exp_name, pid in local.chaos_experiment_principals : [
        for scope_id in concat(local.chaos_scopes.vms, local.chaos_scopes.vmss) : {
          key          = "${exp_name}|${scope_id}"
          exp_name     = exp_name
          principal_id = pid
          scope_id     = scope_id
        }
      ]
    ]) : item.key => item
  }

  scope                = each.value.scope_id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = each.value.principal_id

  name = uuidv5("url", "chaos|vm|${each.value.exp_name}|${each.value.scope_id}")
}

# /********************************************************************************
# Notes:
# This section will be used to create smaller issues based within UK South and
# Global Resources designed to test failovers and outages. This will include things
# like AAD outages, App Service Plan and VM Resource failures, Zonal outages, etc.

# I will need to be able to gather resources dynamically, and create scenarios
# that will be randomised (ie random availability zone failures, VM failures, etc)
# so that no one scenario will be the same. This will be created within Azure and
# can be extracted via ARM template for future use if needed.

# ********************************************************************************/
# #