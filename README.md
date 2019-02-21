# pcms-customer-scaffold

Base scaffolding in the customer subscription

This Terraform module deploys

* a Virtual Network in Azure based on the project name
* a GatewaySubnet (/28) containing a VpnGw1 route based VPN gateway

## Usage

```hcl
module "network" {
    source         = "github.com/Azure/network/azurerm"
    project        = "non-prod"
    location       = "westeurope"
    address_space  = [ "10.12.0.0/22" ]

    tags  = {
                customer    = "acme"
                project     = "non-prod"
                costcentre  = "it"
                owner       = "John Doe"
            }
}
```

## Outputs

The ip_address is the only exported attribute.

## Arguments

* **project** (required) - *prod* or *non-prod*
