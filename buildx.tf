resource "hcloud_server" "buildx" {
  for_each    = { for server in var.buildx_servers : server.server_name => server }
  name        = each.value.server_name
  server_type = each.value.server_type
  location    = each.value.server_location
  image       = "docker-ce"
  network {
    network_id = var.network_id
    ip         = each.value.private_ipv4
  }
  ssh_keys = each.value.hcloud_ssh_keys

  lifecycle {
    ignore_changes = [
      user_data,
      ssh_keys,
      image
    ]
  }
  user_data = <<-EOT
#cloud-config
${yamlencode({
  reboot_if_required = true
  update_packages    = true
  upgrade_packages   = true
})}
EOT
}
