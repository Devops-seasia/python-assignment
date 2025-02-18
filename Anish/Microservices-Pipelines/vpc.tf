resource "aws_vpc" "test-vpc" {
  cidr_block       = "145.0.0.0/16"
  instance_tenancy = "default"            
  enable_dns_hostnames    = true

  tags = {
    Name = "test-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test-vpc.id
  tags = {                                
    "Name" = "igw"
  }
}


resource "aws_route_table" "routeigm" {
  vpc_id = aws_vpc.test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id    
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "145.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "subnet-1"                  
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "145.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    "Name" = "subnet-2"
  }
}

resource "aws_route_table_association" "table-a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.routeigm.id
}                                                     

resource "aws_route_table_association" "table-b" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.routeigm.id
}