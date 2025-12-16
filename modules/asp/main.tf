resource "azurerm_service_plan" "asp" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  os_type  = var.os_type

  sku_name = var.sku_name

  zone_balancing_enabled       = var.zone_balancing_enabled
  worker_count                 = var.worker_count
  maximum_elastic_worker_count = var.maximum_elastic_worker_count

  tags = var.tags
}
