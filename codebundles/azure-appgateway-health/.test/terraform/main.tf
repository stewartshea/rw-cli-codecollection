# Current sub (assumed from CLI login)
data "azurerm_subscription" "current" {}

# Get tenant and user details of the current CLI session
data "azurerm_client_config" "current" {}

# Local SSH Key Pair Generation
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save Private Key to Local File
resource "local_file" "private_key" {
  filename        = "backend-key.secret"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600"
}

# Save Public Key to Local File
resource "local_file" "public_key" {
  filename        = "backend-key.pub.secret"
  content         = tls_private_key.ssh_key.public_key_openssh
  file_permission = "0644"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
  tags     = var.tags

}

# Assign "Reader" role to the service account for the resource group
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = var.sp_principal_id
}


resource "azurerm_virtual_network" "vnet" {
  name                = "appgw-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_subnet" "backend_subnet" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "appgw_public_ip" {
  name                = "appgw-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_public_ip.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-backend-settings"
    protocol              = "Http"
    port                  = 80
    cookie_based_affinity = "Disabled"
    request_timeout       = 20
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    priority                   = 1
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-backend-settings"
  }


  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  # Associate backend addresses (VM IPs)
  dynamic "backend_address_pool" {
    for_each = ["10.0.2.4", "10.0.2.5"]
    content {
      name  = "backend-pool"
      fqdns = []
    }
  }
}


resource "azurerm_network_security_group" "nsg_backend" {
  name                = "nsg-backend"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "backend_nic" {
  count               = 2
  name                = "backend-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  count               = 2
  name                = "backend-vm-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }


  network_interface_ids = [azurerm_network_interface.backend_nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag.primary_blob_endpoint
  }
}

resource "azurerm_storage_account" "diag" {
  name                     = "diagstorage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

output "resource_group" {
  value = azurerm_resource_group.rg.name
}