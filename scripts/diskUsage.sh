#!/bin/bash

# Set the threshold for disk usage (in percentage)
threshold=90

# Get disk usage percentage
disk_usage=$(df -h /System/Volumes/Data | awk 'NR==2 {print $5}' | cut -d'%' -f1) #Line 2 column 5

# Check if disk usage exceeds the threshold
if [ $disk_usage -gt $threshold ]; then
    echo "Disk usage is above $threshold%."
    echo "Current disk usage: $disk_usage%"
    # Add commands to notify the administrator (e.g., send an email, write to log)
else
    echo "Disk usage is within acceptable limits."
    echo "Current disk usage: $disk_usage%"
fi
