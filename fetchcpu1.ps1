# Set AWS profile and output file paths
$profile = "comcash"
$instanceDataFile = "C:\comcash_cpu\instance_data.json"
$outputFile = "C:\comcash_cpu\filtered_cpu_metrics.txt"

# Step 1: Fetch Instance IDs and Names
aws ec2 describe-instances `
    --profile $profile `
    --filters "Name=instance-type,Values=t2.small,t2.medium,t2.large" `
    --query "Reservations[*].Instances[*].{InstanceId:InstanceId,Name:Tags[?Key=='Name'].Value | [0]}" `
    --output json > $instanceDataFile

# Step 2: Load Instances and Filter by Name
$instanceData = Get-Content -Path $instanceDataFile | ConvertFrom-Json

# Filter out instances with no Name or names containing "test", "dev", or "clone"
$filteredInstances = $instanceData | Where-Object {
    $_.Name -ne $null -and $_.Name -ne "" -and $_.Name -notmatch 'test|dev|clone|ca'
}

# Check filtered count
Write-Host "Filtered instances: $($filteredInstances.Count)"

# Step 3: Fetch CPU Utilization for Filtered Instances
# Initialize output file
Clear-Content -Path $outputFile -ErrorAction SilentlyContinue

# Time range
# $startTime = (Get-Date).AddDays(-7).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
# $endTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Set explicit time range for analysis
$startTime = "2024-11-25T00:00:00Z"  # Start: November 25, 2024, at midnight UTC
$endTime = "2024-12-05T23:59:59Z"   # End: December 5, 2024, at 11:59 PM UTC


foreach ($instance in $filteredInstances) {
    $instanceId = $instance.InstanceId
    $instanceName = $instance.Name
    Write-Host "Fetching metrics for: $instanceId ($instanceName)"
    
    # Fetch CPU metrics using AWS CLI for the specified time range
    $metrics = aws cloudwatch get-metric-statistics `
        --profile $profile `
        --namespace AWS/EC2 `
        --metric-name CPUUtilization `
        --start-time $startTime `
        --end-time $endTime `
        --period 1800 `
        --statistics Average `
        --dimensions Name=InstanceId,Value=$instanceId `
        --output json | ConvertFrom-Json

    # Get max CPU utilization
    $maxCpu = 0
    if ($metrics.Datapoints.Count -gt 0) {
        $maxCpu = ($metrics.Datapoints | Measure-Object -Property Average -Maximum).Maximum
    }

    # Append result to the output file
    Add-Content -Path $outputFile -Value "Instance: $instanceId, Name: $instanceName, Max CPU: $maxCpu%"
}


# Step 4: Display Top 10 Results
Write-Host "`nTop Instances by CPU Utilization:"
Get-Content -Path $outputFile | Sort-Object -Descending | Select-Object -First 25
