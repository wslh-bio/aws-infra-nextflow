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

#### Attach SSM Agent service Role
resource "aws_iam_role_policy_attachment" "ssmagent_role" {
  role       = aws_iam_role.nextflow_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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