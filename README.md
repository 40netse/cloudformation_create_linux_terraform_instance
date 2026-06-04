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

---

## Prerequisites

### All platforms

- An EC2 key pair in the target region (create one in the AWS Console under EC2 → Key Pairs)
- Sufficient IAM permissions to create VPCs, EC2 instances, IAM roles, and CloudFormation stacks

### Linux / macOS

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured:

```bash
aws configure
```

### Windows

**1. Install the AWS CLI**

Download and run the MSI installer from:  
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

After installation, open PowerShell and configure your credentials:

```powershell
aws configure
```

You will be prompted for:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (enter `us-east-1`)
- Default output format (enter `json`)

**2. Allow PowerShell scripts to run (one-time setup)**

Windows blocks unsigned scripts by default. Run this once in PowerShell to allow locally downloaded scripts to execute:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

This only affects scripts on your local machine — it does not lower security for scripts downloaded from the internet.

---

## Configuration

Edit the parameters file for your platform before deploying.

**Linux/macOS** — `stack_parameters.sh`  
**Windows** — `stack_parameters.ps1`

| Variable | Default | Description |
|---|---|---|
| `region` | `us-east-1` | AWS region to deploy into |
| `aws_az` | `us-east-1a` | Availability zone for subnet and instance |
| `vpc_cidr` | `10.0.0.0/16` | CIDR block for the VPC |
| `subnet_cidr` | `10.0.0.0/24` | CIDR block for the public subnet |
| `linux_instance_type` | `c4.large` | EC2 instance type |
| `key` | `mdw-poc-common` | EC2 key pair name (must exist in the target region) |
| `access` | `0.0.0.0/0` | CIDR allowed SSH access — restrict this for production |

---

## Deploy

### Linux / macOS

```bash
./build_stack.sh
```

| Flag | Description |
|---|---|
| `-k` | Pause for keyboard confirmation between each stack deployment |
| `-p <seconds>` | Override the polling interval (default: 15 seconds) |

```bash
# Deploy with confirmation prompts
./build_stack.sh -k

# Deploy with a 30-second polling interval
./build_stack.sh -p 30
```

### Windows (PowerShell)

Open PowerShell, navigate to the repo directory, and run:

```powershell
.\build_stack.ps1
```

| Flag | Description |
|---|---|
| `-k` | Pause for keyboard confirmation between each stack deployment |
| `-p <seconds>` | Override the polling interval (default: 15 seconds) |

```powershell
# Deploy with confirmation prompts
.\build_stack.ps1 -k

# Deploy with a 30-second polling interval
.\build_stack.ps1 -p 30
```

### Expected output

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
 SSH:  ssh -i mdw-poc-common.pem ubuntu@3.90.x.x
============================================
```

---

## Connect via SSH

The public IP and SSH command are printed at the end of the build script. Allow a minute or two after the stack completes for the UserData script to finish installing Terraform.

### Linux / macOS

```bash
ssh -i ~/.ssh/<key-pair-name>.pem ubuntu@<public-ip>
```

### Windows

**Option 1 — Built-in OpenSSH (Windows 10/11, recommended)**

Windows 10 and Windows 11 include a built-in OpenSSH client. Open PowerShell and connect directly using your `.pem` key file:

```powershell
ssh -i C:\path\to\<key-pair-name>.pem ubuntu@<public-ip>
```

If OpenSSH is not installed, enable it via **Settings → Apps → Optional Features → Add a feature → OpenSSH Client**.

**Option 2 — PuTTY**

PuTTY uses its own `.ppk` key format instead of `.pem`. Before connecting you must convert the key:

1. Download and install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) (includes PuTTYgen)
2. Open **PuTTYgen**, click **Load**, select your `.pem` file (change the file filter to *All Files*)
3. Click **Save private key** to export a `.ppk` file
4. Open **PuTTY**, enter the public IP as the hostname, then go to **Connection → SSH → Auth → Credentials** and browse to your `.ppk` file
5. Log in as user `ubuntu`

### Verify Terraform is installed

Once connected:

```bash
terraform version
```

---

## Teardown

### Linux / macOS

```bash
./teardown_stack.sh
```

| Flag | Description |
|---|---|
| `-k` | Pause for keyboard confirmation before deletion begins |

```bash
./teardown_stack.sh -k
```

### Windows (PowerShell)

```powershell
.\teardown_stack.ps1
```

| Flag | Description |
|---|---|
| `-k` | Pause for keyboard confirmation before deletion begins |

```powershell
.\teardown_stack.ps1 -k
```

Deletes both stacks in reverse order (Linux instance first, then base VPC), waiting for each deletion to complete before proceeding.

> **Note:** If a stack deletion fails (e.g., due to a retained resource), the script will report an error and exit rather than hanging. Check the CloudFormation console for details.

---

## AMIs

The Linux instance template includes AMI mappings for both supported regions:

| Region | AMI | OS |
|---|---|---|
| `us-east-1` | `ami-02013f5b15758f4d4` | Ubuntu 22.04 LTS (Jammy), 2026-06-02 |
| `us-east-2` | `ami-0209ee5cb40d1c54b` | Ubuntu 22.04 LTS (Jammy), 2026-06-02 |
| `us-west-2` | `ami-03a1c8d65318aa1fc` | Ubuntu 22.04 LTS (Jammy), 2026-06-02 |

To add another region, add an entry to the `RegionMap` in `ExistingVPC_LinuxInstance.yaml` and update the parameters file for your platform.
