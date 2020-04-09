# Create Production VPC
data "aws_availability_zones" "available" {}

resource "aws_vpc" "principal" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags       = {
    Name="Main-VPC"
    Module  = var.moduleIdentification
    Team    = var.team
  }
}

#Create Testing VPC environment
resource "aws_vpc" "testing" {
  cidr_block = var.vpc_cidr_block_testing
  enable_dns_hostnames = true
  tags       = {
    Name="Testing-VPC"
    Module  = var.moduleIdentification
    Team    = var.team
    Environment = "testing"
  }
}
#Create Production Public Subnets
resource "aws_subnet" "public" {
  count                   = var.n_subnet_public
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "${var.prefix_cidr_block}.${count.index+var.cidr_prefix_start_public}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags                    = {
    Name    = "Subnet-Prod-Pub-${count.index+var.cidr_prefix_start_public}"
    Type    = "Public"
    Module  = var.moduleIdentification
    Team    = var.team
    Environment = "production"
  }
  #depends_on = [aws_vpc.principal]
}

#Create Testing Public Subnets
resource "aws_subnet" "public_testing" {
  count                   = var.n_subnet_public
  vpc_id                  = aws_vpc.testing.id
  cidr_block              = "${var.prefix_cidr_block_testing}.${count.index+var.cidr_prefix_start_public}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags                    = {
    Name    = "Subnet-Test-Pub-${count.index+var.cidr_prefix_start_public}"
    Type    = "Public"
    Module  = var.moduleIdentification
    Team    = var.team
    Environment = "testing"
  }
  #depends_on = [aws_vpc.principal]
}

#Create Production Private Subnets (RDS instances will be inside here)
resource "aws_subnet" "private" {
  count                   = var.n_subnet_private
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "${var.prefix_cidr_block}.${count.index+var.cidr_prefix_start_private}.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags                    = {
    Name    = "Subnet-Prod-Priv-${count.index+var.cidr_prefix_start_private}"
    Type    = "Private"
    Module  = var.moduleIdentification
    Team    = var.team
    Environment = "production"
  }
}

#Create Testing Private Subnets (RDS instances will be inside here)
resource "aws_subnet" "private_testing" {
  count                   = var.n_subnet_private
  vpc_id                  = aws_vpc.testing.id
  cidr_block              = "${var.prefix_cidr_block_testing}.${count.index+var.cidr_prefix_start_private}.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags                    = {
    Name    = "Subnet-Test-Priv-${count.index+var.cidr_prefix_start_private}"
    Type    = "Private"
    Module  = var.moduleIdentification
    Team    = var.team
    Environment = "testing"
  }
}

#Create Internet GW for the production public subnets
resource "aws_internet_gateway" "GW-Prod-Public" {
  vpc_id  = aws_vpc.principal.id
  tags    = {
    Name="GW-Prod-Public"
    Module  = var.moduleIdentification
    Team    = var.team
    Environment = "production"
  }

}

#Create Internet GW for the testing public subnets
resource "aws_internet_gateway" "GW-Test-Public" {
  vpc_id  = aws_vpc.testing.id
  tags    = {
    Name="GW-Test-Public"
    Module  = var.moduleIdentification
    Team    = var.team
    Environment = "testing"
  }

}

#Create the route table with default route for the production public subnets
resource "aws_route_table" "RT-Prod-Public" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.GW-Prod-Public.id
  }

  tags = {
    Name="RT-Prod-Public"
    Module  = var.moduleIdentification
    Team    = var.team
    Environment = "production"
  }
}

#Create the route table with default route for the testing public subnets
resource "aws_route_table" "RT-Test-Public" {
  vpc_id = aws_vpc.testing.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.GW-Test-Public.id
  }

  tags = {
    Name="RT-Test-Public"
    Module  = var.moduleIdentification
    Team    = var.team
    Environment = "testing"
  }
}

#Associate Production Public Subnets with the Route table
resource "aws_route_table_association" "rt-public-association" {
   count          = length(aws_subnet.public)
   subnet_id      = aws_subnet.public[count.index].id
   route_table_id =  aws_route_table.RT-Prod-Public.id
}

#Associate Testing Public Subnets with the Route table
resource "aws_route_table_association" "rt-testing-public-association" {
   count          = length(aws_subnet.public_testing)
   subnet_id      = aws_subnet.public_testing[count.index].id
   route_table_id =  aws_route_table.RT-Test-Public.id
}
