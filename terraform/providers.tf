terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.48.0"
    }
  }

  backend "local" {
    path = "/data"
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
