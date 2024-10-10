#!/bin/bash

# This script will destroy the current batch compute environments and queues and redeploy them resetting the configured launch template

# The script takes the environment tfvars as an argument

terraform destroy \
  -target aws_batch_compute_environment.nextflow_head \
  -target aws_batch_compute_environment.nextflow_job \
  -target aws_batch_job_queue.nextflow_job \
  -target aws_batch_job_queue.nextflow_head \
  -var-file=$1 && \
terraform apply -var-file=$1