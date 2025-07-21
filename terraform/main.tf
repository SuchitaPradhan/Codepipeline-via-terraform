# ---------------------- main.tf ----------------------

# -------------------- Terraform Provider Setup --------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.39.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # <-- Change this to your preferred region if different
}

# -------------------- Random ID for Unique Bucket Name --------------------
resource "random_id" "id" {
  byte_length = 8
}

# -------------------- S3 Bucket for Pipeline Artifacts --------------------
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket        = "${var.project_name}-artifacts-${random_id.id.hex}"
  force_destroy = true # <-- Use with caution in production
}

resource "aws_s3_bucket_versioning" "codepipeline_artifacts_versioning" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------- CodeBuild Project --------------------
resource "aws_codebuild_project" "build_project" {
  name          = "${var.project_name}-build"
  description   = "Build project for the ${var.project_name} pipeline"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "5" # in minutes

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        build:
          commands:
            - echo "Preparing artifacts..."
      artifacts:
        files:
          - appspec.yml
          - 'app/**/*'
    EOT
  }
}

# -------------------- CodeDeploy Setup --------------------
resource "aws_codedeploy_app" "deploy_app" {
  compute_platform = "Server"
  name             = "${var.project_name}-app"
}

resource "aws_codedeploy_deployment_group" "deploy_group" {
  app_name              = aws_codedeploy_app.deploy_app.name
  deployment_group_name = "${var.project_name}-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "${var.project_name}-instance" # <-- Match with EC2 instance tag below
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
}

# -------------------- CodePipeline Setup --------------------
resource "aws_codepipeline" "pipeline" {
  name          = "${var.project_name}-pipeline"
  role_arn      = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  # -------- Source Stage --------
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn = data.aws_codestarconnections_connection.github.arn # <-- Update ARN after creating connection in AWS Console
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"           # <-- GitHub repo (e.g., your-name/your-repo)
        BranchName       = var.github_branch
      }
      run_order = 1
    }
  }

  # -------- Build Stage --------
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }

  # -------- Deploy Stage --------
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["BuildArtifact"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.deploy_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.deploy_group.deployment_group_name
      }
    }
  }
}

# -------------------- GitHub Connection --------------------
data "aws_codestarconnections_connection" "github" {
  arn = "arn:aws:codeconnections:ap-south-1:176387410897:connection/7b88ddf3-b890-4a00-b9be-928aec7dff1a"
}
# -------------------------------------------------- Target EC2 Instance ---------------------------------------------------

# Find latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
# -------------------- EC2 Resources --------------------

# Find latest Amazon Linux 2 AMI
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = "devops" # <-- Your EC2 key pair name
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y ruby wget
              yum install -y httpd
              cd /home/ec2-user
              wget https://aws-codedeploy-${var.aws_region}.s3.${var.aws_region}.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto
              systemctl start codedeploy-agent
              systemctl enable codedeploy-agent
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name = "${var.project_name}-instance" # <-- Tag should match CodeDeploy EC2 filter
  }
}

# -------------------- Security Group --------------------
resource "aws_security_group" "instance_sg" {
  name = "${var.project_name}-instance-sg"
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # You can restrict this to your IP for better security
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


