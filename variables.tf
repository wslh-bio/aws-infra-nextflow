variable "env_prefix" {
  description = "This is the account environment prefix, used in tags."
}

variable "owner" {
    description = "The owner of the project, used in tags."
}

variable "region" {
  description = "The AWS region where infrastructure will be deployed."
}

variable "project" {
    description = "The project name, used for tags and resource names."
}

# Identifies the subnet from the 'Tier' tag attached to the previously provisioned resource
variable "nextflow_subnet_tier" {
  description = "'Tier' tag value of subnet where ec2 instances are running nextflow jobs."
}

# The name of the previously previsioned security group to apply to nextflow EC2 instances
variable "nextflow_security_group" {
  description = "Name of security group to apply to ec2 instances running nextflow jobs"
}

variable "buckets" {
  description = "List of S3 bucket names that nextflow jobs will need access."  
}

variable "external_buckets" {
  description = "List of external S3 bucket names that nextflow jobs need access to."
}

variable "job_compute_family" {
  description = "List of compute instance families to use for nextflow workflow jobs."
}

variable "head_compute_family" {
  description = "List of compute instance families to use for the nextflow engine process."
}

variable "max_job_cpus" {
  description = "Maximum allowed virtual CPUs for all simultaneous nextflow jobs in the compute environment."
}

variable "max_head_cpus" {
  description = "Maximum allowed virtual CPUs for all simultaneous nextflow engine processes in the compute environment."
}

variable "aws_nextflow_user" {
  description = "The programmatic IAM user that has roles to access AWS Batch."
}

# The name of the previously provisioned VPC where nextflow jobs are to be provisioned
variable "nextflow_vpc_name" {
  description = "Name of VPC where nextflow jobs are to be provisioned."
}

# The AMI to use for the Nextflow head/job EC2 instances
variable "nextflow_ec2_ami" {
  description = "The AMI or Amazon Machine Image to use for ec2 instances running nextflow jobs, must be an Amazon ECS-Optimized image."
}