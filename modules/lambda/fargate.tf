
data "aws_availability_zones" "available" {
  state = "available"
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.21"

  name = "autospotting-${module.label.id}"

  cidr = "10.0.0.0/24"

  azs            = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  public_subnets = ["10.0.0.0/25", "10.0.0.128/25"]

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true
  map_public_ip_on_launch = true
}

resource "aws_ecs_cluster" "autospotting" {
  name               = "autospotting-${module.label.id}"
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}

module "ecs-task-definition" {
  source  = "umotif-public/ecs-fargate-task-definition/aws"
  version = "~> 1.0.0"

  enabled              = true
  name_prefix          = "autospotting-${module.label.id}"
  task_container_image = "${aws_ecr_repository.autospotting.repository_url}:${var.lambda_source_image_tag}"
  container_name       = "autospotting-${module.label.id}"

  cloudwatch_log_group_name = aws_cloudwatch_log_group.autospotting.name
}

resource "aws_cloudwatch_log_group" "autospotting"{
    name = "autospotting-${module.label.id}"
    retention_in_days= 7
}

module "ecs-fargate-scheduled-task" {
  source  = "umotif-public/ecs-fargate-scheduled-task/aws"
  version = "~> 1.0.0"

  name_prefix = "test-scheduled-task"

  ecs_cluster_arn = aws_ecs_cluster.autospotting.arn

  task_role_arn      = module.ecs-task-definition.task_role_arn
  execution_role_arn = module.ecs-task-definition.execution_role_arn

  event_target_task_definition_arn = module.ecs-task-definition.task_definition_arn
  event_rule_schedule_expression   = "rate(1 hour)"
  event_target_subnets             = module.vpc.public_subnets
  event_target_assign_public_ip = true
  }