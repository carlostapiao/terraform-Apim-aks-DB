terraform {

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    helm = {
      source = "hashicorp/helm"
    }

  }

}

provider "azurerm" {

  features {}

  subscription_id = "e690edad-0257-4dec-b4c9-08e163433edb"

}

resource "azurerm_resource_group" "rg" {

  name     = "rg-k8s-lab"
  location = "Central US"

}

# ACR

resource "azurerm_container_registry" "acr" {

  name                = "carlos69lamejor"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true

}

# AKS

resource "azurerm_kubernetes_cluster" "aks" {

  name                = "aks-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-lab"

  default_node_pool {

    name       = "nodepool1"
    node_count = 1
    vm_size    = "Standard_B2ps_v2"

  }

  identity {
    type = "SystemAssigned"
  }

}

# Permiso ACR → AKS

resource "azurerm_role_assignment" "acr_pull" {

  principal_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  role_definition_name = "AcrPull"

  scope = azurerm_container_registry.acr.id

}

# SQL Server

resource "azurerm_mssql_server" "sql" {

  name = "sqlservercarlos69"

  resource_group_name = azurerm_resource_group.rg.name

  location = azurerm_resource_group.rg.location

  version = "12.0"

  administrator_login = "sqladmin"

  administrator_login_password = "Password1234!"

}

# Database

resource "azurerm_mssql_database" "db" {

  name = "productosdb"

  server_id = azurerm_mssql_server.sql.id

  sku_name = "Basic"

}

# Firewall

resource "azurerm_mssql_firewall_rule" "allow_azure" {

  name = "AllowAzure"

  server_id = azurerm_mssql_server.sql.id

  start_ip_address = "0.0.0.0"

  end_ip_address   = "0.0.0.0"

}

# APIM

resource "azurerm_api_management" "apim" {

  name = "apim-lab-carlos"

  location = azurerm_resource_group.rg.location

  resource_group_name = azurerm_resource_group.rg.name

  publisher_name  = "Carlos"

  publisher_email = "carlos@example.com"

  sku_name = "Developer_1"

}

# Kubernetes provider

provider "kubernetes" {

  host = azurerm_kubernetes_cluster.aks.kube_config[0].host

  client_certificate = base64decode(
    azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  )

  client_key = base64decode(
    azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  )

  cluster_ca_certificate = base64decode(
    azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  )

}

# Helm

provider "helm" {

  kubernetes = {

    host = azurerm_kubernetes_cluster.aks.kube_config[0].host

    client_certificate = base64decode(
      azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
    )

    client_key = base64decode(
      azurerm_kubernetes_cluster.aks.kube_config[0].client_key
    )

    cluster_ca_certificate = base64decode(
      azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
    )

  }

}

# NGINX Ingress

resource "helm_release" "nginx_ingress" {

  name = "nginx-ingress"

  repository = "https://kubernetes.github.io/ingress-nginx"

  chart = "ingress-nginx"

  namespace = "ingress-nginx"

  create_namespace = true

}