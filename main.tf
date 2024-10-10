/*

Infrastructure for running nextflow jobs on AWS Batch

*/

terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.20.1"
        }
    }

    required_version = ">= 1.1.6"

    backend "s3" {}
}

provider "aws" {
    region  = var.region
}




/*
    IAM Roles
*/


###
### Seqera Platform IAM User
###

resource "aws_iam_policy" "seqera_platform_access_policy" {
    name        = "${var.project}_seqera_platform_access"
    path        = "/"
    description = "Seqera Platform access policy"

    policy = jsonencode(
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Sid": "SeqeraBatchAccess",
            "Effect": "Allow",
            "Action": [
              "batch:CancelJob",
              "batch:RegisterJobDefinition",
              "batch:DescribeComputeEnvironments",
              "batch:DescribeJobDefinitions",
              "batch:DescribeJobQueues",
              "batch:DescribeJobs",
              "batch:ListJobs",
              "batch:SubmitJob",
              "batch:TerminateJob"
            ],
            "Resource": ["*"]
          },
          {
            "Sid": "SeqeraBucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Describe*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*",
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject"
            ],
            "Resource" = concat([for name in var.buckets : "arn:aws:s3:::${name}/*"],[for name in var.buckets : "arn:aws:s3:::${name}"])
        },
        ]
      }
    )
}

resource "aws_iam_user_policy_attachment" "attach-nextflow-user" {
  user       = var.aws_nextflow_user
  policy_arn = aws_iam_policy.seqera_platform_access_policy.arn
}




###
### AWS Batch Service Role
###

resource "aws_iam_role" "batch_service_role" {
  name = "${var.project}_batch_service_ROLE"

  assume_role_policy = jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
            "Service": "batch.amazonaws.com"
            }
        }
        ]
    }
  )

  tags = {
    "Project" = var.project,
    "Environment" = var.env_prefix,
    "Owner" = var.owner
  }
}

resource "aws_iam_role_policy_attachment" "batch_service_role" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}




###
### EC2 Spot Fleet Role
###
resource "aws_iam_role" "spot_fleet_role" {
  name = "${var.project}_spot_fleet_ROLE"

  assume_role_policy = jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
            "Service": "spotfleet.amazonaws.com"
            }
        }
        ]
    }
  )

  tags = {
    "Project" = var.project,
    "Environment" = var.env_prefix,
    "Owner" = var.owner
  }
}

resource "aws_iam_role_policy_attachment" "spot_fleet_role" {
  role       = aws_iam_role.spot_fleet_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}




###
### EC2 Instance Role
###

resource "aws_iam_role" "nextflow_instance_role" {
  name = "${var.project}_instance_ROLE"

  assume_role_policy = jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
            "Service": "ec2.amazonaws.com"
            }
        }
        ]
    }
  )

  tags = {
    "Project" = var.project,
    "Environment" = var.env_prefix,
    "Owner" = var.owner
  }
}

resource "aws_iam_instance_profile" "nextflow_instance_role" {
  name = "${var.project}_instance_role_profile"
  role = aws_iam_role.nextflow_instance_role.name
}

