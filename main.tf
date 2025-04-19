resource "aws_vpc" "wordpress-workshop" {
  cidr_block           = "10.2.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "wordpress-workshop"
  }
}

resource "aws_subnet" "Public-Subnet-A" {
  vpc_id            = aws_vpc.wordpress-workshop.id
  cidr_block        = "10.2.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public-Subnet-A"
  }
}

resource "aws_subnet" "Public-Subnet-B" {
  vpc_id            = aws_vpc.wordpress-workshop.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public-Subnet-B"
  }
}

resource "aws_subnet" "Application-Subnet-A" {
  vpc_id            = aws_vpc.wordpress-workshop.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Application-Subnet-A"
  }
}

resource "aws_subnet" "Application-Subnet-B" {
  vpc_id            = aws_vpc.wordpress-workshop.id
  cidr_block        = "10.2.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Application-Subnet-B"
  }
}

resource "aws_subnet" "Data-Subnet-A" {
  vpc_id            = aws_vpc.wordpress-workshop.id
  cidr_block        = "10.2.4.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Data-Subnet-A"
  }
}

resource "aws_subnet" "Data-Subnet-B" {
  vpc_id            = aws_vpc.wordpress-workshop.id
  cidr_block        = "10.2.5.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Data-Subnet-B"
  }
}

resource "aws_internet_gateway" "WP-Internet-Gateway" {
  vpc_id = aws_vpc.wordpress-workshop.id

  tags = {
    Name = "WP-Internet-Gateway"
  }
}

resource "aws_internet_gateway_attachment" "WP-Internet-Gateway-Attachement" {
  internet_gateway_id = aws_internet_gateway.WP-Internet-Gateway.id
  vpc_id              = aws_vpc.wordpress-workshop.id
}

resource "aws_route_table" "WP-Public" {
  vpc_id = aws_vpc.wordpress-workshop.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.WP-Internet-Gateway.id
  }

  tags = {
    Name = "WP-Public"
  }
}

resource "aws_route_table_association" "WP-Public-Association-A" {
  subnet_id      = aws_subnet.Public-Subnet-A.id
  route_table_id = aws_route_table.WP-Public.id
}

resource "aws_route_table_association" "WP-Public-Association-B" {
  subnet_id      = aws_subnet.Public-Subnet-B.id
  route_table_id = aws_route_table.WP-Public.id
}

resource "aws_eip" "WP-Natgateway-A" {

  tags = {
    Name = "WP-Natgateway-A"
  }
}

resource "aws_eip" "WP-Natgateway-B" {

  tags = {
    Name = "WP-Natgateway-B"
  }
}

resource "aws_nat_gateway" "WP-Natgateway-A" {
  allocation_id = aws_eip.WP-Natgateway-A.id
  subnet_id     = aws_subnet.Public-Subnet-A.id

  tags = {
    Name = "WP-Natgateway-A"
  }

  depends_on = [aws_internet_gateway.WP-Internet-Gateway]
}

resource "aws_nat_gateway" "WP-Natgateway-B" {
  allocation_id = aws_eip.WP-Natgateway-B.id
  subnet_id     = aws_subnet.Public-Subnet-B.id

  tags = {
    Name = "WP-Natgateway-B"
  }

  depends_on = [aws_internet_gateway.WP-Internet-Gateway]
}

resource "aws_route_table" "RouteNat-A" {
  vpc_id = aws_vpc.wordpress-workshop.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.WP-Natgateway-A.id
  }

  tags = {
    Name = "RouteNat-A"
  }
}

resource "aws_route_table" "RouteNat-B" {
  vpc_id = aws_vpc.wordpress-workshop.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.WP-Natgateway-B.id
  }

  tags = {
    Name = "RouteNat-B"
  }
}

