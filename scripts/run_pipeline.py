"""
Trigger the SageMaker Pipeline execution.
Run via: make run
"""

import boto3
import subprocess
import json
from datetime import datetime

def get_terraform_output(key):
    result = subprocess.run(
        ["terraform", "output", "-raw", key],
        cwd="terraform",
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout.strip()

def main():
    pipeline_name   = get_terraform_output("pipeline_name")
    training_bucket = get_terraform_output("training_bucket")
    artifacts_bucket = get_terraform_output("artifacts_bucket")
    execution_role  = get_terraform_output("execution_role_arn")

    client = boto3.client("sagemaker")

    print(f"Starting pipeline execution: {pipeline_name}")

    response = client.start_pipeline_execution(
        PipelineName=pipeline_name,
        PipelineExecutionDisplayName=f"run-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
        PipelineParameters=[
            {"Name": "TrainingBucket",  "Value": training_bucket},
            {"Name": "ArtifactsBucket", "Value": artifacts_bucket},
            {"Name": "ExecutionRole",   "Value": execution_role},
        ]
    )

    execution_arn = response["PipelineExecutionArn"]
    print(f"Execution ARN: {execution_arn}")
    print()
    print("Pipeline is running. Check progress with:")
    print("  make status")
    print()
    print("Autopilot will run up to 4 hours. Once complete, approve the model")
    print("in the SageMaker Model Registry then run:")
    print("  make endpoint")

if __name__ == "__main__":
    main()
