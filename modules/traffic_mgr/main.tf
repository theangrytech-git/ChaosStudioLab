resource "azurerm_traffic_manager_profile" "tm_profile" {
  name                   = var.profile_name
  resource_group_name    = var.resource_group_name
  traffic_routing_method = var.traffic_routing_method

  dns_config {
    relative_name = var.relative_name
    ttl           = var.ttl
  }

  monitor_config {
    protocol                     = var.monitor_protocol
    port                         = var.monitor_port
    path                         = var.monitor_path
    interval_in_seconds          = var.monitor_interval_in_seconds
    timeout_in_seconds           = var.monitor_timeout_in_seconds
    tolerated_number_of_failures = var.monitor_tolerated_number_of_failures
  }

  tags = var.tags
}

resource "azurerm_public_ip" "pip" {
  count               = var.create_public_ip ? 1 : 0
  name                = var.public_ip_name
  location            = var.public_ip_location
  resource_group_name = var.resource_group_name
  sku                 = var.public_ip_sku
  allocation_method   = var.public_ip_allocation

  # Zones are optional and SKU must support zones
  zones = var.public_ip_zones
  domain_name_label   = lower(var.public_ip_dns_label)

  tags = var.tags
}

# Endpoint for the managed Public IP (only if created)
resource "azurerm_traffic_manager_azure_endpoint" "pip_ep" {
  count              = var.create_public_ip ? 1 : 0
  name               = var.managed_endpoint_name
  profile_id         = azurerm_traffic_manager_profile.tm_profile.id
  target_resource_id = azurerm_public_ip.pip[0].id
  enabled            = var.managed_endpoint_enabled

  # Apply weight/priority only if relevant to the routing method
  weight   = contains(["Weighted"], var.traffic_routing_method) && var.managed_endpoint_weight != null ? var.managed_endpoint_weight : null
  priority = contains(["Priority"], var.traffic_routing_method) && var.managed_endpoint_priority != null ? var.managed_endpoint_priority : null
  depends_on = [ azurerm_public_ip.pip ]
}
