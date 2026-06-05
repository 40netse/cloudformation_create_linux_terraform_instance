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

### Linux / macOS (`stack_parameters.sh`)

```bash
region=us-east-1           # AWS region to deploy into
aws_az=us-east-1a          # Availability zone for subnet and instance

vpc_cidr="10.0.0.0/16"    # CIDR block for the VPC
subnet_cidr="10.0.0.0/24" # CIDR block for the public subnet
linux_instance_type=c4.large                 # EC2 instance type
key=your-keypair-name                        # EC2 key pair name (must exist in the target region)
access="0.0.0.0/0"                           # CIDR allowed SSH access — restrict for production

management_cidr1="203.0.113.10/32"   # required — SSH and ICMP allowed from this IP
management_cidr2="203.0.113.20/32"   # optional — leave blank ("") to skip
management_cidr3=""                   # optional — leave blank ("") to skip
```

### Windows (`stack_parameters.ps1`)

```powershell
$region            = "us-east-1"    # AWS region to deploy into
$awsAz             = "us-east-1a"   # Availability zone for subnet and instance

$vpcCidr           = "10.0.0.0/16"  # CIDR block for the VPC
$subnetCidr        = "10.0.0.0/24"  # CIDR block for the public subnet
$linuxInstanceType = "c4.large"                  # EC2 instance type
$key               = "your-keypair-name"         # EC2 key pair name (must exist in the target region)
$access            = "0.0.0.0/0"                 # CIDR allowed SSH access — restrict for production

$managementCIDR1   = "203.0.113.10/32"   # required — SSH and ICMP allowed from this IP
$managementCIDR2   = "203.0.113.20/32"   # optional — leave blank ("") to skip
$managementCIDR3   = ""                   # optional — leave blank ("") to skip
```

### Parameter reference

| Parameter | Description |
|---|---|
| `region` / `$region` | AWS region — must match an entry in the template's RegionMap (see AMIs section) |
| `aws_az` / `$awsAz` | Availability zone — must be within the chosen region (e.g. `us-east-1a`) |
| `vpc_cidr` / `$vpcCidr` | VPC CIDR block |
| `subnet_cidr` / `$subnetCidr` | Public subnet CIDR — must fall within the VPC CIDR |
| `linux_instance_type` / `$linuxInstanceType` | EC2 instance type |
| `key` / `$key` | EC2 key pair name — must already exist in the target region |
| `access` / `$access` | CIDR for the general SSH security group — restrict to your IP for production |
| `management_cidr1` / `$managementCIDR1` | First public IP allowed SSH and ICMP — **required**, use `/32` notation |
| `management_cidr2` / `$managementCIDR2` | Second public IP — optional, leave as `""` to omit |
| `management_cidr3` / `$managementCIDR3` | Third public IP — optional, leave as `""` to omit |

> **Note:** `management_cidr2` and `management_cidr3` can be left as `""` — their security group rules are automatically omitted by CloudFormation when blank.

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

## Fortinet UI for Terraform

The instance comes pre-installed with Node.js and `uv`, and the security group allows access to port `3000` from the management CIDRs. This lets you run the [Fortinet UI for Terraform](https://fortinetcloudcse.github.io/fortinet-ui-terraform/) — a web-based UI that automatically generates forms from annotated Terraform templates, letting you deploy FortiGate infrastructure without manually editing `.tfvars` files.

Full workshop documentation: **https://fortinetcloudcse.github.io/fortinet-ui-terraform/**

### Auto-start on deployment

The UI starts automatically — no manual steps required. UserData handles everything on first boot:

1. Clones `https://github.com/FortinetCloudCSE/fortinet-ui-terraform` to `/home/ubuntu/`
2. Runs `SETUP.sh` to install Python and Node.js dependencies
3. Runs `RESTART.sh` to start the backend and frontend
4. Registers a `@reboot` cron job so the UI restarts automatically if the instance is rebooted

By the time CloudFormation reports `CREATE_COMPLETE`, allow a few minutes for UserData to finish, then open a browser to:

```
http://<instance-public-ip>:3000
```

### Services

`RESTART.sh` starts two services:
- **Backend** (FastAPI/uvicorn) on `localhost:8000` — not exposed externally; Vite proxies all `/api` requests to it
- **Frontend** (Vite) on port `3000` — accessible from your browser

### Useful commands

If you need to manually manage the UI after SSHing in:

```bash
# Restart both services
cd ~/fortinet-ui-terraform/ui && ./RESTART.sh

# View logs
tail -f ~/fortinet-ui-terraform/logs/backend.log
tail -f ~/fortinet-ui-terraform/logs/frontend.log

# Stop all services
pkill -f 'vite'
pkill -f 'uvicorn'
```

### Security notes

- Port `3000` is open only to the management CIDRs defined in the parameters file — the UI is not publicly accessible
- Port `8000` (backend) is never exposed externally; the Vite dev server proxies all `/api` requests to `localhost:8000`
- The instance IAM role provides the AWS credentials the UI needs for live dropdowns (regions, keypairs, VPCs) — no `aws configure` needed on the instance

### Workshop reference

The Fortinet UI for Terraform workshop covers:
- [Introduction and architecture](https://fortinetcloudcse.github.io/fortinet-ui-terraform/1_introduction/)
- [Working in the UI](https://fortinetcloudcse.github.io/fortinet-ui-terraform/2_getting_started/2_1_working_in_the_ui/)
- [Example templates](https://fortinetcloudcse.github.io/fortinet-ui-terraform/3_example_templates/)

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
| `us-west-1` | `ami-083532ada23c5c24c` | Ubuntu 22.04 LTS (Jammy), 2026-06-02 |
| `us-west-2` | `ami-03a1c8d65318aa1fc` | Ubuntu 22.04 LTS (Jammy), 2026-06-02 |

To add another region, add an entry to the `RegionMap` in `ExistingVPC_LinuxInstance.yaml` and update the parameters file for your platform.
