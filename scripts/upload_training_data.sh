#!/bin/bash
set -e

BUCKET=$(cd terraform && terraform output -raw training_bucket)
DATA_FILE="data/train.csv"

if [ ! -f "$DATA_FILE" ]; then
  echo "Error: $DATA_FILE not found."
  echo "Add your training CSV to the data/ directory before uploading."
  exit 1
fi

echo "Uploading training data to s3://$BUCKET/data/train.csv ..."
aws s3 cp "$DATA_FILE" "s3://$BUCKET/data/train.csv"
echo "Done."
