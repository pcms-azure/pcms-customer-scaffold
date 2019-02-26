resource "azurerm_resource_group" "core" {
  name     = "${var.project}-core"
  location = "${var.loc}"
  tags     = "${var.tags}"
}

locals {
  primaryiprange  = "${element(var.address_space, 0)}"
  primarycidr     = "${element(split("/", local.primaryiprange ), 1)}"
  newbits         = "${max(0, 28 - local.primarycidr)}"
}

resource "azurerm_virtual_network" "customer" {
  name                = "${var.project}-vnet"
  location            = "${azurerm_resource_group.core.location}"
  tags                = "${azurerm_resource_group.core.tags}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  address_space       = "${var.address_space}"
}

resource "azurerm_subnet" "gw" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_resource_group.core.name}"
  virtual_network_name = "${azurerm_virtual_network.customer.name}"
  address_prefix       = "${cidrsubnet(local.primaryiprange, local.newbits, 1)}"
}

resource "azurerm_public_ip" "vpnpip" {
  name                = "${var.project}-vpnpip"
  location            = "${azurerm_resource_group.core.location}"
  tags                = "${azurerm_resource_group.core.tags}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  allocation_method = "Dynamic"
}

data "azurerm_public_ip" "vpnip" {
  name                = "${azurerm_public_ip.vpnpip.name}"
  resource_group_name = "${azurerm_resource_group.core.name}"
}

resource "azurerm_virtual_network_gateway" "vpngw" {
  name                = "${var.project}-vpngw"
  location            = "${azurerm_resource_group.core.location}"
  tags                = "${azurerm_resource_group.core.tags}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  type     = "Vpn"
  sku      = "VpnGw1"
  vpn_type = "RouteBased"

  enable_bgp    = "${var.bgp}"
  active_active = "${var.aa}"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.vpnpip.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.gw.id}"
  }
}