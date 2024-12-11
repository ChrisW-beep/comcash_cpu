import subprocess
import json

# Load instance IDs
with open("C:\\comcash_cpu\\instance_ids.txt", "r") as f:
    instance_ids = f.read().splitlines()

# Time range
start_time = "2024-11-30T00:00:00Z"
end_time = "2024-12-01T23:59:59Z"

# Fetch metrics for each instance
cpu_data = []
for instance_id in instance_ids:
    print(f"Fetching metrics for: {instance_id}")
    result = subprocess.run([
        "aws", "cloudwatch", "get-metric-statistics",
        "--profile", "comcash",
        "--namespace", "AWS/EC2",
        "--metric-name", "CPUUtilization",
        "--start-time", start_time,
        "--end-time", end_time,
        "--period", "3600",
        "--statistics", "Average",
        "--dimensions", f"Name=InstanceId,Value={instance_id}",
        "--output", "json"
    ], capture_output=True, text=True)

    # Parse the output
    metrics = json.loads(result.stdout)
    datapoints = metrics.get("Datapoints", [])
    if datapoints:
        max_cpu = max(dp["Average"] for dp in datapoints)
        cpu_data.append({"InstanceId": instance_id, "MaxCPU": max_cpu})
    else:
        cpu_data.append({"InstanceId": instance_id, "MaxCPU": 0})

# Sort instances by max CPU usage
cpu_data = sorted(cpu_data, key=lambda x: x["MaxCPU"], reverse=True)

# Print the top 10 instances
print("Top Instances by CPU Utilization:")
for entry in cpu_data[:10]:  # Top 10
    print(f"Instance: {entry['InstanceId']}, Max CPU: {entry['MaxCPU']:.2f}%")
