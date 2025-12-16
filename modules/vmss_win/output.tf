output "id" {
  description = "Resource ID of the VM Scale Set"
  value       = azurerm_windows_virtual_machine_scale_set.uks_win_vmss.id
}

output "name" {
  description = "Name of the VM Scale Set"
  value       = azurerm_windows_virtual_machine_scale_set.uks_win_vmss.name
}