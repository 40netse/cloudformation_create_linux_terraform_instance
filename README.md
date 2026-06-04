# CloudFormation: Linux Terraform Instance

Deploys an Ubuntu 22.04 EC2 instance pre-installed with the latest Terraform into a new VPC using two CloudFormation stacks.

## Architecture

**Stack 1 — Base VPC** (`NewVPC_BaseSetup_Single.yaml`)
- VPC with a single public subnet
- Internet Gateway and route table

**Stack 2 — Linux Instance** (`ExistingVPC_LinuxInstance.yaml`)
- Ubuntu 22.04 LTS EC2 instance with Terraform installed via UserData
- IAM role with EC2 and CloudWatch permissions
- Security group allowing SSH access

## Prerequisites

- AWS CLI installed and configured (`aws configure`)
- An EC2 key pair in the target region
- Sufficient IAM permissions to create VPCs, EC2 instances, IAM roles, and CloudFormation stacks

## Configuration

All deployment parameters are in `stack_parameters.sh`:

| Variable | Default | Description |
|---|---|---|
| `region` | `us-east-1` | AWS region to deploy into |
| `aws_az` | `us-east-1a` | Availability zone for subnet and instance |
| `vpc_cidr` | `10.0.0.0/16` | CIDR block for the VPC |
| `subnet_cidr` | `10.0.0.0/24` | CIDR block for the public subnet |
| `linux_instance_type` | `c4.large` | EC2 instance type |
| `key` | `mdw-poc-common` | EC2 key pair name (must exist in the target region) |
| `access` | `0.0.0.0/0` | CIDR allowed SSH access — restrict this for production |

Edit `stack_parameters.sh` before deploying:

```bash
vi stack_parameters.sh
```

## Deploy

```bash
./build_stack.sh
```

The script deploys both stacks in order, waiting for each to reach `CREATE_COMPLETE` before proceeding. On success, output resembles:

```
============================================
 Base VPC Stack: terraform-linux-dev-base
============================================
 Region:            us-east-1
 Availability Zone: us-east-1a
 VPC ID:            vpc-0abc1234def567890  (10.0.0.0/16)
 Subnet ID:         subnet-0abc1234def567890  (10.0.0.0/24)
============================================

Deploying terraform-linux-dev-linux Template

============================================
 Linux Instance Stack: terraform-linux-dev-linux
============================================
 Instance ID:    i-0abc1234def567890
 Instance Type:  c4.large
 Key Pair:       mdw-poc-common
 Public IP:      3.90.x.x
 Access CIDR:    0.0.0.0/0
--------------------------------------------
 SSH:  ssh -i ~/.ssh/mdw-poc-common.pem ubuntu@3.90.x.x
============================================
```

### Options

| Flag | Description |
|---|---|
| `-k` | Pause for keyboard confirmation between each stack deployment |
| `-p <seconds>` | Override the polling interval (default: 15 seconds) |

```bash
# Deploy with confirmation prompts between stacks
./build_stack.sh -k

# Deploy with a 30-second polling interval
./build_stack.sh -p 30
```

## Connect via SSH

```bash
ssh -i ~/.ssh/<key-pair-name>.pem ubuntu@<public-ip>
```

The public IP is printed at the end of the build script. Allow a minute or two after the stack completes for the UserData script to finish installing Terraform.

Verify Terraform is installed:

```bash
terraform version
```

## Teardown

```bash
./teardown_stack.sh
```

Deletes both stacks in reverse order (Linux instance first, then base VPC), waiting for each deletion to complete before proceeding.

### Options

| Flag | Description |
|---|---|
| `-k` | Pause for keyboard confirmation before deletion begins |

```bash
./teardown_stack.sh -k
```

> **Note:** If a stack deletion fails (e.g., due to a retained resource), the script will report an error and exit rather than hanging. Check the CloudFormation console for details.

## AMIs

The Linux instance template includes AMI mappings for both supported regions:

| Region | AMI | OS |
|---|---|---|
| `us-east-1` | `ami-02013f5b15758f4d4` | Ubuntu 22.04 LTS (Jammy), 2026-06-02 |
| `us-west-2` | `ami-03a1c8d65318aa1fc` | Ubuntu 22.04 LTS (Jammy), 2026-06-02 |

To add another region, add an entry to the `RegionMap` in `ExistingVPC_LinuxInstance.yaml` and update `stack_parameters.sh`.
