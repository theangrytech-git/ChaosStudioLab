output "vm_id" {
  value = azurerm_linux_virtual_machine.uks_lin_vm.id
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.uks_lin_vm.name
}

output "public_ip" {
  value = var.public_ip_enabled ? azurerm_public_ip.uks_lin_vm_pip[0].ip_address : null
}
