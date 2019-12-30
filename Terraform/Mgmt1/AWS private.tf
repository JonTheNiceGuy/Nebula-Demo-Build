resource "aws_subnet" "Private" {
  depends_on = [aws_vpc_ipv4_cidr_block_association.private_cidr]
  vpc_id                  = "${aws_vpc.VPC.id}"
  cidr_block              = "${var.private_first_three_octets}.0/24"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "s${var.modulename}_private"
  }
}

resource "aws_eip" "NATGateway" {
  vpc = true
  depends_on = [aws_internet_gateway.InternetGateway]
}

# The NAT gateway *MUST* live in a Public subnet.
resource "aws_nat_gateway" "NATGateway" {
  allocation_id = "${aws_eip.NATGateway.id}"
  subnet_id     = "${aws_subnet.Public.id}"

  tags = {
    Name = "NATGateway"
  }
}

resource "aws_route_table" "Private" {
  vpc_id = "${aws_vpc.VPC.id}"
  tags = {
    Name = "r${var.modulename}_Private"
  }
}

resource "aws_route" "PrivateDefault" {
  route_table_id         = "${aws_route_table.Private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.NATGateway.id}"
}

resource "aws_route_table_association" "PrivateAssociation" {
  subnet_id = "${aws_subnet.Private.id}"
  route_table_id = "${aws_route_table.Private.id}"
}