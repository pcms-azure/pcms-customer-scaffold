output "ip_address" {
    value = "${data.azurerm_public_ip.vpnip.ip_address}"
}
