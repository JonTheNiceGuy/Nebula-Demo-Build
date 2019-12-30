resource "aws_subnet" "Public" {
  vpc_id                  = "${aws_vpc.VPC.id}"
  cidr_block              = "${var.public_first_three_octets}.0/24"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "s${var.modulename}_public"
  }
}

resource "aws_route_table" "Public" {
  vpc_id = "${aws_vpc.VPC.id}"
  tags = {
    Name = "r${var.modulename}_public"
  }
}

resource "aws_route" "PublicDefault" {
  route_table_id = "${aws_route_table.Public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.InternetGateway.id}"
}

resource "aws_route_table_association" "PublicAssociation" {
  subnet_id = "${aws_subnet.Public.id}"
  route_table_id = "${aws_route_table.Public.id}"
}