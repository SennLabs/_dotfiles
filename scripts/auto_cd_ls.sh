#!/bin/bash

TARGET_DIR=$1 # Replace with the actual path

# Change to the target directory
cd "$TARGET_DIR"

# Check if the directory change was successful
if [ $? -eq 0 ]; then
  ls -a --color=auto
else
  echo "Failed to change to $TARGET_DIR. Please check the path."
fi
