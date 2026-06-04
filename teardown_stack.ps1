#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$k
)

. "$PSScriptRoot\stack_parameters.ps1"

function Get-StackSummary {
    param([string]$StackName, [string]$Region)
    $result = aws cloudformation list-stacks `
                  --stack-status-filter CREATE_COMPLETE `
                  --output json --region $Region | ConvertFrom-Json
    return $result.StackSummaries | Where-Object { $_.StackName -eq $StackName } | Select-Object -First 1
}

function Remove-Stack {
    param([string]$StackName, [string]$Region)
    Write-Host "Deleting $StackName in $Region..."
    aws cloudformation delete-stack --stack-name $StackName --region $Region | Out-Null
}

function Wait-ForStackDeletion {
    param([string]$StackId, [string]$StackName, [string]$Region)

    Write-Host "Waiting for $StackName deletion..."
    for ($c = 1; $c -le 40; $c++) {
        $result = aws cloudformation list-stacks --output json --region $Region | ConvertFrom-Json
        $stack  = $result.StackSummaries | Where-Object { $_.StackId -eq $StackId } | Select-Object -First 1

        if ($null -eq $stack) {
            Write-Host "$StackName not found in stack list — deletion complete."
            return $true
        }

        switch ($stack.StackStatus) {
            "DELETE_COMPLETE" {
                Write-Host "$StackName deletion complete."
                return $true
            }
            "DELETE_FAILED" {
                Write-Error "$StackName deletion failed (DELETE_FAILED). Manual cleanup required."
                return $false
            }
        }

        Start-Sleep -Seconds 15
    }

    Write-Error "Timed out waiting for $StackName deletion."
    return $false
}

# ── Locate stacks ─────────────────────────────────────────────────────────────

$s2 = Get-StackSummary -StackName $stack2 -Region $region
$s1 = Get-StackSummary -StackName $stack1 -Region $region

Write-Host ""
Write-Host "Stack 2: $($s2.StackName)  id: $($s2.StackId)  region: $region"
Write-Host "Stack 1: $($s1.StackName)  id: $($s1.StackId)  region: $region"
Write-Host ""

if ($k) {
    Read-Host "Press Enter to delete both stacks"
}

# ── Delete stack2 first (depends on stack1) ───────────────────────────────────

if ($null -ne $s2) {
    Remove-Stack -StackName $s2.StackName -Region $region
    $ok = Wait-ForStackDeletion -StackId $s2.StackId -StackName $s2.StackName -Region $region
    if (-not $ok) { exit 1 }
} else {
    Write-Host "$stack2 not found, skipping."
}

# ── Delete stack1 ─────────────────────────────────────────────────────────────

if ($null -ne $s1) {
    Remove-Stack -StackName $s1.StackName -Region $region
    $ok = Wait-ForStackDeletion -StackId $s1.StackId -StackName $s1.StackName -Region $region
    if (-not $ok) { exit 1 }
} else {
    Write-Host "$stack1 not found, skipping."
}

Write-Host "Done."
