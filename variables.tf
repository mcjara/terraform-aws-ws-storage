# Variables
variable "instance_name" {
  type = string
}

variable "source_ip_range" {
  type    = list(string)
  default = []
}