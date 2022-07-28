resource "aws_ecr_repository" "repo" {
  name                 = "${var.prefix}-ecr-demo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}

# Push sample container image
resource "null_resource" "frontend" {
  triggers = {
    file_content_md5 = md5(file("${path.module}/dockerbuild.sh"))
  }

  provisioner "local-exec" {
    command = "sh ${path.module}/dockerbuild.sh"

    environment = {
      AWS_REGION     = local.region
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
      REPO_URL       = aws_ecr_repository.repo.repository_url
      CONTAINER_NAME = "${var.prefix}-hello-world"
    }
  }
}
