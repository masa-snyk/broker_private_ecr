### -------------------------
### Create ECS cluster
### -------------------------

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "4.1.0"

  cluster_name = local.name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.this.name
      }
    }
  }
  tags = local.tags
}

### -----------------------------
### Container task definition
### -----------------------------

resource "aws_ecs_task_definition" "broker_cra" {
  family                   = "${var.prefix}-broker-cra"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.SnykCraEcsRole.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.prefix}-broker"
      image     = "snyk/broker:container-registry-agent"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = local.region
          awslogs-stream-prefix = "BROKER"
          awslogs-group         = aws_cloudwatch_log_group.this.name
        }
      }
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      environment = [
        {
          name  = "BROKER_TOKEN",
          value = "${var.broker_token}"
        },
        {
          name  = "BROKER_CLIENT_URL"
          value = "http://127.0.0.1:8000"
        },
        {
          name  = "CR_AGENT_URL"
          value = "http://127.0.0.1:8081"
        },
        {
          name  = "CR_TYPE"
          value = "ecr"
        },
        {
          name  = "CR_ROLE_ARN"
          value = aws_iam_role.SnykEcrServiceRole.arn
        },
        {
          name  = "CR_REGION"
          value = local.region
        },
        {
          name  = "CR_EXTERNAL_ID"
          value = random_uuid.ex_id.result
        },
        {
          name  = "PORT"
          value = "8000"
        }
      ]
    },
    {
      name      = "${var.prefix}-cra"
      image     = "snyk/container-registry-agent:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = local.region
          awslogs-stream-prefix = "CRA"
          awslogs-group         = aws_cloudwatch_log_group.this.name
        }
      }
      environment = [
        {
          name  = "SNYK_PORT"
          value = "8081"
        }
      ]
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = local.tags
}

### --------------------------------------------------------------
### Crate ECS service to run Containers 
### --------------------------------------------------------------

resource "aws_ecs_service" "broker_cra" {
  name            = "${var.prefix}-snyk-broker-cra"
  cluster         = module.ecs.cluster_id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.broker_cra.arn
  desired_count   = 1

  # need this to exec into this container
  enable_execute_command = true

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.broker.id, aws_security_group.cra.id]
  }

  tags       = local.tags
  depends_on = [aws_ecs_task_definition.broker_cra]
}

### ----------------------------------------------------------------
### Hack to get ECS Task ID
### There is no resource/data source in Terraform to get Task ID....
### ----------------------------------------------------------------

/*
data "external" "get_task_id" {
  depends_on = [aws_ecs_service.broker]

  program = ["bash", "hack_to_get_task_id.sh"]

  query = {
    cluster_id = module.ecs.cluster.id
  }
}
*/