# Variable that holds the CIDR block for the VPC
variable "agent_vpc_cidr_block" {
    description = "CIDR block for the VPC agent is deployed in."
    type = string
    default = "10.5.0.0/16"
}

# Creating the VPC resource
resource "aws_vpc" "worker_vpc" {
    # Setting the CIDR block of the VPC to the variable agent_vpc_cidr_block
    cidr_block = var.agent_vpc_cidr_block

    # Enabling DNS hostnames on the VPC
    enable_dns_hostnames = true

    # Setting the tag Name to worker_vpc
    tags = {
        Name = "worker_vpc"
    }
}

# Creating the Internet Gateway resource
resource "aws_internet_gateway" "agent_igw" {
    vpc_id = aws_vpc.worker_vpc.id

    tags = {
        Name = "agent_igw"
    }
}

# Creating the public route table resource
resource "aws_route_table" "agent_public_rt" {
    vpc_id = aws_vpc.worker_vpc.id

    # Adding the IGW to the route table
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.agent_igw.id
    }
}

# Var for holding the CIDR block for the public subnet
variable "agent_public_subnet_cidr_block" {
    description = "CIDR block for the public subnet."
    type = string
    default = "10.5.1.0/24"
}

# Fetch from AWS API the available AZs in the region
# data "aws_availability_zones" "available" {
#     state = "available"
# }

# Creating the public subnet
resource "aws_subnet" "agent_public_subnet" {
    vpc_id = aws_vpc.worker_vpc.id
    cidr_block = var.agent_public_subnet_cidr_block
    availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true

    tags = {
        Name = "tutorial_public_subnet"
    }
}

# Associating the public subnet with the public route table
resource "aws_route_table_association" "agent_public" {
    route_table_id = aws_route_table.agent_public_rt.id
    subnet_id = aws_subnet.agent_public_subnet.id
}