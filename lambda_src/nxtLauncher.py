#!/usr/bin/env python3

import sys
import json
import boto3
import html
import logging
import datetime

logging.basicConfig(format='%(levelname)s - %(message)s',level=logging.INFO)
logger = logging.getLogger(__name__)

# boto3 session
session = boto3.session.Session()

# AWS Batch Client
batch_client = session.client('batch')

# set execution time
execTime = datetime.datetime.now().strftime('%Y-%m-%d-%H-%M-%S')

def checkJobDefinition(definitionName):
    try:
        response = batch_client.describe_job_definitions(jobDefinitionName=definitionName)
        definitions = response['jobDefinitions']
        
        # loop through returned definitions to find an active definition
        for definition in definitions:
            if definition['status'] == 'ACTIVE':
                logger.info("Job Definition is registered.")
                return True

        # if no definitions are found return False
        logger.info("Job Definition is not registered.")
        return False

    except Exception as err:
        logger.error(err)
        sys.exit(1)

def registerJobDefinition(jobDefinition):
    logger.info("Registering Job Definition.")
    try:
        response = batch_client.register_job_definition(**jobDefinition)
        if response['jobDefinitionArn']:
            logger.info(f"Job Definition registration completed: {response['jobDefinitionName']}")
            return True
        else:
            logger.error("There was an error registering the job definition.")
            logger.error(response)
            sys.exit(1)
    except Exception as err:
        logger.error(err)
        sys.exit(1)

def submitJob(jobName,jobQueue,jobDefinition,command,nextflowEnvironment):
    try:
        response = batch_client.submit_job(
            jobName=jobName,
            jobQueue=jobQueue,
            jobDefinition=jobDefinition,
            containerOverrides = {
                'command': [command],
                'environment': nextflowEnvironment
            }
        )
        if response:
            logger.info(f"Nextflow Job Started Successfully: {response}")
            return
    except Exception as err:
        logger.error(err)
        sys.exit(1)

def lambda_handler(event, context):
    towerToken = event['towerToken']
    jobDefinitionJSON = event['jobDefinitionJSON']
    tags = {}

    # load configurations
    with open(f"json_config/{jobDefinitionJSON}") as j:
        jobDefinition = json.load(j)
    with open("json_config/nextflow_environment.json") as j:
        nextflowEnvironment = json.load(j)
    
    # check JobDefinition exists, if not create then submit
    if checkJobDefinition(jobDefinition["jobDefinitionName"]):
        submitJob("Name","Queue",jobDefinition["jobDefinitionName"],"Command",nextflowEnvironment)
    else:
        registerJobDefinition(jobDefinition)
        submitJob("Name","Queue",jobDefinition["jobDefinitionName"],"Command",nextflowEnvironment)

# Testing Block
if __name__ == "__main__":
    event = {
        'towerToken' : '',
        'jobDefinitionJSON': 'nxtLauncher_jdv1.0.0.json'
    }
    context = {}

    lambda_handler(event,context)