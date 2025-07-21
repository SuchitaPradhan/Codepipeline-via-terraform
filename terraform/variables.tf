// ============================== //
//  variables.tf - Inputs for CodePipeline Setup
// ============================== //

// Modify these values as per your environment before running 'terraform apply'

// ---------- Project and AWS Region ----------
variable "project_name" {
  description = "suchita-codepipeline"
  type        = string
}


// ---------- GitHub Source Repository ----------
variable "github_repo" {
  description = "GitHub repository URL for source code"
  type        = string
  default     = "https://github.com/SuchitaPradhan/Codepipeline-via-terraform.git"
}


// ---------- EC2 Instance Configuration ----------
//variable "instance_type" {
 // description = "EC2 instance type for CodeDeploy target"
 // type        = string
  //default     = "t2.micro"
//} //
// ---------- Key Pair Name (ensure this key exists in your AWS account) ----------
variable "key_name" {
  description = "Name of the EC2 Key Pair to access the instance"
  type        = string
  default     = "devops" // <-- Replace this
}

// ---------- AMI ID for EC2 (Amazon Linux 2 recommended) ----------
//variable "ami_id" {
 // description = "AMI ID for the EC2 instance"
 // type        = string
 // default     = "ami-03bb6d83c60fc5f7c" // <-- Update based on region
//}//
// ---------- GitHub Integration Details ----------
variable "github_owner" {
  description = "GitHub username or organization name"
  type        = string
  default     = "SuchitaPradhan" // <-- Update if your GitHub username is different
}

variable "github_branch" {
  description = "Branch to track for CodePipeline (used internally)"
  type        = string
  default     = "main"
}

variable "aws_region" {
  description = "AWS region for AWS provider and resources"
  type        = string
  default     = "ap-south-1"
}

variable "codestar_connection_arn" {
  description = "The ARN of the existing AWS CodeStar Connection."
  type        = string
}
variable "github_token" {
  description = "GitHub Personal Access Token (PAT) with 'repo' and 'admin:repo_hook' scopes."
  type        = string
  sensitive   = true
}

