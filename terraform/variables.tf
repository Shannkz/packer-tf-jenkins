variable "vpc_id" {
    description = "ID of the VPC for SG."
    type = string
    default = "vpc-006f84d06141afbec"
}

variable "nodes_qty" {
    description = "The number of worker nodes."
    type = string
    default = "1"
}