
resource "aws_ecr_repository" "autospotting" {
  name                 = "autospotting-${module.label.id}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  timeouts {
    delete = "2m"
  }
}

data "aws_ecr_authorization_token" "source" {
  registry_id = split(".", var.lambda_source_ecr)[0]

}
data "aws_ecr_authorization_token" "destination" {}

provider "docker" {
  registry_auth {
    address  = split("/", aws_ecr_repository.autospotting.repository_url)[0]
    username = data.aws_ecr_authorization_token.destination.user_name
    password = data.aws_ecr_authorization_token.destination.password
  }
}

resource "local_file" "Dockerfile" {
  content  = "FROM ${var.lambda_source_ecr}/${var.lambda_source_image}:${var.lambda_source_image_tag}"
  filename = "${path.module}/docker/Dockerfile"
}

resource "docker_registry_image" "destination" {
  name          = "${aws_ecr_repository.autospotting.repository_url}:${var.lambda_source_image_tag}"
  keep_remotely = false
  build {
    context = "${path.module}/docker"

    auth_config {
      host_name = var.lambda_source_ecr
      user_name = data.aws_ecr_authorization_token.source.user_name
      password  = data.aws_ecr_authorization_token.source.password
    }
  }
  depends_on = [
    local_file.Dockerfile,
  ]
}