resource "azurerm_linux_web_app" "wa_linux" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id

  site_config {
    application_stack {
      python_version = var.runtime == "python" ? var.runtime_version : null
      node_version   = var.runtime == "node" ? var.runtime_version : null
      php_version    = var.runtime == "php"   ? var.runtime_version : null
    }

    always_on = true
  }

  app_settings = merge(
    {
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "true"
      "WEBSITE_RUN_FROM_PACKAGE"            = "1"
    },
    var.app_settings
  )

  https_only = true
  tags       = var.tags
}