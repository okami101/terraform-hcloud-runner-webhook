locals {
  cache_mount_path        = "/mnt/HC_Volume_${var.volume_cache_id}"
  act_config_file_path    = "/etc/act/config.yaml"
  act_compose_file_path   = "/runner/compose.yaml"
  docker_config_file_path = "/etc/docker/daemon.json"
  act_cache_port          = 8088
  cloud_init_write_files = [
    {
      path        = local.docker_config_file_path
      permissions = "0644"
      content = jsonencode({
        "data-root" = "/var/lib/docker"
      })
    }
  ]
  buildx_servers = [
    for server in var.buildx_servers : {
      server_name      = server.server_name
      server_type      = server.server_type
      server_location  = server.server_location
      volume_cache_id  = server.volume_cache_id
      hcloud_ssh_keys  = server.hcloud_ssh_keys
      private_ipv4     = server.private_ipv4
      cache_mount_path = "/mnt/HC_Volume_${server.volume_cache_id}"
    }
  ]
}
