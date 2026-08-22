
resource "hcloud_server" "runners" {
  for_each    = { for server in var.runners : server.server_name => server }
  name        = each.value.server_name
  server_type = each.value.server_type
  location    = each.value.server_location
  image       = "debian-13"
  public_net {
    ipv4 = each.value.primary_ipv4_id
    ipv6 = each.value.primary_ipv6_id
  }
  network {
    network_id = var.network_id
    ip         = each.value.private_ipv4
  }
  ssh_keys = var.hcloud_ssh_keys

  lifecycle {
    ignore_changes = [
      user_data,
      ssh_keys,
      image,
      network
    ]
  }
  user_data = <<-EOT
#cloud-config
${yamlencode(
  {
    packages = []
    write_files = [
      {
        path        = "/runner/config.yaml"
        permissions = "0644"
        content = yamlencode({
          log = {
            level = "info"
          }
          runner = {
            capacity = var.runner_capacity
            timeout  = var.runner_timeout
          }
          cache = {
            host = "172.17.0.1"
            port = local.act_cache_port
          }
          container = {
            options = join(" ", [
              for host in var.buildx_servers : "--add-host=${host.server_name}:${host.private_ipv4}"
            ])
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
                CONFIG_FILE                     = "/config.yaml"
                GITEA_INSTANCE_URL              = var.gitea_instance_url
                GITEA_RUNNER_REGISTRATION_TOKEN = var.gitea_runner_registration_token
              }
              image   = "gitea/runner:3"
              restart = "always"
              ports = [
                "${local.act_cache_port}:${local.act_cache_port}",
              ]
              volumes = [
                "./config.yaml:/config.yaml",
                "${local.cache_mount_path}/data:/data",
                "${local.cache_mount_path}/.cache:/root/.cache",
                "/var/run/docker.sock:/var/run/docker.sock",
              ]
            }
          }
        })
      }
    ]
    runcmd = [
      "sleep 60",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sh get-docker.sh",
      "mkdir ${local.cache_mount_path}",
      "mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_${each.value.volume_cache_id} ${local.cache_mount_path}",
      "sleep 30",
      "docker compose -f ${local.act_compose_file_path} pull",
      "docker compose -f ${local.act_compose_file_path} up -d"
    ]
})}
EOT
}

resource "hcloud_volume_attachment" "runner_cache" {
  for_each  = { for server in var.runners : server.server_name => server }
  server_id = hcloud_server.runners[each.key].id
  volume_id = each.value.volume_cache_id
}
