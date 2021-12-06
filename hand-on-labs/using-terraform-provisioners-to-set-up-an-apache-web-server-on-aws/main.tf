provider "aws" {
  region = "us-east-1"
}

locals {
  prefix = "${var.product_name}_${var.environment}"
}

################################################################################
# Supporting Resources
################################################################################

# Create key-pair for logging into EC2 in us-east-1
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "webserver_key" {
  key_name  = "webserver_key"
  public_key = file("${var.public_key_path}")
  tags = {
    Name = "${local.prefix}_VPC_Main"
  }
}

# Get Linux AMI ID using SSM Parameter endpoint in us-east-1
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter
data "aws_ssm_parameter" "webserver-ami" {
  # Query for the latest Amazon Linux AMI IDs using AWS Systems Manager Parameter Store
  # Parameter Store Prefix (tree): /aws/service/ami-amazon-linux-latest/
  # AMI name alias: (example) amzn-ami-hvm-x86_64-gp2
  # https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Create VPC in us-east-1
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "vpc" {
  # RFC1918: http://www.faqs.org/rfcs/rfc1918.html
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.prefix}_VPC_Main"
  }
}

# Create IGW in us-east-1
resource "aws_internet_gateway" "igw" {
  # Attach IGW to VPC Main
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.prefix}_IGW_Main"
  }
}

# Get main route table to modify
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_table
data "aws_route_table" "main_route_table" {
  # Describes one or more of your route tables
  # https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeRouteTables.html
  filter {
    name   = "association.main"
    values = ["true"]
  }
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc.id]
  }
}

# Create route table in us-east-1
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table
resource "aws_default_route_table" "internet_route" {
  default_route_table_id = data.aws_route_table.main_route_table.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.prefix}_RouteTable_Main"
  }
}

# Get all available AZ's in VPC for master region
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones
data "aws_availability_zones" "azs" {
  state = "available"
}

# Create subnet #1 in us-east-1
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "subnet" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "${local.prefix}_Subnet_Main"
  }
}

# Create security group for allowing TCP/80 & TCP/22
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "sg" {
  description = "Allow TCP/80 & TCP/22"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow TCP/80 traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Semantically equivalent to all
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}_SecurityGroup_Main"
  }
}

################################################################################
# EC2 Module
################################################################################

# Create and bootstrap webserver
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "webserver" {
  ami                         = data.aws_ssm_parameter.webserver-ami.value
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.webserver_key.key_name
  monitoring                  = true
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install httpd",
      "sudo systemctl start httpd",
      "echo '<h1><center>Demo Website With Help From Terraform Provisioner</center></h1>' > index.html",
      "sudo mv index.html /var/www/html/",
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.private_key_path}")
      host        = self.public_ip
    }
  }
  tags= {
    Name = "${local.prefix}_EC2_Webserver"
  }
}
