#!/bin/bash
##########################################################################################################
# Creates a service principal for Packer and creates a
# default Packer template and credentials file as per 
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/ansible-install-configure#file-credentials
##########################################################################################################

error()
{
  if [[ -n "$@" ]]
  then
    tput setaf 1
    echo "ERROR: $@" >&2
    tput sgr0
  fi

  exit 1
}

yellow() { tput setaf 3; cat - ; tput sgr0; return; }
cyan()   { tput setaf 6; cat - ; tput sgr0; return; }

## Main

read -e -p "Enter resource group name for packer images: " -i "packer_images" imagesrg
read -e -p "Enter Azure region: " -i "West Europe" location
read -e -p "Enter VM size: " -i "Standard_DS2_v2" vm_size
read -e -p "Enter Packer filename: " -i "configManagementVm.json" packerfile
read -e -p "Enter Ansible playbook filename: " -i "configManagementVm.yaml" ansiblefile

# Grab the Azure subscription ID
echo -n "Subscription ID is ... " | yellow
subId=$(az account show --output tsv --query id)
[[ -z "$subId" ]] && error "Not logged into Azure as expected."
echo "$subId" | cyan

sname="packer-${subId}-sp"
name="http://${sname}"

# Create the resource group for the images
echo "az group create --name $imagesrg --location "$location" --output jsonc" | yellow
az group create --name $imagesrg --location "$location" --output jsonc

# Create the service principal
echo "az ad sp create-for-rbac --name \"$name\"" | yellow
spout=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$subId" --name "$name" --output json)

# If the service principal has been created then offer to reset credentials
if [[ "$?" -ne 0 ]]
then
  echo -n "Service Principal already exists. Do you want to reset credentials? [Y/n]: "
  read ans
  if [[ "${ans:-Y}" = [Yy] ]]
  then spout=$(az ad sp credential reset --name "$name" --output json)
  else exit 1
  fi
fi

[[ -z "$spout" ]] && error "Failed to create / reset the service principal $name"

# Echo the json output
echo "$spout" | yellow

# Derive the required variables
clientId=$(jq -r .appId <<< $spout)
clientSecret=$(jq -r .password <<< $spout)
tenantId=$(jq -r .tenant <<< $spout)

# Create a credentials file.  This can be uploaded to hosts with ansible installed as ~/.azure/credentials

cat > credentials <<END-OF-CREDENTIALS
[default]
tenant=$tenantId
subscription_id=$subId
client_id=$clientId
secret=$clientSecret
END-OF-CREDENTIALS


cat > $packerfile <<END-OF-PACKERFILE
{
  "builders": [{
    "type": "azure-arm",

    "client_id": "$clientId",
    "client_secret": "$clientSecret",
    "tenant_id": "$tenantId",
    "subscription_id": "$subId",

    "managed_image_resource_group_name": "$imagesrg",
    "managed_image_name": "$(basename $packerfile .json)",

    "os_type": "Linux",
    "image_publisher": "Canonical",
    "image_offer": "UbuntuServer",
    "image_sku": "16.04-LTS",

    "azure_tags": {
        "dept": "Testing",
        "task": "Image Deployment"
    },

    "location": "$location",
    "vm_size": "$vm_size"
  }],
  "provisioners": [
    {
      "type": "shell",
      "inline": [
        "apt-add-repository -y ppa:ansible/ansible",
        "apt-get update",
        "apt-get install -y libssl-dev libffi-dev python-dev python-pip",
        "apt-get upgrade -y",
        "pip install --upgrade pip"
        "pip install ansible[azure]"
      ],
      "inline_shebang": "/bin/sh -x",
      "execute_command": "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    },
    {
      "type": "file",
      "source": "./credentials",
      "destination": "/tmp/credentials"
    },
    {
      "type": "shell",
      "inline": [
	"test -d ~/.azure || mkdir -m 700 ~/.azure",
        "chmod 600 /tmp/credentials && mv /tmp/credentials ~/.azure/credentials"
      ],
      "inline_shebang": "/bin/sh -x",
      "execute_command": "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    },
    {
      "type": "ansible",
      "playbook_file": "$ansiblefile" 
    },
    {
      "type": "shell",
      "inline": [
        "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
      ],
      "inline_shebang": "/bin/sh -x",
      "execute_command": "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    }
  ]
}
END-OF-PACKERFILE

[[ -s $packerfile ]] && echo -n "Run " && { echo "packer build $packerfile" | cyan; }
exit 0
