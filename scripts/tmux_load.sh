#!/usr/bin/env bash
ram=$(free -m | awk '/Mem:/ {printf "%.0f%%", $3/$2 * 100}')
cpu=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
echo "CPU:${cpu} RAM:${ram}"
