variable "env_prefix" {
  description = "This is the account environment prefix."
}

variable "owner" {
    description = "The owner of the project."
}

variable "region" {
  description = "The AWS region."
}

variable "project" {
    description = "The project tags assoicated with infrastructure resources and components."
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
  description = "Names of S3 buckets that nextflow jobs need access to."  
}

variable "external_buckets" {
  description = "Names of external S3 buckets that nextflow jobs need access to."
}

variable "job_compute_family" {
  description = "Compute instance families to use for nextflow workflow jobs."
}

variable "head_compute_family" {
  description = "Compute instance families to use for the nextflow workflow main process."
}

variable "max_job_cpus" {
  description = "Maxmium allowed virtual cpus for jobs in the compute environment"
}

variable "max_head_cpus" {
  description = "Maxmium allowed virtual cpus for nextflow main process in the compute environment"
}

variable "aws_nextflow_user" {
  description = "The programmatics IAM user that has roles to access AWS Batch"
}

# The name of the previously provisioned VPC where nextflow jobs are to be provisioned
variable "nextflow_vpc_name" {
  description = "Name of VPC where nextflow jobs are to be provisioned"
}

# The AMI to use for the Nextflow head/job EC2 instances
variable "nextflow_ec2_ami" {
  description = "AMI for ec2 instances running nextflow jobs"
}