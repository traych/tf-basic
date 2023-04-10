terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "tf-teodor-rg" {
  name     = "tf-teodor-rg"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "tf-teodor-network" {
  name                = "tf-teodor-network"
  resource_group_name = azurerm_resource_group.tf-teodor-rg.name
  location            = azurerm_resource_group.tf-teodor-rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "tf-teodor-subnet-internal" {
  name                 = "tf-teodor-subnet-internal"
  resource_group_name  = azurerm_resource_group.tf-teodor-rg.name
  virtual_network_name = azurerm_virtual_network.tf-teodor-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "tf-teodor-public-ip" {
  name                = "tf-teodor-public-ip"
  resource_group_name = azurerm_resource_group.tf-teodor-rg.name
  location            = azurerm_resource_group.tf-teodor-rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "tf-teodor-nic" {
  name                = "tf-teodor-nic"
  location            = azurerm_resource_group.tf-teodor-rg.location
  resource_group_name = azurerm_resource_group.tf-teodor-rg.name

  ip_configuration {
    name                          = "tf-teodor-IP"
    subnet_id                     = azurerm_subnet.tf-teodor-subnet-internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.tf-teodor-public-ip.id
}
}

resource "azurerm_virtual_machine" "tf-teodor-vm" {
  name                  = "tf-teodor-vm"
  location              = azurerm_resource_group.tf-teodor-rg.location
  resource_group_name   = azurerm_resource_group.tf-teodor-rg.name
  network_interface_ids = [azurerm_network_interface.tf-teodor-nic.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "tf-teodor-hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
