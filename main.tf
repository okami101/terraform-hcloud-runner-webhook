resource "hcloud_server" "server" {
  name        = var.server_name
  server_type = var.server_type
  location    = var.server_location
  image       = "docker-ce"
  public_net {
    ipv4 = var.primary_ipv4_id
    ipv6 = var.primary_ipv6_id
  }
  ssh_keys = var.hcloud_ssh_keys
  lifecycle {
    ignore_changes = [
      user_data,
      ssh_keys,
      image
    ]
  }
  user_data = <<-EOT
#cloud-config
${yamlencode(local.cloud_init)}
EOT
}

resource "hcloud_volume_attachment" "cache" {
  volume_id = var.volume_cache_id
  server_id = hcloud_server.server.id
}
