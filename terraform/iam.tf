# -------------------- CodePipeline IAM Role --------------------
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}
cd
resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}
resource "aws_iam_role_policy" "codepipeline_s3_upload" {
  name = "codepipeline-s3-upload"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:PutObject"],
        Resource = "arn:aws:s3:::codepipeline-project-artifacts-271f6a19310b1257/codepipeline-project/SourceArti/*"
      }
    ]
  })
}
resource "aws_iam_role_policy" "codepipeline_deploy_access" {
  name = "codepipeline-deploy-access"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment"
        ],
        Resource = [
          "arn:aws:codedeploy:ap-south-1:176387410897:deploymentgroup:codepipeline-project-app/codepipeline-project-deployment-group"
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy" "codepipeline_deploy_config_access" {
  name = "codepipeline-deploy-config-access"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codedeploy:GetDeploymentConfig"
        ],
        Resource = "arn:aws:codedeploy:ap-south-1:176387410897:deploymentconfig:CodeDeployDefault.OneAtATime"
      }
    ]
  })
}
resource "aws_iam_role_policy" "codepipeline_register_revision" {
  name = "codepipeline-register-application-revision"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetApplicationRevision"
        ],
        Resource = "arn:aws:codedeploy:ap-south-1:176387410897:application:codepipeline-project-app"
      }
    ]
  })
}

# -------------------- CodeBuild IAM Role --------------------
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}
resource "aws_iam_role_policy" "codebuild_logging_access" {
  name = "codebuild-cloudwatch-logs"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:ap-south-1:176387410897:log-group:/aws/codebuild/codepipeline-project-build:*"
      }
    ]
  })
}
resource "aws_iam_role_policy" "codebuild_s3_access" {
  name = "codebuild-artifact-access"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation"
        ],
        Resource = "arn:aws:s3:::codepipeline-project-artifacts-271f6a19310b1257/codepipeline-project/SourceArti/*"
      }
    ]
  })
}
resource "aws_iam_role_policy" "codebuild_artifact_upload" {
  name  = "codebuild-artifact-upload"
  role  = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = "arn:aws:s3:::codepipeline-project-artifacts-271f6a19310b1257/codepipeline-project/BuildArtif/*"
      }
    ]
  })
}

# -------------------- CodeDeploy IAM Role --------------------
resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}
resource "aws_iam_role_policy" "codedeploy_ec2_permissions" {
  name = "codedeploy-ec2-permissions"
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DeleteLifecycleHook",
          "autoscaling:Describe*",
          "autoscaling:PutLifecycleHook",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "autoscaling:ResumeProcesses",
          "autoscaling:SuspendProcesses",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "tag:GetTags",
          "tag:GetResources"
        ],
        Resource = "*"
      }
    ]
  })
}


# -------------------- EC2 IAM Role and Instance Profile --------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile-${var.project_name}"
  role = aws_iam_role.ec2_role.name
}


