/*
aws_launch_configuration

aws_autoscaling_group

aws_autoscaling_schedule (both of them)

aws_security_group (for the Instances, but not for the ALB)

aws_security_group_rule (both of the rules for the Instances, but not those for the ALB)

aws_cloudwatch_metric_alarm (both of them)
*/

######################################################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
}

resource "aws_launch_configuration" "this" {
  name_prefix   = "tf-lc-"
  image_id        = "ami-01a6e31ac994bbc09"
  instance_type = "t2.micro"
  security_groups = [module.security_group_web-dmz.this_security_group_id]

  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "tf-asg"

  # Launch configuration
  launch_configuration = aws_launch_configuration.this.name
  create_lc = false
  recreate_asg_when_lc_changes = true


# Auto scaling group
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "ELB"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 3
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

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules        = ["all-all"]
}

