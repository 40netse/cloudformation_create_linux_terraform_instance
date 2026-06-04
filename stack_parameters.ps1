$stackPrefix        = "terraform-linux-dev"
$stack1             = "$stackPrefix-base"
$stack2             = "$stackPrefix-linux"

$region             = "us-east-1"
$awsAz              = "us-east-1a"

$vpcCidr            = "10.0.0.0/16"
$subnetCidr         = "10.0.0.0/24"
$linuxInstanceType  = "c4.large"
$key                = "mdw-poc-common"
$access             = "0.0.0.0/0"
