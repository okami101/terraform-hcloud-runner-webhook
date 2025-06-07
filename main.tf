resource "hcloud_server" "runner" {
  name        = var.server_name
  server_type = var.server_type
  location    = var.server_location
  image       = "docker-ce"
  public_net {
    ipv4 = var.primary_ipv4_id
    ipv6 = var.primary_ipv6_id
  }
  network {
    network_id = var.network_id
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
${yamlencode({
  write_files = concat(local.cloud_init_write_files, [
    {
      path        = local.act_config_file_path
      permissions = "0644"
      content = yamlencode({
        log = {
          level = "info"
        }
        runner = {
          capacity = 3
        }
        cache = {
          host = "172.17.0.1"
          port = local.act_cache_port
        }
      })
    },
    {
      path        = local.act_compose_file_path
      permissions = "0644"
      content = yamlencode({
        services = {
          act = {
            environment = {
              CONFIG_FILE                     = local.act_config_file_path
              GITEA_INSTANCE_URL              = var.gitea_instance_url
              GITEA_RUNNER_REGISTRATION_TOKEN = var.gitea_runner_registration_token
            }
            image = "gitea/act_runner:nightly"
            ports = [
              "${local.act_cache_port}:${local.act_cache_port}",
            ]
            volumes = [
              "${local.act_config_file_path}:${local.act_config_file_path}",
              "${local.cache_mount_path}/actdata:/data",
              "${local.cache_mount_path}/actcache:/root/.cache",
              "/var/run/docker.sock:/var/run/docker.sock",
            ]
          }
        }
      })
    }
  ])
  runcmd = [
    "mkdir ${local.cache_mount_path}",
    "mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_${var.volume_cache_id} ${local.cache_mount_path}",
    "sed -i 's|/var/lib|${local.cache_mount_path}|g' ${local.docker_config_file_path}",
    "systemctl restart docker",
    "docker compose -f ${local.act_compose_file_path} up -d"
  ]
})}
EOT
}

resource "hcloud_volume_attachment" "runner_cache" {
  volume_id = var.volume_cache_id
  server_id = hcloud_server.runner.id
}
