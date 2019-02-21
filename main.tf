resource "azurerm_resource_group" "core" {
  name     = "core"
  location = "${var.loc}"
  tags     = "${var.tags}"
}

locals {
  primaryiprange  = "${element(var.address_space, 0)}"
  newbits         = "${element(split("/", local.primaryiprange ), 1)}"
}

resource "azurerm_virtual_network" "core" {
  name                = "core"
  location            = "${azurerm_resource_group.core.location}"
  tags                = "${azurerm_resource_group.core.tags}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  address_space       = "${var.address_space}"
}

resource "azurerm_subnet" "gw" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_resource_group.core.name}"
  tags                 = "${azurerm_resource_group.core.tags}"
  virtual_network_name = "${azurerm_virtual_network.core.name}"
  address_prefix       = "${cidrsubnet(locals.primaryiprange, locals.newbits, -1)}"
}

resource "azurerm_public_ip" "core" {
  name                = "core"
  location            = "${azurerm_resource_group.core.location}"
  tags                = "${azurerm_resource_group.core.tags}"
  resource_group_name = "${azurerm_resource_group.core.name}"

  allocation_method = "Dynamic"
}

/*
resource "azurerm_virtual_network_gateway" "core" {
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
    public_ip_address_id          = "${azurerm_public_ip.core.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.core.id}"
  }
}
*/