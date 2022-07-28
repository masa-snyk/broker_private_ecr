### -----------------------------------------
### Policies
### -----------------------------------------

data "aws_iam_policy_document" "ecr_read_only" {
  statement {
    sid    = "SnykAllowPull"
    effect = "Allow"
    actions = [
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetAuthorizationToken",
      "ecr:DescribeRepositories",
      "ecr:ListTagsForResource",
      "ecr:ListImages",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "SnykCraEcsRole" {
  name = "${var.prefix}-SnykCraEcsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "${var.prefix}-SnykCraAssumeRolePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "SnykCraAssumeRolePolicvy"
          Action   = "sts:AssumeRole"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  tags = local.tags
}

resource "aws_iam_policy" "readonly" {
  name        = "${var.prefix}-AmazonEC2ContainerRegistryReadOnlyForSnyk"
  description = "Provides Container Registry Agent with read-only access to Amazon EC2 Container Registry repositories"
  policy      = data.aws_iam_policy_document.ecr_read_only.json

  tags = local.tags
}

resource "aws_iam_role" "SnykEcrServiceRole" {
  name        = "${var.prefix}-SnykEcrServiceRole"
  description = "Allows ECS task to call ECR AWS services on your behalf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.SnykCraEcsRole.arn
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = random_uuid.ex_id.result
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.SnykEcrServiceRole.name
  policy_arn = aws_iam_policy.readonly.arn
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

### ----------------
### for ssm login
### ----------------

data "aws_iam_policy_document" "ecs_task_role_ssm" {
  version = "2012-10-17"
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm" {
  name_prefix = "${var.prefix}-ecs_task-ssm"
  policy      = data.aws_iam_policy_document.ecs_task_role_ssm.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.SnykCraEcsRole.name
  policy_arn = aws_iam_policy.ssm.arn
}
