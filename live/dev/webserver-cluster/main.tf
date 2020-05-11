###
provider "aws" {
  version                 = "~> 2.0"
  region                  = "eu-west-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "ora2postgres"
}

terraform {
  required_version = "~> v0.12"

  backend "s3" {
    bucket = "tf-state-eu-west-2-rnbv"
    key    = "tf-registry/live/dev/webserver-cluster/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "tf-locks-eu-west-2-rnbv"
    encrypt        = true
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
}

module "networking_alb" {
  source = "../../../modules/networking/alb"
}

module "cluster_asg" {
  source = "../../../modules/cluster/asg-rolling-deploy"

  target_group_arns = module.networking_alb.target_group_arns
  min_size          = 2
  max_size          = 4
  desired_capacity  = 3
  image_id          = "ami-01a6e31ac994bbc09"
  instance_type     = "t2.micro"
  user_data         = data.template_file.user_data.rendered
}
