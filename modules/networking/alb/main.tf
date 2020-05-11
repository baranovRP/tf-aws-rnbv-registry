###
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "tf-registry-alb"

  load_balancer_type = "application"

  vpc_id          = data.aws_vpc.default.id
  subnets         = data.aws_subnet_ids.all.ids
  security_groups = [module.security_group_alb.this_security_group_id]

  target_groups = [
    {
      name_prefix      = "defl"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Dev"
  }
}

module "security_group_alb" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"
  vpc_id  = data.aws_vpc.default.id

  name        = "tf-registry-alb-sg"
  description = "Security group usage with alb"

  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]
  ingress_rules            = ["http-80-tcp", "all-icmp"]
  egress_rules             = ["all-all"]
}
