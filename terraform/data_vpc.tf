# # lookup for the "default" VPC
# data "aws_vpc" "jenkins_vpc" {
#   id = var.vpc_id
# }

# # subnet list in the "default" VPC
# # The "default" VPC has all "public subnets"
# data "aws_subnets" "jenkins_public" {
#   filter {
#     name = "vpc-id"
#     values = [data.aws_vpc.jenkins_vpc.id]
#   }
# }
