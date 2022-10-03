# variable "vpc_id" {
#     description = "ID of the VPC for SG."
#     type = string
#     # default = "vpc-006f84d06141afbec"
# }

variable "server_subnet" {
    type = string
}

variable "agent_subnet" {
    type = string
}

variable "agent_sg_id" {
    type = string
}