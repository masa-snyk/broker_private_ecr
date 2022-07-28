#!/bin/bash

#set -x

TFSTATE=../terraform.tfstate 
CLUSTER_ID=$(terraform output -state=${TFSTATE} -raw ecs_cluster_id)
SERVICE_NAME=$(terraform output -state=${TFSTATE} -raw broker_service_name)

aws ecs list-tasks --cluster ${CLUSTER_ID} \
	--service-name  ${SERVICE_NAME} \
	| jq -r '.taskArns[0]'
