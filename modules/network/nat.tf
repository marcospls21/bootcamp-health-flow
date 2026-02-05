# Elastic IPs para os NATs
resource "aws_eip" "nat" {
  count  = length(aws_subnet.public)
  domain = "vpc"

  tags = {
    Name = "hf-${var.env}-eip-nat-${count.index}"
  }
}

# NAT Gateway por AZ
resource "aws_nat_gateway" "this" {
  count         = length(aws_subnet.public)
  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id

  tags = {
    Name = "hf-${var.env}-nat-${count.index}"
  }
}

