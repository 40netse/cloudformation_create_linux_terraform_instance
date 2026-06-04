#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$k,
    [int]$p = 15
)

. "$PSScriptRoot\stack_parameters.ps1"

$pause = $p

function Get-StackStatus {
    param([string]$StackName, [string]$Region)
    $stacks = aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --output json --region $Region |
              ConvertFrom-Json
    return ($stacks.StackSummaries | Where-Object { $_.StackName -eq $StackName } | Measure-Object).Count
}

function Get-StackOutputs {
    param([string]$StackName, [string]$Region)
    $result = aws cloudformation describe-stacks --stack-name $StackName --output json --region $Region |
              ConvertFrom-Json
    return $result.Stacks[0].Outputs
}

# ── Stack 1: Base VPC ─────────────────────────────────────────────────────────

if ($k) {
    Read-Host "Press Enter to deploy $stack1 template"
}

Write-Host "Deploying $stack1 Template"

if ((Get-StackStatus -StackName $stack1 -Region $region) -eq 0) {
    aws cloudformation create-stack `
        --stack-name $stack1 `
        --region $region `
        --template-body file://NewVPC_BaseSetup_Single.yaml `
        --parameters `
            ParameterKey=VPCCIDR,ParameterValue=$vpcCidr `
            ParameterKey=Public1Subnet,ParameterValue=$subnetCidr `
            ParameterKey=AZForSubnet1,ParameterValue=$awsAz | Out-Null
}

Write-Host "Waiting for $stack1 to reach CREATE_COMPLETE..."
$created = $false
for ($c = 1; $c -le 50; $c++) {
    if ((Get-StackStatus -StackName $stack1 -Region $region) -ne 0) {
        $created = $true
        break
    }
    Start-Sleep -Seconds $pause
}
if (-not $created) {
    Write-Error "Timed out waiting for $stack1 to reach CREATE_COMPLETE."
    exit 1
}

$outputs = Get-StackOutputs -StackName $stack1 -Region $region
$vpc     = ($outputs | Where-Object { $_.OutputKey -eq "VPCID"    }).OutputValue
$subnet  = ($outputs | Where-Object { $_.OutputKey -eq "SubnetID" }).OutputValue

Write-Host ""
Write-Host "============================================"
Write-Host " Base VPC Stack: $stack1"
Write-Host "============================================"
Write-Host " Region:            $region"
Write-Host " Availability Zone: $awsAz"
Write-Host " VPC ID:            $vpc  ($vpcCidr)"
Write-Host " Subnet ID:         $subnet  ($subnetCidr)"
Write-Host "============================================"
Write-Host ""

# ── Stack 2: Linux Instance ───────────────────────────────────────────────────

if ($k) {
    Read-Host "Press Enter to deploy $stack2 template"
}

Write-Host "Deploying $stack2 Template"

if ((Get-StackStatus -StackName $stack2 -Region $region) -eq 0) {
    aws cloudformation create-stack `
        --stack-name $stack2 `
        --region $region `
        --capabilities CAPABILITY_IAM `
        --template-body file://ExistingVPC_LinuxInstance.yaml `
        --parameters `
            ParameterKey=VPCID,ParameterValue=$vpc `
            ParameterKey=Public1Subnet,ParameterValue=$subnet `
            ParameterKey=KeyPair,ParameterValue=$key `
            ParameterKey=InstanceType,ParameterValue=$linuxInstanceType `
            ParameterKey=CIDRForInstanceAccess,ParameterValue=$access `
            ParameterKey=AZForInstance1,ParameterValue=$awsAz | Out-Null
}

Write-Host "Waiting for $stack2 to reach CREATE_COMPLETE..."
$created = $false
for ($c = 1; $c -le 50; $c++) {
    if ((Get-StackStatus -StackName $stack2 -Region $region) -ne 0) {
        $created = $true
        break
    }
    Start-Sleep -Seconds $pause
}
if (-not $created) {
    Write-Error "Timed out waiting for $stack2 to reach CREATE_COMPLETE."
    exit 1
}

$outputs  = Get-StackOutputs -StackName $stack2 -Region $region
$instance = ($outputs | Where-Object { $_.OutputKey -eq "LinuxInstanceID" }).OutputValue
$ip       = ($outputs | Where-Object { $_.OutputKey -eq "LinuxInstanceIP" }).OutputValue

Write-Host ""
Write-Host "============================================"
Write-Host " Linux Instance Stack: $stack2"
Write-Host "============================================"
Write-Host " Instance ID:    $instance"
Write-Host " Instance Type:  $linuxInstanceType"
Write-Host " Key Pair:       $key"
Write-Host " Public IP:      $ip"
Write-Host " Access CIDR:    $access"
Write-Host "--------------------------------------------"
Write-Host " SSH:  ssh -i $key.pem ubuntu@$ip"
Write-Host "============================================"
Write-Host ""
