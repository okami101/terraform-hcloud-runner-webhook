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

variable "server_location" {
  description = "Name of the server"
}

variable "volume_cache_id" {
  description = "ID of the volume to be used as cache"
}

variable "cache_mount_path" {
  description = "Path to mount the cache volume"
}

variable "gitea_instance_url" {
  description = "URL of the Gitea instance"
}

variable "gitea_runner_registration_token" {
  description = "Registration token for the Gitea runner"
  sensitive   = true
}
