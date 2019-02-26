variable "project" {
    type        = "string"
    default     = "pcms-contoso-non-prod"
    description = "PCMS project identifier, e.g. pcms-<customername>-non-prod*"
}

variable "loc" {
    type        = "string"
    default     = "westeurope"
    description = "Azure region shortname."
}

variable "tags" {
    type        = "map"
    default     = {}
    description = "Map of tag name:value pairs."
}

variable "address_space" {
    type        = "list"
    default     = [ "10.0.0.0/22" ]
    description = "List of vnet address spaces"
}

variable "bgp" {
    type        = "string"
    default     = false
    description = "Configure whether VPN gateway will use BGP. (Default: false)"
}

variable "aa" {
    type        = "string"
    default     = false
    description = "Configure whether VPN gateway will be configured as active-active. (Default: false)"
}