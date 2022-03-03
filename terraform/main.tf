provider "hcloud" {
  token = var.hcloud_token
}

data "hcloud_image" "talos" {
  with_selector = "os=talos"
}

resource "hcloud_server" "server" {
  count       = 1
  name        = "server-${count.index}"
  image       = data.hcloud_image.talos.id
  server_type = var.controlplane_server_type
  location    = "fsn1"
  labels = {
    "type"         = "controlplane"
    "talos/server" = "true"
    "talos/agent"  = "false"
  }
  network {
    network_id = hcloud_network.talos.id
  }

  provisioner "local-exec" {
    command = <<-EOT
    bash controlplane.sh ${self.ipv4_address}
        EOT
  }

  depends_on = [
    hcloud_network_subnet.talos
  ]
}

resource "hcloud_server" "agent" {
  count       = var.agent_count
  name        = "agent-${count.index}"
  image       = data.hcloud_image.talos.id
  server_type = var.agent_server_type
  location    = "fsn1"
  labels = {
    "type"         = "worker"
    "talos/server" = "false"
    "talos/agent"  = "true"
  }
  network {
    network_id = hcloud_network.talos.id
  }

  provisioner "local-exec" {
    command = <<-EOT
    bash node.sh ${self.ipv4_address}
        EOT
  }

  # provisioner "local-exec" {
  #   when    = destroy
  #   command = "kubectl delete node ${self.name}"
  # }

  depends_on = [
    hcloud_server.server,
    hcloud_network_subnet.talos
  ]
}

resource "hcloud_network" "talos" {
  name     = "talos"
  ip_range = "10.29.0.0/16"

  provisioner "local-exec" {
    command = <<-EOT
    bash network.sh ${self.ip_range}
        EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ../settings/* && rm -f wireguard/*"
  }
}

resource "hcloud_network_subnet" "talos" {
  network_id   = hcloud_network.talos.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.29.0.0/24"
}
