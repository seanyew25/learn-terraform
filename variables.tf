variable "key-pair_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"

}

variable "security_groups" {
  type = list(string)
}

