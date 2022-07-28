#!/bin/bash

if [ $# -ne 1 ]
	then
		echo 'Needs to supply argument'
		echo '  $1 = <broker|cra>'
		exit 1
fi

# set -x

TFSTATE=./terraform.tfstate 
CLUSTER_ID=$(terraform output -state=${TFSTATE} -raw ecs_cluster_id)
CLUSTER_NAME=$(terraform output -state=${TFSTATE} -raw ecs_cluster_name)
PREFIX=$(terraform output -state=${TFSTATE} -raw prefix)

SERVICE_NAME=${PREFIX}-snyk-broker-cra

TASK_ID=$(aws ecs list-tasks --cluster ${CLUSTER_ID} \
	--service-name  ${SERVICE_NAME} \
	| jq -r '.taskArns[0]')

aws ecs execute-command \
	--task=${TASK_ID} \
	--cluster=${CLUSTER_NAME} \
	--container=${PREFIX}-${1} \
	--interactive \
	--command /bin/sh 
