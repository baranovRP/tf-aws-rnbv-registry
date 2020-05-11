###
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "tf-asg"

  # Launch configuration
  launch_configuration         = aws_launch_configuration.this.name
  create_lc                    = false
  recreate_asg_when_lc_changes = true
  target_group_arns            = var.target_group_arns

  # Auto scaling group
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "ELB"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    }
  ]

  tags_as_map = {
    extra_tag1 = "extra_value1"
    extra_tag2 = "extra_value2"
  }
}

module "security_group_web-dmz" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "tf-registry-web-dmz-sg"
  description = "Security group for webserver-cluster private subnet usage with EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]
  ingress_rules            = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules             = ["all-all"]
}

resource "aws_launch_configuration" "this" {
  name_prefix                 = "tf-lc-"
  image_id                    = var.image_id
  instance_type               = var.instance_type
  security_groups             = [module.security_group_web-dmz.this_security_group_id]
  associate_public_ip_address = false

  user_data = var.user_data

  lifecycle {
    create_before_destroy = true
  }
}
