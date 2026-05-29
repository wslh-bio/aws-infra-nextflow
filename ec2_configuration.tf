/*
    Launch and Instance Configuration
*/

## Nextflow Launch Configuration

data "template_cloudinit_config" "nextflow_template_head" {
    gzip          = false
    base64_encode = true

    part {
        content_type = "text/cloud-config"
        content      = templatefile("${path.module}/NextflowEC2launchTemplate.tftpl", { buckets = var.buckets })
    }
}

data "template_cloudinit_config" "nextflow_template_job" {
    gzip          = false
    base64_encode = true

    part {
        content_type = "text/cloud-config"
        content      = templatefile("${path.module}/NextflowEC2launchTemplate.tftpl", { buckets = var.buckets })
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
    name                   = "${var.env_prefix}_${var.project}_launch_template_job"
    image_id               = var.nextflow_ec2_ami
    user_data              = data.template_cloudinit_config.nextflow_template_job.rendered
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
        "Project"     = var.project,
        "Environment" = var.env_prefix,
        "Owner"       = var.owner
        }
    }
}

## Nextflow Workflow Head EC2 Template
resource "aws_launch_template" "nextflow_template_head" {
    name                   = "${var.env_prefix}_${var.project}_launch_template_head"
    image_id               = var.nextflow_ec2_ami
    user_data              = data.template_cloudinit_config.nextflow_template_head.rendered
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
        "Project"     = var.project,
        "Environment" = var.env_prefix,
        "Owner"       = var.owner
        }
    }
}
