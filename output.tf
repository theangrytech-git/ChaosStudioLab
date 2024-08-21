output "_1_Access-URL-via-TrafficManager" {
  value = "Use this URL to access via Traffic Manager: http://${azurerm_traffic_manager_profile.tm1.fqdn} "
}
output "_2_Access-URL-via-uks-Firewall" {
  value = "Use this URL to access directly to the ${var.uks} Firewall: http://${azurerm_public_ip.uks-fwpip.fqdn} "
}
output "_3_Access-URL-via-ukw-Firewall" {
  value = "Use this URL to access directly to the ${var.ukw} Firewall: http://${azurerm_public_ip.ukw-fwpip.fqdn} "
}