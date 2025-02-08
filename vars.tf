variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  sensitive   = true
}

variable "hcloud_ssh_keys" {
  description = "List of SSH key IDs to be added to the server"
  type        = list(string)
}

variable "server_name" {
  description = "Name of the server"
}

variable "server_type" {
  description = "Type of the server"
}

variable "server_location" {
  description = "Name of the server"
}

variable "primary_ipv4_id" {
  description = "ID of IPV4 primary IP"
}

variable "primary_ipv6_id" {
  description = "ID of IPV6 primary IP"
}

variable "volume_cache_id" {
  description = "ID of the volume to be used as cache"
}

variable "gitea_instance_url" {
  description = "URL of the Gitea instance"
}

variable "gitea_runner_registration_token" {
  description = "Registration token for the Gitea runner"
  sensitive   = true
}
