# For ACAI: will work in AWS Dev
$env:AWS_PROFILE = "acai_development_org_mgmt"

# Define the path to your Python script
$pythonScriptPath = ".\get_ou_ids.py"

$awsOrgId = "o-3dea23gdqc"
$awsRootOuId = "r-t15w"

# Define the OU assignments mapping OU paths to Service Control Policies (SCPs)
$ouAssignments = @{
    "/root"                                     = @("platinum", "gold")
    "/root/CoreAccounts"                        = @("platinum", "gold")
    "/root/Sandbox"                             = @()  # Empty array means no SCPs assigned
    "/root/WorkloadAccounts"                    = @("platinum", "gold")
    "/root/WorkloadAccounts/BusinessUnit_3"     = @("silver")
    "/root/WorkloadAccounts/*/Non-Prod"         = @("iron")
}

# Convert the paths array to a JSON string
$jsonAssignments  = $ouAssignments | ConvertTo-Json


# Call the Python script with the JSON paths as an argument
& python $pythonScriptPath $awsOrgId $awsRootOuId $jsonAssignments 
