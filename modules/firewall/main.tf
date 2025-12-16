locals {
  # Determine whether to create PIPs
  want_create_pip      = var.public_ip_id == null && var.create_public_ip
  want_create_mgmt_pip = var.management_public_ip_id == null && var.create_management_ip

  # Safely select IDs (avoid coalesce crash when both null)
  chosen_public_ip_id = try(
    coalesce(
      var.public_ip_id,
      azurerm_public_ip.firewall_pip[0].id
    ),
    null
  )

  chosen_mgmt_public_ip_id = try(
    coalesce(
      var.management_public_ip_id,
      azurerm_public_ip.firewall_mgmt_pip[0].id
    ),
    null
  )

  firewall_public_ip_address = try(azurerm_public_ip.firewall_pip[0].ip_address, null)

  must_have_dataplane_pip = contains(["Standard", "Premium"], var.sku_tier)
  must_have_mgmt_pip      = var.sku_tier == "Basic"
}

# -------------------------------------------------------------------
# Public IPs (created only if requested)
# -------------------------------------------------------------------
resource "azurerm_public_ip" "firewall_pip" {
  count               = local.want_create_pip ? 1 : 0
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "firewall_mgmt_pip" {
  count               = local.want_create_mgmt_pip ? 1 : 0
  name                = "${var.name}-mgmt-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# -------------------------------------------------------------------
# Azure Firewall resource
# -------------------------------------------------------------------
resource "azurerm_firewall" "firewall" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier
  threat_intel_mode   = var.threat_intel_mode

  # Primary dataplane IP configuration
  dynamic "ip_configuration" {
    for_each = length(var.ip_configurations) > 0 ? [var.ip_configurations[0]] : []
    content {
      name                 = ip_configuration.value.name
      subnet_id            = ip_configuration.value.subnet_id
      public_ip_address_id = local.chosen_public_ip_id
    }
  }

  # Additional IP configurations (no PIP)
  dynamic "ip_configuration" {
    for_each = length(var.ip_configurations) > 1 ? slice(var.ip_configurations, 1, length(var.ip_configurations)) : []
    content {
      name      = ip_configuration.value.name
      subnet_id = ip_configuration.value.subnet_id
    }
  }

  # Management IP configuration (Basic SKU only)
  dynamic "management_ip_configuration" {
    for_each = (local.must_have_mgmt_pip && local.chosen_mgmt_public_ip_id != null) ? [1] : []
    content {
      name                 = "mgmtconfig"
      subnet_id            = var.ip_configurations[0].subnet_id
      public_ip_address_id = local.chosen_mgmt_public_ip_id
    }
  }

  # Guardrails (prevents silent misconfigurations)
  lifecycle {
    precondition {
      condition     = !(local.must_have_dataplane_pip && local.chosen_public_ip_id == null)
      error_message = "Standard/Premium SKU requires a dataplane Public IP. Create one or provide public_ip_id."
    }
    precondition {
      condition     = !(local.must_have_mgmt_pip && local.chosen_mgmt_public_ip_id == null)
      error_message = "Basic SKU requires a management Public IP. Enable create_management_ip or provide management_public_ip_id."
    }
  }
}

# -------------------------------------------------------------------
# Network Rule Collections
# -------------------------------------------------------------------
resource "azurerm_firewall_network_rule_collection" "network_rule_collection" {
  for_each            = var.network_rule_collections
  name                = each.value.name
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                  = rule.value.name
      source_addresses      = rule.value.source_addresses
      destination_addresses = rule.value.destination_addresses
      destination_ports     = rule.value.destination_ports
      protocols             = rule.value.protocols
    }
  }
}

# -------------------------------------------------------------------
# Application Rule Collections
# -------------------------------------------------------------------
resource "azurerm_firewall_application_rule_collection" "application_rule_collection" {
  for_each            = var.application_rule_collections
  name                = each.value.name
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name             = rule.value.name
      source_addresses = rule.value.source_addresses
      fqdn_tags        = coalesce(try(rule.value.fqdn_tags, null), [])
      target_fqdns     = coalesce(try(rule.value.target_fqdns, null), [])

      # Correct block name: 'protocol'
      dynamic "protocol" {
        for_each = rule.value.protocols
        content {
          type = protocol.value.type
          port = protocol.value.port
        }
      }
    }
  }
}

# -------------------------------------------------------------------
# NAT Rule Collections
# -------------------------------------------------------------------
resource "azurerm_firewall_nat_rule_collection" "nat_rule_collection" {
  for_each            = var.nat_rule_collections
  name                = each.value.name
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                  = rule.value.name
      source_addresses      = rule.value.source_addresses
      destination_addresses = coalesce(
        try(rule.value.destination_addresses, null),
        local.firewall_public_ip_address != null ? [local.firewall_public_ip_address] : []
      )
      destination_ports     = rule.value.destination_ports
      translated_address    = rule.value.translated_address
      translated_port       = rule.value.translated_port
      protocols             = rule.value.protocols
    }
  }
}