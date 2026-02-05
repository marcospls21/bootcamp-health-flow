# Subnets públicas
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "hf-${var.env}-public-${count.index}"
    Tier = "public"
  }
}

# Subnets privadas para aplicações
resource "aws_subnet" "private_app" {
  count              = length(var.private_app_subnets)
  vpc_id             = aws_vpc.this.id
  cidr_block         = var.private_app_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "hf-${var.env}-app-${count.index}"
    Tier = "app"
  }
}

# Subnets privadas para dados
resource "aws_subnet" "private_data" {
  count              = length(var.private_data_subnets)
  vpc_id             = aws_vpc.this.id
  cidr_block         = var.private_data_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "hf-${var.env}-data-${count.index}"
    Tier = "data"
  }
}

