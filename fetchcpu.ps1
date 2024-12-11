# Load Instance IDs from the file
$instance_ids = Get-Content -Path "C:\comcash_cpu\instance_ids.txt"

# Set start and end times for the desired period (e.g., last weekend)
$start_time = (Get-Date).AddDays(-7).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$end_time = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Output results to a file
$output_file = "C:\comcash_cpu\cpu_metrics_output.txt"
Clear-Content -Path $output_file -ErrorAction SilentlyContinue

# Loop through each instance and fetch CPU metrics
foreach ($instance_id in $instance_ids) {
    Write-Output "Fetching metrics for Instance ID: $instance_id" | Tee-Object -FilePath $output_file -Append
    aws cloudwatch get-metric-statistics `
        --profile comcash `
        --namespace AWS/EC2 `
        --metric-name CPUUtilization `
        --start-time $start_time `
        --end-time $end_time `
        --period 3600 `
        --statistics Average `
        --dimensions Name=InstanceId,Value=$instance_id `
        --output table | Tee-Object -FilePath $output_file -Append
}
