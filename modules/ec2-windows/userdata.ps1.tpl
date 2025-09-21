<powershell>
$ErrorActionPreference = 'Stop'
$log = "C:\ProgramData\ec2-bootstrap-${instance_name}.log"
New-Item -ItemType Directory -Path (Split-Path $log) -Force | Out-Null
"Starting userdata for ${instance_name} at $(Get-Date)" | Out-File $log -Append

# Download & install CloudWatch Agent
Write-Output "Downloading CloudWatch Agent" | Out-File $log -Append
$zip = "C:\CWAgent.zip"
$uri = "https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/AmazonCloudWatchAgent.zip"
Invoke-WebRequest -Uri $uri -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath "C:\CWAgent" -Force
& "C:\CWAgent\install.ps1"

# Fetch CloudWatch agent config from SSM parameter and start agent
Write-Output "Fetching CloudWatch config from SSM parameter ${ssm_parameter}" | Out-File $log -Append
& "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -c ssm:${ssm_parameter} -s

"Userdata finished at $(Get-Date)" | Out-File $log -Append
</powershell>
