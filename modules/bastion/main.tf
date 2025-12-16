resource "azurerm_public_ip" "pip_bastion" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "uks_bastion" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  #dns_name            = var.dns_name
  tags                = var.tags

  ip_configuration {
    name                 = "bastion-ipconf"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.pip_bastion.id
  }
}
