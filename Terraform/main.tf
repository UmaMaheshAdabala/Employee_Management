# VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "myVPC"
  }
}


#Subnet - Public
resource "aws_subnet" "my-public-subnet" {
  vpc_id                  = aws_vpc.my-vpc.id
  count                   = 2
  availability_zone       = var.my-public-subnet.availability_zone[count.index]
  cidr_block              = var.my-public-subnet.cidr_block[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = var.my-public-subnet.name[count.index]
  }
}

#Subnet - Private
resource "aws_subnet" "my-private-subnet" {
  vpc_id            = aws_vpc.my-vpc.id
  count             = 2
  availability_zone = var.my-private-subnet.availability_zone[count.index]
  cidr_block        = var.my-private-subnet.cidr_block[count.index]
  tags = {
    Name = var.my-private-subnet.name[count.index]
  }
}

# IGW
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "myIGW"
  }
}

#Public Route Table
resource "aws_route_table" "my-public-rt" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "myPublicRT"
  }
}

#Public Route
resource "aws_route" "my-route" {
  route_table_id         = aws_route_table.my-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my-igw.id
}

#Private Route Table
resource "aws_route_table" "my-private-rt" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "myPrivateRT"
  }
}

#Public Route Association 
resource "aws_route_table_association" "my-public-route-association" {
  route_table_id = aws_route_table.my-public-rt.id
  count          = 2
  subnet_id      = aws_subnet.my-public-subnet[count.index].id
}

#Private Route Association
resource "aws_route_table_association" "my-private-route-association" {
  route_table_id = aws_route_table.my-private-rt.id
  count          = 2
  subnet_id      = aws_subnet.my-private-subnet[count.index].id
}

#Security Group for ALB
resource "aws_security_group" "my-alb-sg" {
  name   = "myALBSG"
  vpc_id = aws_vpc.my-vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# #Security Group for ECS
# resource "aws_security_group" "my-ecs-sg" {
#   name   = "myECSSG"
#   vpc_id = aws_vpc.my-vpc.id
#   ingress {
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.my-alb-sg.id]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# #Security group for RDS
# resource "aws_security_group" "my-rds-sg" {
#   name   = "myRDSSG"
#   vpc_id = aws_vpc.my-vpc.id
#   ingress {
#     from_port       = 3306
#     to_port         = 3306
#     protocol        = "tcp"
#     security_groups = [aws_security_group.my-ecs-sg.id]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # RDS Subnetgroup

# resource "aws_db_subnet_group" "my-rds-subnet" {
#   name       = "myRDSSubnetGroup"
#   subnet_ids = [aws_subnet.my-private-subnet[0].id]
# }

# # Mysql RDS
# resource "aws_db_instance" "my-sql-rds" {
#   identifier             = "employees-db"
#   engine                 = "mysql"
#   engine_version         = "8.0"
#   instance_class         = "db.t3.micro"
#   allocated_storage      = 20
#   db_name                = "employees_db"
#   username               = var.db-username
#   password               = var.db-password
#   db_subnet_group_name   = aws_db_subnet_group.my-rds-subnet.id
#   vpc_security_group_ids = [aws_security_group.my-rds-sg.id]
#   skip_final_snapshot    = true
#   publicly_accessible    = false
#   multi_az               = false
#   tags = {
#     Name = "mySQLRDS"
#   }
# }

#ALB
resource "aws_lb" "my-alb" {
  name               = "myALB"
  load_balancer_type = "application"
  subnets            = [aws_subnet.my-public-subnet[0].id, aws_subnet.my-public-subnet[1].id]
  security_groups    = [aws_security_group.my-alb-sg.id]
  internal           = false
}

#ALB Target Group(Frontend)
resource "aws_alb_target_group" "my-alb-tg-frontend" {
  name     = "myTGFrontend"
  vpc_id   = aws_vpc.my-vpc.id
  port     = 80
  protocol = "HTTP"
}