#### Attach EC2 container service Role
resource "aws_iam_role_policy_attachment" "ecs_instance_role_ec2" {
  role       = aws_iam_role.nextflow_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

#### Attach CloudWatch Policy
resource "aws_iam_role_policy_attachment" "ecs_instance_role_cloudwatch" {
  role       = aws_iam_role.nextflow_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}


#### Custom Nextflow Policy
resource "aws_iam_role_policy" "nextflow_launch_policy" {
    name = "${var.project}_batch_job"
    role = aws_iam_role.nextflow_instance_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            "Sid": "NextflowBucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Describe*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*",
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject"
            ],
            "Resource" = concat([for name in var.buckets : "arn:aws:s3:::${name}/*"],[for name in var.buckets : "arn:aws:s3:::${name}"])
        },
        {
            "Sid": "NextflowLaunchJobs",
            "Effect": "Allow",
            "Action": [
                "batch:DescribeJobQueues",
                "batch:CancelJob",
                "batch:SubmitJob",
                "batch:ListJobs",
                "batch:TagResource",
                "batch:DescribeComputeEnvironments",
                "batch:TerminateJob",
                "batch:DescribeJobs",
                "batch:RegisterJobDefinition",
                "batch:DescribeJobDefinitions",
                "ecs:DescribeTasks",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeInstanceAttribute",
                "ecs:DescribeContainerInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeImages",
                "logs:Describe*",
                "logs:Get*",
                "logs:List*",
                "logs:StartQuery",
                "logs:StopQuery",
                "logs:TestMetricFilter",
                "logs:FilterLogEvents",
                "ses:SendRawEmail",
                "secretsmanager:ListSecrets"
            ],
            "Resource" = "*",
        },
        {
            "Sid": "AccessToS3OpenData",
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:*Object"
            ],
            "Resource" = concat([for name in var.external_buckets : "arn:aws:s3:::${name}"], [for name in var.external_buckets : "arn:aws:s3:::${name}/*"])
        },
        ]
    })
}

#### Custom EBS Autoscaling Policy
data "aws_kms_alias" "ebs" {
  name = "alias/aws/ebs"
}

resource "aws_iam_role_policy" "ebs_autoscaling_policy" {
  role = aws_iam_role.nextflow_instance_role.id
  name = "${var.project}_ebs_autoscaling_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "ec2:AttachVolume",
            "ec2:ModifyInstanceAttribute",
            "ec2:CreateVolume",
            "ec2:DeleteVolume",
            "ec2:CreateTags"
        ],
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Action = [
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeAttribute",
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
            "kms:Decrypt",
            "kms:CreateGrant",
            "kms:Encrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
        ],
        Effect = "Allow",
        Resource = data.aws_kms_alias.ebs.target_key_arn
      }
    ]
  })
}




/*
    Compute Environments
*/

