terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = "~> 2.34"
    azurerm = "~> 1.39"
  }
}

data "http" "icanhazip" {
  url = "http://ipv4.icanhazip.com"
}

# Default Provider
provider "aws" {
  region = "us-east-1"
}

provider "azurerm" {}