import chardet
import json

# Detect file encoding
with open("instance_ids.txt", "rb") as f:
    raw_data = f.read()
    result = chardet.detect(raw_data)
    encoding = result['encoding']
    print(f"Detected encoding: {encoding}")

# Load instance IDs with detected encoding
with open("instance_ids.txt", "r", encoding=encoding) as f:
    instance_ids = f.read().splitlines()

# Clean and validate instance IDs
valid_ids = [id.strip() for id in instance_ids if id.strip().startswith("i-")]

# Generate CloudWatch metric queries
metric_queries = []
for idx, instance_id in enumerate(valid_ids):
    metric_queries.append({
        "Id": f"query{idx}",
        "MetricStat": {
            "Metric": {
                "Namespace": "AWS/EC2",
                "MetricName": "CPUUtilization",
                "Dimensions": [
                    {"Name": "InstanceId", "Value": instance_id}
                ]
            },
            "Period": 3600,
            "Stat": "Average"
        },
        "ReturnData": True
    })

# Save to JSON
with open("metric_queries.json", "w", encoding="utf-8") as f:
    json.dump(metric_queries, f, indent=4)

print(f"Metric queries saved to metric_queries.json. Total queries: {len(valid_ids)}")
