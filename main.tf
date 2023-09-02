resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "mtc_public_subnet" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev_public_rt"
  }

}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtc_internet_gateway.id

}

resource "aws_route_table_association" "mtc_public_assoc" {
  subnet_id      = aws_subnet.mtc_public_subnet.id
  route_table_id = aws_route_table.mtc_public_rt.id
}

resource "aws_security_group" "mtc_sg" {

  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }

}

# Create a network interface
resource "aws_network_interface" "test-web-server-nic" {
  subnet_id       = aws_subnet.mtc_public_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.mtc_sg.id]

}

# Assign an Elastic IP
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.test-web-server-nic.id
  associate_with_private_ip = "10.0.1.50"

}

resource "aws_key_pair" "mtc_auth" {
  key_name   = "mtckey"
  public_key = file("~/.ssh/mtckey.pub")
}

resource "aws_instance" "web_server" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server-ami.id
  key_name               = aws_key_pair.mtc_auth.id
  
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.test-web-server-nic.id
  }
  
  root_block_device {
    volume_size = 10
  }

  user_data = "${file("install_apache.sh")}"


  tags = {
    Name = "dev-node"
  }
}