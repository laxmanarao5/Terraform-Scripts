provider "aws"{
    region = "ap-south-2"
    access_key = "AKIAZO3GJMFHJNPSN44Y"
    secret_key = "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"
}

# resource "aws_instance" "third"{
#     ami             = "ami-0ce4e694de0a4848c"
#     instance_type   = "t3.micro"
# } 

# resource "aws_instance" "second"{
#     ami             = "ami-0ce4e694de0a4848c"
#     instance_type   = "t3.micro"
#     tags = {
#         Name = "Second_instance"
#     }
# } 

# 1. Create VPC
resource "aws_vpc" "first_private_network"{
    cidr_block="10.0.1.0/24"
    tags = {
        Name = "First network"
    }

}


#2. Create Internet Gateway
resource "aws_internet_gateway" "gw"{
    vpc_id= aws_vpc.first_private_network.id
}


# 3 .Create Custom Route Table
resource "aws_route_table" "routes"{
    vpc_id= aws_vpc.first_private_network.id

    route{
        cidr_block= "0.0.0.0/0"
        gateway_id= aws_internet_gateway.gw.id
    }

    route{
        ipv6_cidr_block = "::/0"
        gateway_id= aws_internet_gateway.gw.id
    }
    tags={
        Name = "Routing table for portfolio"
    }
}

# 4. Create subnet

resource "aws_subnet" "sub_network"{
    vpc_id= aws_vpc.first_private_network.id
    cidr_block="10.0.1.0/24"
    availability_zone= "ap-south-2a"
    map_public_ip_on_launch = true
    tags = {
        Name = "First sub_network"
    }

}

# 5. Associate Routing table 
resource "aws_route_table_association" "association"{
    subnet_id = aws_subnet.sub_network.id
    route_table_id= aws_route_table.routes.id
}


# 6. Create security group 

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id= aws_vpc.first_private_network.id

  ingress {
    description      = "SSH Protocol"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_SSH_HTTP"
  }
}


# 7. creating network interface

resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.sub_network.id
  private_ips     = ["10.0.1.10"]
  
  security_groups = [aws_security_group.allow_tls.id]

}

# 8 . Create Elastic IP

# resource "aws_eip" "eip"{
#   vpc =  true
#   network_interface = aws_network_interface.test.id
#   tags={
#     Name = "Eip"
#   }
# }


# 8 . Start instance and install required applications

resource "aws_instance" "web-server"{
    ami             = "ami-0ce4e694de0a4848c"
    instance_type   = "t3.micro"
    key_name = "web-server"
    availability_zone= "ap-south-2a"
    network_interface{
      device_index=0
      network_interface_id= aws_network_interface.test.id
    }


    user_data = <<-EOF
                #!/bin/sh
                # Author : laxman
                sudo apt-get update
                sudo apt-get install docker-ce docker-compose-plugin
                EOF
    tags = {
        Name = "Second_instance"
    }
} 




#terraform init    - download required libraries
#terraform plan    - show additions,changes and removed resources
#terraform apply   - apply terraform plan
#terraform destroy - terminate resources

