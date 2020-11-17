terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# # Configure the AWS Provider
provider "aws" {
  region     = "ap-south-1"
}

# # 1. Create vpc

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

# # 2. Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

}

# # 3. Create Custom Route Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# # 4. Create a Subnet 

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "prod-subnet"
  }
}

# # 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# # 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# # 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# # 8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

variable "credentials_file" {
  default = TF_VAR_key
}

# # 9. Create ubuntu instance and install/enable docker

resource "aws_instance" "web-server-instance" {
  ami               = "ami-0a4a70bd98c6d6441"
  instance_type     = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name          = "my_access"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  # user_data = <<-EOF
  #             #!/bin/bash
  #             cd ~
  #             sudo apt update
  #             sudo apt -y install docker.io
  #             sudo systemctl enable --now docker
  #             EOF

  # provisioner "remote-exec" {
  #   inline = [
  #     "cd ~",
  #     "sudo apt update",
  #     "sudo apt -y install docker.io",
  #     "sudo systemctl enable --now docker",
  #     "sudo groupadd docker",
  #     "sudo usermod -aG docker $USER"
  #   ]
  # } 
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${var.credentials_file}"
  }
  provisioner "file" {
    source = "projfiles"
    destination = "/home/ubuntu"
  }
  # provisioner "remote-exec" {
  #   inline = [
  #     "docker stop nodejs-demo",
  #     "docker rm -f nodejs-demo",
  #     "docker image rm -f nodejs-demo",
  #     "docker build -t nodejs-demo .",
  #     "docker run -d --name nodejs-demo -p 8090:3000 nodejs-demo"
  #   ]
  # }

  tags = {
    Name = "web-server"
  }
}