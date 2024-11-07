# Current sub (assumed from cli login)
data "azurerm_subscription" "current" {
}


# Resource Group
resource "azurerm_resource_group" "test" {
  name     = var.resource_group
  location = var.location
}

# Assign "Reader" role to the service account for the resource group
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.test.id
  role_definition_name = "Reader"
  principal_id         = var.sp_principal_id
}

# Virtual Network
resource "azurerm_virtual_network" "test" {
  name                = "test-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

# Subnet
resource "azurerm_subnet" "test" {
  name                 = "test-subnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Interface
resource "azurerm_network_interface" "test" {
  name                = "test-nic"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
  }
}

# VM Scaled Set
resource "azurerm_linux_virtual_machine_scale_set" "test" {
  name                            = "test-vmss"
  resource_group_name             = azurerm_resource_group.test.name
  location                        = azurerm_resource_group.test.location
  sku                             = "Standard_DC1s_v2"
  instances                       = 1 # Number of VMs in the scale set, adjust as needed
  admin_username                  = "husker"
  admin_password                  = random_password.admin_password.result
  disable_password_authentication = false

  # Spot setup
  priority        = "Spot"
  eviction_policy = "Deallocate"

  # Network Profile
  network_interface {
    name    = "test-vmss-nic"
    primary = true

    ip_configuration {
      name                          = "internal"
      subnet_id                     = azurerm_subnet.test.id
      primary                       = true
    }
  }

  # OS Disk configuration
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Image configuration
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "24.04.202410170"
  }


  tags = var.tags
}


# Random Password Generator
resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>?" # Customize special characters if needed
}

# Outputs
output "vm_public_ip" {
  value = azurerm_network_interface.test.private_ip_address
}

output "vm_password" {
  description = "The admin password generated by the module."
  value       = random_password.admin_password.result
  sensitive   = true
}