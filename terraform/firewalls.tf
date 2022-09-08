
resource "hcloud_firewall" "controlplane_fw" {
  name = "controlplane_fw"

  rule {
    description = "allow all UDP inside cluster"
    direction   = "in"
    protocol    = "udp"
    port        = "51111"
    source_ips = [
      "0.0.0.0/0",
    ]
  }

  apply_to {
    label_selector = "type=controlplane"
  }

  depends_on = [
    hcloud_server.server
  ]
}

resource "hcloud_firewall" "worker_fw" {
  name = "worker_fw"

  apply_to {
    label_selector = "type=worker"
  }

  depends_on = [
    hcloud_server.agent
  ]
}

