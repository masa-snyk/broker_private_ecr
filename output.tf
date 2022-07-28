output "Debug" {
  value = <<EOF
region: ${local.region}
account ID: ${data.aws_caller_identity.current.account_id}
ECR repo url: ${aws_ecr_repository.repo.repository_url}
ECS Cluster ID: ${module.ecs.cluster_id}
ECS Cluster Name: ${module.ecs.cluster_name}
ECS Task Definition ID for Broker: ${aws_ecs_task_definition.broker_cra.arn}
ECS service ID for Broker: ${aws_ecs_service.broker_cra.id}
Cloudwatch log group: ${aws_cloudwatch_log_group.this.name}

EOF
}

output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "broker_service_name" {
  value = aws_ecs_service.broker_cra.name
}

output "external_id" {
  value = random_uuid.ex_id.result
}

output "prefix" {
  value = var.prefix
}