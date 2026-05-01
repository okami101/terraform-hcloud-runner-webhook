resource "hcloud_server" "buildx" {
  for_each    = { for server in var.enable_buildx_runners ? var.buildx_servers : [] : server.server_name => server }
  name        = each.value.server_name
  server_type = each.value.server_type
  location    = each.value.server_location
  image       = "debian-13"
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
    packages = ["git", "qemu-user-static"]
    runcmd = [
      "wget https://github.com/moby/buildkit/releases/download/${var.buildkit_version}/buildkit-${var.buildkit_version}.linux-${substr(each.value.server_type, 0, 3) == "cax" ? "arm64" : "amd64"}.tar.gz",
      "tar xf buildkit-*.tar.gz -C /usr/local/bin --strip-components=1",
      "buildkitd --addr tcp://${each.value.private_ipv4}:1234"
    ]
  }
)}
EOT
}
