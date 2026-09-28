# VPC creation
resource "aws_vpc" "name" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "MyVPC"
  }
}

#public subnet creation 
resource "aws_subnet" "public_subnet"{
    vpc_id = aws_vpc.name.id
    cidr_block = var.subnet_cidr
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "MyPublicSubnet"
    }
}

#internet gateway creation
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.name.id
    tags = {
        Name = "MyInternetGateway"
    }
}

#route table creation
resource "aws_route_table" "public_rt"{
    vpc_id = aws_vpc.name.id
    tags = {
        Name = "MyPublicRouteTable"
    }
}

#route creation 
resource "aws_route" "route"{
    route_table_id = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

#route table association 
resource "aws_route_table_association" "public_rt_association"{
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt.id
}

#security group craetion
resource "aws_security_group" "sg"{
    name = "MySecurityGroup"
    description = "Allow SSH and HTTP"
    vpc_id = aws_vpc.name.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#ec2 instance creation
resource "aws_instance" "web" {
    ami = "ami-0e34b50e714a297f1"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.sg.id]
    tags = {
        Name = "MyWebServer"
    }
}

#private subnet creation
resource "aws_subnet" "private_subnet"{
    vpc_id = aws_vpc.name.id
    cidr_block = var.private_subnet_cidr
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = false
    tags = {
        Name = "MyPrivateSubnet"
    }
}

#EIP creation for NAT Gateway
resource "aws_eip" "eip" {
    domain = "vpc"
}

#nat craetion
resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.eip.id
    subnet_id = aws_subnet.public_subnet.id
    tags = {
        Name = "MyNATGateway"
    }
}

#private route table creation
resource "aws_route_table" "private_rt"{
    vpc_id = aws_vpc.name.id
    tags = {
        Name = "MyPrivateRouteTable"
    }
    
}

#private nat route creation
resource "aws_route" "private_route"{
    route_table_id = aws_route_table.private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id  

}

#private route table association
resource "aws_route_table_association" "private_rt_association"{
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt.id
}

#private ec2 instance creation
resource "aws_instance" "private_web" {
    ami = "ami-0e34b50e714a297f1"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.private_subnet.id
    vpc_security_group_ids = [aws_security_group.sg.id]
    tags = {
        Name = "MyPrivateWebServer"
    }
}