#!/bin/bash

TARGET_DIR=$1

echo "Permissions|Owner|Group|Size|Modified|Name"

ls -ahl "$TARGET_DIR" | tail -n +2

