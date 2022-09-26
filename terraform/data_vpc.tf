# lookup for the "default" VPC
data "aws_vpc" "default_vpc" {
  default = true
}

# subnet list in the "default" VPC
# The "default" VPC has all "public subnets"
data "aws_subnets" "default_public" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}
