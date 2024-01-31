#providing provider and version
terraform {
  required_providers {
  aws = {
    source = "hashicrop/aws"
    version = "5.31.0"
  }    
  }
}
#creating virtual private cloud
resource "aws_vpc" "Prod-vpc" {
    cidr_block = "192.168.0.0/16"
    region = "eu-west-1" 
    tags = {
        Name = "client-vpc"
    } 
}
#creating internet gateway
resource "aws_internet_gateway" "Prod-igw" {
    vpc_id = aws_vpc.Prod-vpc_id
    tags = {
        Name = "prod-igw"
    }
  
}
#creating web-subnets
resource "aws_subnet" "web-subnet-1" {
    vpc_id = aws_vpc.Prod-vpc_id
    cidr_block = "192.168.1.0/24"
    availability_zone = "eu-west-1a"
    map_public_ip_on_lanuch = true
    tags = {
        Name = "web-subnet-1"
    }
  
}
resource "aws_subnet" "web-subnet-2" {
    vpc_id = aws_vpc.Prod-vpc_id
     cidr_block = "192.168.2.0/24"
     availability_zone = "eu-west-1a"
     map_public_ip_on_lanuch = true
    tags = {
        Name = "web-subnet-2"
    } 
}
#creating applicaton subnets
resource "aws_subnet" "app-subnet-1" {
    vpc_id = aws_vpc.Prod-vpc_id 
    cidr_block = "192.168.12.0/24"
    availability_zone = "eu-west-1b" 
    map_public_ip_on_lanuch = false
    tags = {
        Name = "app-subnet-1"
    }
}
resource "aws_subnet" "app-subnet-2" {
    vpc_id = aws_vpc.Prod-vpc.id
    cidr_block = "192.168.13.0/24"
    availability_zone = "eu-west-1b"
    map_public_ip_on_lanuch = false
    tags = {
       Name = "app-subnet-2" 
    }
  
}
#creating database subnets
resource "aws_subnet" "db-subnet-1" {
  vpc_id = aws_vpc.Prod-vpc.id
  cidr_block = "192.168.31.0/24"
  availability_zone = "eu-west-1b"
  map_publi_ip_on_lanuch = false
  tags ={
    Name = "db-subnet-1"
  }
}
resource "aws_subnet" "db-subnet-2" {
  vpc_id = aws_vpc.Prod-vpc.id
  cidr_block = "192.168.32.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = false
  tags ={
    Name= "app-subnet-2"
  }
}
#creating web-route-table
resource "aws_route_table" "web-rt" {
    vpc_id = aws_vpc.Prod-vpc.id
 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Prod-igw.id
 }
 tags = {
    name = "web-rt"
 }
}
resource "aws_route_table_association" "web-rta" {
    subnet_id = aws_subnet.web-subnet-1
    route_table_id = aws_route_table.web-rt.id
  
}
resource "aws_route_table_association" "web-rta-2" {
    subnet_id = aws_subnet.web-subnet-2
    route_table_id = aws_route_table.web-rt.id
  
}
#creating web-server security group
resource "aws_security_group" "web-sg" {
   name = "web-server-sg"
   description = "creating security group for web-server"
   vpc_id = aws_vpc.Prod-vpc.id

ingress {
    description = "allow HTTP"
    from_port = 22
    to_port = 22
    protocal = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }

ingress {
    description = "Alllow HTTP from VPC"
    from_port = 80
    to_port = 80
    protocal = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}  
egress {
    from_port = 0
    to_port = 0 
    protocal = "-1"
    cidr_blocks= ["0.0.0.0/0"]
}
tags = {
    Name = "web-sg"
}
}
#creating app-security group 
resource "aws_security_group" "app-sg" {
    name = "app-server-sg"
    description = "creating security group fro app-server"
    vpc_id = aws_vpc.Prod-vpc.id
  ingress {
    description = "Allow HTTP"
    from_port = 22
    to_port= 22
    protocal = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP"
    from_port = 80 
    to_port = 80
    protocal = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocal = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "app-sg"
  }
}
#creating database security group
resource "aws_security_group"  "db-sg" {
    name = "db-server-sg"
    description = "creating security group for db-server"
    vpc_id = aws_vpc.Prod-vpc.id

ingress {
        description = "Allow MYSQL"
        from_port = 3306
        to_port = 3306
        protocal = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
ingress {
    description = "Allow POSTGRES"
    from_port = 5042
    to_port = 5042
    protocal = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 32768
    to_port = 65535
    protocal = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Name = "db-sg"
  }
}
#creating WEB-SERVERS 
resource "aws_instance" "web-server-1" {
    ami = "ami-0fef2f5dd8d0917e8"
    instance_type = "t2.micro"
    key_name = "irelandkey"
    availability_zone = "eu-west-1a"
    subnet_id = aws_subnet.web-subnet-1.id
    vpc_security_group_ids = [aws_security_group.web-sg.id]
    user_data = "${file(apache.sh)}"
    tags = {
        Name = "web-server1"
    }
  
}
resource "aws_instance" "web-server-2" {
    ami = "ami-0fef2f5dd8d0917e8"
    instance_type = "t2.micro"
    key_name = "irelandkey"
    availability_zone = "eu-west-1a"
    subnet_id = aws_subnet.web-subnet-2.id
    vpc_security_group_ids = [aws_security_group.web-sg.id]
    user_data = "${file(apache.sh)}"
    tags = {
        Name = "web-server2"
    }
  
}
#creating load balancer
resource "aws_lb" "external-elb" {
  name = "external lb"
  internal = false
  security_group = [aws_security_group.web-sg.id]
  subnets = [aws_subnet.web-subent-1.id,aws_subnet.web-subnet-2].id
}
#creating target group and attaching to lb
resource "aws_lb_target_group" "external-lb-tg" {
    name = "lb-tg"
    port = 80
    protocal   = "HTTP"
    vpc_id = aws_vpc.Prod-vpc.id
}
resource "aws_lb_target_group_attachment" "lb-tg-1" {
    target_group_arn = aws_lb_target_group.external-lb-tg.arn
    target_id = aws_instance.web-server1.id
    port = 80
    depends_on = [ 
        aws_instance.web-server1,
     ]
  
}
resource "aws_lb_target_group_attachment" "lb-tg-2" {
    target_group_arn = aws_lb_target_group.external-lb-tg.arn
    target_id = aws_instance.web-server-2.id
    port = 80
    depends_on = [ 
        aws_instance.web-server2,
     ]
  
}
resource "aws_lb_listner" "listner-lb" {
    load_balancer_arn = aws_lb.external-elb.arn
    port = 80
    protocal = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.external-lb-tg.arnccc
  }
}
resource "aws_db_instance" "db-ec2" {
    allocated_storage = 10
    db_subnet_group_name = aws_subnet.db-subnet-1.id
    engine = "mysql"
    engine_version = "8.0.28"
    instance_class = "db.t2.micro"
    multi_az = false
    db_name = "mysql"
    username = "chintu"
    password = "chintu123"
    final_snapshot = false
    vpc_security_group_ids = [aws_security_group.db-sg.id]
}
resource "aws_db_subnet_group" "deafult" {
    name = "main"
    subnet_ids = [aws_subnet.db-subnet-1.id,aws_subnet.db-subnet-2.id]
    tags = {
        Name = "db-subnet-group"
    }
}
output "lb_dns_name" {
    description = "select the dns name of lb"
  value = aws_lb.external-elb.dns_name
}