## Nextflow Job Spot Compute Environment
resource "aws_batch_compute_environment" "nextflow_job" {
  compute_environment_name_prefix = "${var.project}_job_"
  tags = {
    "Project" = var.project,
    "Environment" = var.env_prefix,
    "Owner" = var.owner
  }

  compute_resources {
    tags = {
      "Name" = "${var.project}_spot_instance",
      "Project" = var.project,
      "Environment" = var.env_prefix,
      "Owner" = var.owner
    }
    instance_role = aws_iam_instance_profile.nextflow_instance_role.arn
    spot_iam_fleet_role = aws_iam_role.spot_fleet_role.arn
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    bid_percentage = 80

    instance_type = var.job_compute_family

    max_vcpus = var.max_job_cpus
    min_vcpus = 0

    security_group_ids = [data.aws_security_group.nextflow_security_group.id]

    subnets = data.aws_subnets.nextflow_subnets.ids

    type = "SPOT"
    launch_template {
      launch_template_id = aws_launch_template.nextflow_template_job.id
    }
  }

  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
  depends_on   = [
    aws_iam_role_policy_attachment.batch_service_role,
    aws_iam_role_policy_attachment.spot_fleet_role,
    aws_iam_role.nextflow_instance_role,
    aws_launch_template.nextflow_template_job
    ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_tag" "nextflow_spot_project" {
  resource_arn = aws_batch_compute_environment.nextflow_job.ecs_cluster_arn
  key          = "Project"
  value        = var.project
}

## Nextflow Head Node Compute Environment
resource "aws_batch_compute_environment" "nextflow_head" {
  compute_environment_name_prefix = "${var.project}_head_"
  tags = {
    "Project" = var.project,
    "Environment" = var.env_prefix,
    "Owner" = var.owner
  }

  compute_resources {
    tags = {
      "Name" = "${var.project}_head",
      "Project" = var.project,
      "Environment" = var.env_prefix,
      "Owner" = var.owner
    }
    instance_role = aws_iam_instance_profile.nextflow_instance_role.arn
    allocation_strategy = "BEST_FIT"

    instance_type = var.head_compute_family

    max_vcpus = var.max_head_cpus
    min_vcpus = 0

    security_group_ids = [data.aws_security_group.nextflow_security_group.id]

    subnets = data.aws_subnets.nextflow_subnets.ids


    type = "EC2"

    launch_template {
      launch_template_id = aws_launch_template.nextflow_template_head.id
    }
  }

  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
  depends_on   = [
    aws_iam_role_policy_attachment.batch_service_role,
    aws_iam_role.nextflow_instance_role,
    aws_launch_template.nextflow_template_head
    ]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_tag" "nextflow_head" {
  resource_arn = aws_batch_compute_environment.nextflow_head.ecs_cluster_arn
  key          = "Owner"
  value        = var.project
}




/*
    Batch Job Queues
*/

## Nextflow Workflow Job Queue
resource "aws_batch_job_queue" "nextflow_job" {
  name     = "${var.env_prefix}_${var.project}_nextflow_job"
  state    = "ENABLED"
  priority = 1
  compute_environments = [aws_batch_compute_environment.nextflow_job.arn] # deprecated, but fix errors:  The argument "compute_environments" is required, but no definition was found.
  tags = {
    "Project" = var.project,
    "Environment" = var.env_prefix,
    "Owner" = var.owner
  }
}

## Nextflow Workflow Head Queue
resource "aws_batch_job_queue" "nextflow_head" {
  name     = "${var.env_prefix}_${var.project}_nextflow_head"
  state    = "ENABLED"
  priority = 1
  compute_environments = [aws_batch_compute_environment.nextflow_head.arn] # deprecated, but fix errors:  The argument "compute_environments" is required, but no definition was found.
  tags = {
    "Project" = var.project,
    "Environment" = var.env_prefix,
    "Owner" = var.owner
  }
}




/*
    Launch and Instance Configuration
*/

## Nextflow Launch Configuration

data "template_cloudinit_config" "nextflow_template_head" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/NextflowEC2launchTemplate.tftpl",{buckets = var.buckets})
  }
}

data "template_cloudinit_config" "nextflow_template_job" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/NextflowEC2launchTemplate.tftpl",{buckets = var.buckets})
  }
}

# get the arn of the VPC with the value of var.nextflow_vpc_name
data "aws_vpc" "nextflow_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.nextflow_vpc_name]
  }
}

# get a list of the subnet ids of the VPC with vpc_id of data.aws_vpc.nextflow_vpc.id. Filter using the "Tier" tag having Value var.nextflow_subnet_tier
data "aws_subnets" "nextflow_subnets" {
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.nextflow_vpc.id]
  }

  tags = {
    Tier = var.nextflow_subnet_tier
  }
}

# get the security group ids of the security group having the name var.nextflow_security_group
data "aws_security_group" "nextflow_security_group" {
  filter {
    name   = "tag:Name"
    values = [var.nextflow_security_group]
  }
}

## Nextflow Workflow Job EC2 Template
resource "aws_launch_template" "nextflow_template_job" {
  name = "${var.env_prefix}_${var.project}_launch_template_job"
  image_id = var.nextflow_ec2_ami
  user_data = "${data.template_cloudinit_config.nextflow_template_job.rendered}"
  update_default_version = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      "Project" = var.project,
      "Environment" = var.env_prefix,
      "Owner" = var.owner
    }
  }
}

## Nextflow Workflow Head EC2 Template
resource "aws_launch_template" "nextflow_template_head" {
  name = "${var.env_prefix}_${var.project}_launch_template_head"
  image_id = var.nextflow_ec2_ami
  user_data = "${data.template_cloudinit_config.nextflow_template_head.rendered}"
  update_default_version = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      "Project" = var.project,
      "Environment" = var.env_prefix,
      "Owner" = var.owner
    }
  }
}
