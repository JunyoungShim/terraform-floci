# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.system_name}-${var.enviroment}-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]

  tags = {
    Name = "${var.system_name}-${var.enviroment}-public-subnet${count.index + 1}"
  }
}

# Protect Subnet
resource "aws_subnet" "protect_subnet" {
  count = length(var.protect_subnet_cidrs)

  vpc_id = aws_vpc.main.id
  cidr_block = var.protect_subnet_cidrs[count.index]

  tags = {
    Name = "${var.system_name}-${var.enviroment}-protect-subnet${count.index + 1}"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  
  tags = {
    Name = "${var.system_name}-${var.enviroment}-private-subnet${count.index + 1}"
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  tags = {
    Name = "${var.system_name}-${var.enviroment}-igw"
  }
}
resource "aws_internet_gateway_attachment" "igw_attach" {
  vpc_id = aws_vpc.main.id
  internet_gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.system_name}-${var.enviroment}-public-rt"
  }
}

resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_rt.id
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "protect_rt" {
  count = length(var.protect_subnet_cidrs)
  
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.system_name}-${var.enviroment}-protect-rt${count.index + 1}"
  }
}

resource "aws_route_table" "private_rt" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.system_name}-${var.enviroment}-private-rt${count.index + 1}"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "image-bucket" {
  bucket = "${var.system_name}-${var.enviroment}-image-bucket"
}