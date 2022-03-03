variable "hcloud_token" {
  type = string
}
variable "controlplane_server_type" {
  type    = string
  default = "cx21"
}
variable "agent_server_type" {
  type    = string
  default = "cx21"
}
variable "agent_count" {
  type    = number
  default = 2
}
