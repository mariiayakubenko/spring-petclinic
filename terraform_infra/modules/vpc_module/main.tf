#VPC

resource "aws_vpc" "terraform_vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.project}_vpc"
  }
}

resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "${var.project}_gw"
  }
}

resource "aws_route_table" "terraform_vpc_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_gw.id
  }

  tags = {
    Name = "${var.project}_vpc_rt"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 4, 0)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}_public_subnet"
  }
}

resource "aws_route_table_association" "terraform_vpc_rt" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.terraform_vpc_rt.id
}
