# Create a VPC
data "aws_availability_zones" "available" {}

resource "aws_vpc" "principal" {
  cidr_block = "10.0.0.0/16"
  tags       = merge({"Name"="${var.environment}-VPC"},var.infra_tags)

}
#Create Public Subnets
resource "aws_subnet" "public" {
  count                   = var.num_subnet_public
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "${var.prefix_cidr_block}.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags                    = merge({"Name"="Public-${count.index}", "Type"= "Public"  },var.infra_tags)
  #depends_on = [aws_vpc.principal]
}

resource "aws_subnet" "private" {
  count = var.num_subnet_private
  vpc_id = aws_vpc.principal.id
  cidr_block = "${var.prefix_cidr_block}.${count.index+6}.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags                    = merge({"Name"="Private-${count.index}", "Type"= "Private"  },var.infra_tags)
}



#Create Internet GW for the public subnets
resource "aws_internet_gateway" "GW-FrontEnd-Public" {
  vpc_id = aws_vpc.principal.id

  tags = merge({"Name"="GW-FrontEnd-Public"},var.infra_tags)

}

#Create the route table with default route for the public subnets
resource "aws_route_table" "RT-FrontEnd-Public" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.GW-FrontEnd-Public.id
  }

  tags = merge({"Name"="RT-FrontEnd-Public"},var.infra_tags)
}

#Associate Public Subnets with the Route table
resource "aws_route_table_association" "rt-public-association" {
   count          = length(aws_subnet.public)
   subnet_id      = aws_subnet.public[count.index].id
   route_table_id =  aws_route_table.RT-FrontEnd-Public.id

}