#ALB Target Group(Backend)
resource "aws_alb_target_group" "my-alb-tg-backend" {
  name     = "myTGBackend"
  vpc_id   = aws_vpc.my-vpc.id
  port     = 3000
  protocol = "HTTP"
  health_check {
    path                = "/api/auth/adminlogin"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#ALB Listener (fronend by default)
resource "aws_alb_listener" "my-alb-listener" {
  load_balancer_arn = aws_lb.my-alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.my-alb-tg-frontend.arn
  }
}

#ALB Listener rule
resource "aws_alb_listener_rule" "my-alb-listener-backend" {
  listener_arn = aws_alb_listener.my-alb-listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.my-alb-tg-backend.arn
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# #Role for Task Definition
# resource "aws_iam_role" "my-exec-role" {
#   name               = "myExecutionRole"
#   assume_role_policy = data.aws_iam_policy_document.assume-role.json
# }

# #Policy Doc
# data "aws_iam_policy_document" "assume-role" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }

# #Attach Permission
# resource "aws_iam_role_policy_attachment" "name" {
#   role       = aws_iam_role.my-exec-role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }


# #ECR REPO(frontend)
# resource "aws_ecr_repository" "my-ecr-frontend" {
#   name = "myECRRepoFrontend"
# }

# #ECR Repo(Backend)
# resource "aws_ecr_repository" "my-ecr-backend" {
#   name = "myECRRepoBackend"
# }

# # ECS Cluster
# resource "aws_ecs_cluster" "my-ecs-cluster" {
#   name = "myECSCLUSTER"
# }

# #Task Definition (frontend)
# resource "aws_ecs_task_definition" "my-task-frontend" {
#   family                   = "myECSTaskFrontend"
#   container_definitions    = <<DEFINITION
#   [
#     {
#       "name" : "my-frontend-container",
#       "image" : "${aws_ecr_repository.my-ecr-frontend.repository_url}",
#       "essential" : true,
#       "portMappings" : [
#         {
#           "containerPort" : 80,
#           "hostPort" : 80,
#         }
#       ],
#       "memory" : 717,
#       "cpu" : 512,
#       environment = [
#         { 
#           name = "VITE_BACKEND_URL", value = "http://${aws_lb.alb.dns_name}/api" 
#         },
#         { 
#           name = "VITE_BACKEND_IMAGE", value = "http://${aws_lb.alb.dns_name}/Images/" 
#         }
#       ]
#     }
#   ]
#   DEFINITION
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   memory                   = 717
#   cpu                      = 512
#   execution_role_arn       = aws_iam_role.my-exec-role.arn
# }

# #Task Definition (Backend)
# resource "aws_ecs_task_definition" "my-task-backend" {
#   family                   = "myECSBackend"
#   container_definitions    = <<DEFINITION
#   [ 
#     {
#       "name": "my-backend-container",
#       "image":"${aws_ecr_repository.my-ecr-backend.repository_url}",
#       "essential":true,
#       "portMappings":[
#         {
#           "containerPort" : 3000,
#           "hostPort": 3000
#         }
#       ],
#       "memory" : 717,
#       "cpu" : 512,
#        environment = [
#         { name = "DATABASE_ENDPOINT", value = aws_db_instance.mysql.address },
#         { name = "DATABASE_USER", value = aws_db_instance.mysql.username },
#         { name = "DATABASE_PASSWORD", value = aws_db_instance.mysql.password },
#         { name = "FRONTEND_URL", value = "http://${aws_lb.alb.dns_name}" },
#       ]
#     }
#   ]
#   DEFINITION
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   memory                   = 717
#   cpu                      = 512
#   execution_role_arn       = aws_iam_role.my-exec-role.arn
# }


# # ECS service (frontend)
# resource "aws_ecs_service" "my-ecs-service-frontend" {
#   name            = "myECSFrontendService"
#   cluster         = aws_ecs_cluster.my-ecs-cluster.id
#   task_definition = aws_ecs_task_definition.my-task-frontend.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"
#   network_configuration {
#     subnets          = [aws_subnet.my-private-subnet[1].id]
#     security_groups  = [aws_security_group.my-ecs-sg.id]
#     assign_public_ip = true
#   }
#   load_balancer {
#     target_group_arn = aws_alb_target_group.my-alb-tg-frontend.arn
#     container_name   = "my-frontend-container"
#     container_port   = 80
#   }
#   depends_on = [aws_alb_listener.my-alb-listener]
# }


# #ECS Service (backend)
# resource "aws_ecs_service" "my-ecs-service-backend" {
#   name            = "myECSBackendService"
#   cluster         = aws_ecs_cluster.my-ecs-cluster.id
#   task_definition = aws_ecs_task_definition.my-task-backend.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"
#   network_configuration {
#     subnets          = [aws_subnet.my-private-subnet[1].id]
#     security_groups  = [aws_security_group.my-ecs-sg.id]
#     assign_public_ip = false
#   }
#   load_balancer {
#     target_group_arn = aws_alb_target_group.my-alb-tg-backend.arn
#     container_name   = "my-backend-container"
#     container_port   = 3000
#   }
#   depends_on = [aws_alb_listener.my-alb-listener]
# }
