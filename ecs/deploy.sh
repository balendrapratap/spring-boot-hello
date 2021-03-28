#!/bin/bash

REGION=us-west-1
SERVICE_NAME=aws-service-latest
CLUSTER=aws-ecs-cluster
IMAGE_VERSION=latest
TASK_FAMILY="aws-task-latest"

# Create a new task definition for this build
aws configure list

aws ecs register-task-definition --region ${REGION} --family aws-task-latest --cli-input-json file://ecs/aws-task-latest.json

# Update the service with the new task definition and desired count
REVISION=`aws ecs describe-task-definition --region ${REGION} --task-definition aws-task-latest | egrep "revision" | tr "/" " " | awk '{print $2}' | sed 's/"$//' `
SERVICES=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .failures[]`


#Create or update service
if [[ "$SERVICES" == "" ]]; then
  echo "entered existing service"
  DESIRED_COUNT=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .services[].desiredCount`
  if [[ ${DESIRED_COUNT} = "0" ]]; then
    DESIRED_COUNT="1"
  fi
  aws ecs update-service --cluster ${CLUSTER} --region ${REGION} --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY}:${REVISION} --desired-count ${DESIRED_COUNT} --deployment-configuration maximumPercent=100,minimumHealthyPercent=0
else
  echo "entered new service"
  aws ecs create-service --service-name ${SERVICE_NAME} --desired-count 1 --task-definition ${TASK_FAMILY} --cluster ${CLUSTER} --region ${REGION}
fi