resource "aws_security_group" "WP-Database-Clients" {
  name        = "WP-Database-Clients"
  description = "Security group for wordpress database clients"
  vpc_id      = aws_vpc.wordpress-workshop.id

  tags = {
    Name = "WP-Database-Clients"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-A" {
  security_group_id = aws_security_group.WP-Database-Clients.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "WP-Database" {
  name        = "WP-Database"
  description = "Database instance security group"
  vpc_id      = aws_vpc.wordpress-workshop.id

  tags = {
    Name = "WP-Database"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_mysql-Aurora" {
  security_group_id            = aws_security_group.WP-Database.id
  referenced_security_group_id = aws_security_group.WP-Database.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

resource "aws_vpc_security_group_egress_rule" "allowl_traffic_ipv4-A" {
  security_group_id = aws_security_group.WP-Database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_db_subnet_group" "aurora-wordpress" {
  name       = "aurora-wordpress"
  subnet_ids = [aws_subnet.Data-Subnet-B.id, aws_subnet.Data-Subnet-A.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "wordpress-workshop" {
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "aurora-mysql"
  engine_version         = "8.0"
  instance_class         = "db.t4g.medium"
  username               = "wpadmin"
  password               = "Pass123*"
  parameter_group_name   = "default.mysql8.0"
  multi_az               = true
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.aurora-wordpress.id
  vpc_security_group_ids = [aws_security_group.WP-Database.id, aws_security_group.WP-Database-Clients.id]
}

resource "aws_security_group" "EFS-Clients" {
  name        = "EFS-Clients"
  description = "WP EFS Clients"
  vpc_id      = aws_vpc.wordpress-workshop.id

  tags = {
    Name = "EFS-Clients"
  }
}

resource "aws_vpc_security_group_egress_rule" "allw_all_traffic_ipv4-B" {
  security_group_id = aws_security_group.EFS-Clients.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "WP-EFS" {
  name        = "WP-EFS"
  description = "WP EFS"
  vpc_id      = aws_vpc.wordpress-workshop.id

  tags = {
    Name = "EFS"
  }
}

resource "aws_vpc_security_group_egress_rule" "pv4-B" {
  security_group_id = aws_security_group.WP-EFS.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_NFS" {
  security_group_id            = aws_security_group.WP-EFS.id
  referenced_security_group_id = aws_security_group.EFS-Clients.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}

resource "aws_efs_file_system" "my-efs" {
  creation_token = "my-efs"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "wordpress-EFS"
  }
}

resource "aws_efs_mount_target" "efs_mount_a" {
  file_system_id  = aws_efs_file_system.my-efs.id
  subnet_id       = aws_subnet.Data-Subnet-A.id
  security_groups = [aws_security_group.WP-EFS.id]

  depends_on = [aws_efs_file_system.my-efs]
}

resource "aws_efs_mount_target" "efs_mount_b" {
  file_system_id  = aws_efs_file_system.my-efs.id
  subnet_id       = aws_subnet.Data-Subnet-B.id
  security_groups = [aws_security_group.WP-EFS.id]

  depends_on = [aws_efs_file_system.my-efs]
}

resource "aws_security_group" "WP-Load-Balancer" {
  name        = "WP-Load-Balancer"
  description = "WP-Load-Balancer"
  vpc_id      = aws_vpc.wordpress-workshop.id

  tags = {
    Name = "EFS"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow-WP-Load-Balancer" {
  security_group_id = aws_security_group.WP-Load-Balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_WP-Load-Balancer" {
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.WP-Load-Balancer.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_security_group" "WP-Web-Server" {
  name        = "WP-Web-Server"
  description = "WP-Web-Server"
  vpc_id      = aws_vpc.wordpress-workshop.id

  tags = {
    Name = "WP-Web-Server"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow-WP-Web-Server" {
  security_group_id = aws_security_group.WP-Web-Server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_WP-Web-Server" {
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.WP-Web-Server.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_lb" "wordpress-alb" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.WP-Load-Balancer.id]
  subnets            = [aws_subnet.Application-Subnet-A.id, aws_subnet.Application-Subnet-B.id]

  enable_deletion_protection = true


  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "target" {
  name     = "target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.wordpress-workshop.id
  target_type = "instance"

  health_check {
    protocol = "HTTP"
    path = "/phpinfo.php"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.wordpress-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}

resource "aws_launch_template" "WP-WebServers-LT" {
  name        = "WP-WebServers-LT"
  description = "WP WebServers Launch template"

  image_id      = "ami-074254c177d57d640"
  instance_type = "t2.micro"
  key_name      = null

  vpc_security_group_ids = [
    aws_security_group.EFS-Clients.id,
    aws_security_group.WP-Database.id,
    aws_security_group.WP-Database-Clients.id
  ]

  user_data = filebase64("/mnt/c/Users/Administrator/Desktop/Scontinum/userdata.sh")

}

resource "aws_autoscaling_group" "Wordpress-ASG" {
  name                      = "Wordpress-ASG"
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 2
  vpc_zone_identifier       = [aws_subnet.Application-Subnet-A.id, aws_subnet.Application-Subnet-B.id]
  health_check_type         = "EC2"
  health_check_grace_period = 30

  launch_template {
    id      = aws_launch_template.WP-WebServers-LT.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.target.arn]

  tag {
    key                 = "Name"
    value               = "Wordpress-ASG"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "CPU-Tracking-Policy"
  autoscaling_group_name = aws_autoscaling_group.Wordpress-ASG.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value       = 80
  }
}
