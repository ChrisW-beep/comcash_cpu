import json

# Load the output file
with open("metrics_output_batch.json", "r") as f:
    data = json.load(f)

# Print the content in a formatted way
print(json.dumps(data, indent=4))
