# Snyk Broker Private ECR demo

## What's this demo?

This demo sets up demo environment for AWS private ECR.
Setting up this demo is provisioned by Terraform.
In terraform, 
* Create VPC (along with IGW, NAT, Subnets, etc)
* Create ECR 
* Create sample container image using Docker
* Push the docker image to ECR
* Create ECS cluster
* Run Snyk broker container on Fargate
* Run Snyk Container Registry Agent on Fargate

When terraform successfully provisions, you should have AWS infra as below.

<img src="./asset/Brocker_private_ecr_demo.png">

## Prerequisite

*  Terraform 
    ``` shell
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    ```
    Reference: [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    
* Docker
  * [Get Docker](https://docs.docker.com/get-docker/)

* Snyk Broker Token for ECR
    * Go to Snyk UI -> ECR -> Broker credentials
        <img src="./asset/broker_token.png">
* AWS credentials

## Steps

### Step0: Clone this repository

```
git clone https://github.com/masa-snyk/broker_private_ecr.git
```

or

```
git clone git@github.com:masa-snyk/broker_private_ecr.git
```

### Step1: Set AWS credentials in your enviroment variables

In your teminal
```
export AWS_ACCESS_KEY_ID=<access key>
export AWS_SECRET_ACCESS_KEY=<secret_key>
export AWS_DEFAULT_REGION=<aws region>
```

**Note:** *Never write your credentials in terraform config or use it as terraform variables. It will show up in your terraform state file, which might accicentally pushed to public repos.*

### step 2: Modify Terraform variable

Rename `terraform.tfvars.example` to `terraform.tfvars`.

```
mv terraform.tfvars.example terraform.tfvars
```

Modiry the contents

```
prefix       = "<replace this with your name>"
broker_token = "<replace this with your broker token>"
```

* `prefix` -> Your name or whatever
    * `prefix` is prepended to all of your resources, so it won't conflict with others in same AWS region.
* `broker_token`
  * Broker token obtained from Snyk UI

### Step 3: Run terraform

```
terraform init
terraform plan
terraform apply -auto-apply
```

### That's it

Now you should have your infrastructure on AWS with ECR, ECS, Broker, agent all set up.

If you go to Snyk's integration page, you should now see the your private private ECR Repo.

<img src="./asset/ecr_integration.png">

## Debug

* If you want to log in to broker or cra (container registry agent) containers for debug purpose, do following:

**Note:** You need AWS CLI and Session manager plugin installed in your local machine.
  * AWS CLI
    * https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

  * Session manager plugin
    * https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-macos

 #### To login in to **Broker** container

    ```
    ./debug/debug_login_into_broker.sh broker
    ```

#### To login in to **CRA** container

    ```
    ./debug/debug_login_into_broker.sh cra
    ```

## Action Items

[] Using ECS on EC2 version?
[] Terraform cloud compatible versioin?