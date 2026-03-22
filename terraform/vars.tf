variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  sensitive   = true
}

variable "hcloud_ssh_keys" {
  description = "List of SSH key IDs to be added to the server"
  type        = list(string)
}

variable "network_id" {
  description = "ID of the network to which the server will be connected"
}

variable "gitea_instance_url" {
  description = "URL of the Gitea instance"
}

variable "gitea_runner_registration_token" {
  description = "Registration token for the Gitea runner"
  sensitive   = true
}

variable "buildkit_version" {
  description = "Version of BuildKit to be installed on buildx servers"
  default     = "v0.28.0"
}

variable "runners" {
  description = "List of buildx servers with their configurations"
  type = list(object({
    server_name     = string
    server_type     = string
    server_location = string
    primary_ipv4_id = string
    primary_ipv6_id = string
    private_ipv4    = string
    volume_cache_id = string
    type            = optional(string)
  }))
  default = []
}
