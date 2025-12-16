resource "azurerm_lb" "lb_1" {
  name                = var.lb_name != null ? var.lb_name : "lb-int-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = var.frontend_name != null ? var.frontend_name : "fip-lb-int-${var.location}"
    subnet_id                     = var.subnet_id
    private_ip_address            = cidrhost(var.vnet_cidr, var.lb_offset)
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "lb_bap_1" {
  name            = var.backend_pool_name
  loadbalancer_id = azurerm_lb.lb_1.id
}

resource "azurerm_lb_probe" "lb_probe_1" {
  loadbalancer_id     = azurerm_lb.lb_1.id
  name                = var.probe_name
  port                = var.probe_port
  protocol            = var.probe_protocol # "Http" or "Tcp"
  interval_in_seconds = var.probe_interval
  request_path        = var.probe_protocol == "Http" ? var.probe_request_path : null
}

resource "azurerm_lb_rule" "lb_rule_1" {
  loadbalancer_id                = azurerm_lb.lb_1.id
  name                           = var.rule_name
  protocol                       = var.rule_protocol
  frontend_port                  = var.frontend_port
  backend_port                   = var.backend_port
  frontend_ip_configuration_name = azurerm_lb.lb_1.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.lb_probe_1.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_bap_1.id]
}

# Attach any number of NICs (A and B lists combined) to the backend pool
resource "azurerm_network_interface_backend_address_pool_association" "nic_assoc" {
  for_each = {
    for idx, na in var.nic_associations : tostring(idx) => na
  }

  network_interface_id    = each.value.nic_id
  ip_configuration_name   = each.value.ip_configuration_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_bap_1.id
}
