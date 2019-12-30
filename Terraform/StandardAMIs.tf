variable "ami_win2019" {
  description = "Name of the AWS AMI to use (Search AMI Name: Windows_Server-2019-English-Full-Base-*). Default is provided on 2019-11-25 in us-east-1"
  default = "ami-08b11fc5bd2026dee"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "ami_centos8" {
  description = "Name of the AWS AMI to use (Search AMI Name: aws-marketplace/centos 8). Default is provided on 2019-11-25 in us-east-1"
  default = "ami-0c8941e6fe84f9d6c"
}