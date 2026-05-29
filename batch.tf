/*
    Compute Environments
*/

## Nextflow Job Spot Compute Environment
resource "aws_batch_compute_environment" "nextflow_job" {
  name = "${var.project}_job"
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
    allocation_strategy = "BEST_FIT"
    #bid_percentage = 80

    instance_type = var.job_compute_family

    max_vcpus = var.max_job_cpus
    min_vcpus = 0

    security_group_ids = [data.aws_security_group.nextflow_security_group.id]

    subnets = data.aws_subnets.nextflow_subnets.ids

    type = "EC2"
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

resource "aws_ecs_tag" "nextflow_job_project" {
  resource_arn = aws_batch_compute_environment.nextflow_job.ecs_cluster_arn
  key          = "Project"
  value        = var.project
}

## Nextflow Head Node Compute Environment
resource "aws_batch_compute_environment" "nextflow_head" {
  name = "${var.project}_head"
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
  compute_environment_order {
    order = 1
    compute_environment = aws_batch_compute_environment.nextflow_job.arn
  }

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
  compute_environment_order {
    order = 1
    compute_environment = aws_batch_compute_environment.nextflow_head.arn
  }
  tags = {
    "Project" = var.project,
    "Environment" = var.env_prefix,
    "Owner" = var.owner
  }
}