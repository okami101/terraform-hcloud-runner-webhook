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
${yamlencode(each.value.type == "buildx" ?
  {
    packages    = ["git"]
    write_files = []
    runcmd = [
      "sleep 60",
      "mkdir ${local.cache_mount_path}",
      "mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_${each.value.volume_cache_id} ${local.cache_mount_path}",
      "sleep 30",
      "wget https://github.com/moby/buildkit/releases/download/${var.buildkit_version}/buildkit-${var.buildkit_version}.linux-${substr(each.value.server_type, 0, 3) == "cax" ? "arm64" : "amd64"}.tar.gz",
      "tar xf buildkit-*.tar.gz -C /usr/local/bin --strip-components=1",
      "buildkitd --addr tcp://${each.value.private_ipv4}:1234 --root ${local.cache_mount_path}/buildkit"
    ]
  } :
  {
    packages = []
    write_files = [
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
          container = {
            options = join(" ", [
              for host in var.runners : "--add-host=${host.server_name}:${host.private_ipv4}" if host.type == "buildx"
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
