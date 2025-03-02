#!/usr/bin/env python3

import os
import pandas as pd
import matplotlib.pyplot as plt
from collections import Counter

# Load results from both containers
results_dir = "./results"
dfs = []

for filename in os.listdir(results_dir):
    if filename.endswith(".csv"):
        file_path = os.path.join(results_dir, filename)
        df = pd.read_csv(file_path)
        dfs.append(df)
        print(f"Loaded {len(df)} results from {filename}")

# Combine all results
all_results = pd.concat(dfs)

# Filter out "no_result" entries
valid_results = all_results[all_results.task_id != "no_result"]

# Convert task_id to numeric to ensure proper comparison
valid_results["task_id"] = pd.to_numeric(valid_results["task_id"])

# Check for duplicate task IDs
task_id_counts = Counter(valid_results.task_id)
duplicates = {task_id: count for task_id, count in task_id_counts.items() if count > 1}

print("\nAnalysis Results:")
print(f"Total valid tasks processed: {len(valid_results)}")
print(f"Number of unique task IDs: {len(task_id_counts)}")
print(f"Number of duplicate task IDs: {len(duplicates)}")

if duplicates:
    print("\nWARNING: Duplicate task IDs found!")
    print("Top 10 duplicated task IDs:")
    for task_id, count in sorted(duplicates.items(), key=lambda x: x[1], reverse=True)[
        :10
    ]:
        print(f"Task ID {task_id} was processed {count} times")

    # Analyze which containers processed the duplicates
    print("\nAnalyzing duplicates by container:")
    for task_id in list(duplicates.keys())[:5]:  # Look at first 5 duplicates
        containers = valid_results[valid_results.task_id == task_id][
            "container_id"
        ].tolist()
        print(f"Task ID {task_id} was processed by: {containers}")
else:
    print(
        "\nSUCCESS: No duplicate task IDs found! Each task was processed exactly once."
    )

# Create a visualization of processing rates
plt.figure(figsize=(12, 6))
for df in dfs:
    container = df["container_id"].iloc[0]
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    df = df.sort_values("timestamp")
    df["cumulative_tasks"] = range(1, len(df) + 1)
    plt.plot(df["timestamp"], df["cumulative_tasks"], label=f"Container {container}")

plt.title("Task Processing Rate Over Time")
plt.xlabel("Time")
plt.ylabel("Cumulative Tasks Processed")
plt.legend()
plt.grid(True)
plt.savefig("./results/processing_rate.png")
print("\nCreated visualization of processing rates (processing_rate.png)")

# Analyze queries per second
for df in dfs:
    container = df["container_id"].iloc[0]
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    first_time = df["timestamp"].min()
    last_time = df["timestamp"].max()
    duration_seconds = (last_time - first_time).total_seconds()
    queries_per_second = len(df) / duration_seconds if duration_seconds > 0 else 0
    print(
        f"Container {container} processed {len(df)} queries in {duration_seconds:.2f} seconds ({queries_per_second:.2f} queries/second)"
    )
