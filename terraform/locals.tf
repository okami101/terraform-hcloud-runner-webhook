locals {
  cache_mount_path        = "/mnt/HC_Volume_${var.volume_cache_id}"
  act_config_file_path    = "/etc/act/config.yaml"
  act_compose_file_path   = "/runner/compose.yaml"
  docker_config_file_path = "/etc/docker/daemon.json"
  act_cache_port          = 8088
  cloud_init = {
    package_reboot_if_required = true
    package_update             = true
    package_upgrade            = true
    write_files = [
      {
        path        = local.docker_config_file_path
        permissions = "0644"
        content = jsonencode({
          "data-root" = "/var/lib/docker"
        })
      },
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
              image   = "gitea/act_runner:nightly"
              restart = "always"
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
    ]
    runcmd = [
      "mkdir ${local.cache_mount_path}",
      "mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_${var.volume_cache_id} ${local.cache_mount_path}",
      "sed -i 's|/var/lib|${local.cache_mount_path}|g' ${local.docker_config_file_path}",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sh get-docker.sh",
      "docker compose -f ${local.act_compose_file_path} up -d"
    ]
  }
}
