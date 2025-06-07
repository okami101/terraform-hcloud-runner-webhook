resource "hcloud_server" "buildx" {
  for_each    = { for server in local.buildx_servers : server.server_name => server }
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
  write_files = local.cloud_init_write_files
  runcmd = [
    "mkdir ${each.value.cache_mount_path}",
    "mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_${each.value.volume_cache_id} ${each.value.cache_mount_path}",
    "sed -i 's|/var/lib|${each.value.cache_mount_path}|g' ${local.docker_config_file_path}",
    "systemctl restart docker",
  ]
})}
EOT
}

resource "hcloud_volume_attachment" "buildx_cache" {
  for_each  = { for server in local.buildx_servers : server.server_name => server }
  server_id = hcloud_server.buildx[each.key].id
  volume_id = each.value.volume_cache_id
}
