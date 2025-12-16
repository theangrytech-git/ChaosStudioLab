output "lb_id" {
  value = azurerm_lb.lb_1.id
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.lb_bap_1.id
}

output "frontend_ip_configuration_name" {
  value = azurerm_lb.lb_1.frontend_ip_configuration[0].name
}

output "private_ip" {
  value = azurerm_lb.lb_1.frontend_ip_configuration[0].private_ip_address
}
