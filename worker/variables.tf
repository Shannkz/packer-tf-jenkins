# variable "nodes_qty" {
#     description = "The number of worker nodes."
#     type = string
#     default = "1"
# }

data "aws_instance" "controller" {
    filter {
      name = "tag:Name"
      values = ["jenkins_server"]
    }
}