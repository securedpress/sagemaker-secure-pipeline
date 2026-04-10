"""
Poll SageMaker Pipeline execution status and print current step.
Run via: make status
"""

import boto3
import subprocess


def get_terraform_output(key):
    result = subprocess.run(
        ["terraform", "output", "-raw", key],
        cwd="terraform",
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def main():
    pipeline_name = get_terraform_output("pipeline_name")
    client = boto3.client("sagemaker")

    executions = client.list_pipeline_executions(
        PipelineName=pipeline_name,
        SortOrder="Descending",
        MaxResults=1,
    )["PipelineExecutionSummaries"]

    if not executions:
        print("No executions found. Run: make run")
        return

    execution = executions[0]
    execution_arn = execution["PipelineExecutionArn"]
    status = execution["PipelineExecutionStatus"]

    print(f"Pipeline:  {pipeline_name}")
    print(f"Execution: {execution_arn.split('/')[-1]}")
    print(f"Status:    {status}")
    print()

    steps = client.list_pipeline_execution_steps(
        PipelineExecutionArn=execution_arn
    )["PipelineExecutionSteps"]

    print(f"{'Step':<30} {'Status':<20} {'Duration'}")
    print("-" * 70)

    for step in steps:
        name = step.get("StepName", "—")
        s_status = step.get("StepStatus", "—")
        start = step.get("StartTime")
        end = step.get("EndTime")

        if start and end:
            duration = str(end - start).split(".")[0]
        elif start:
            duration = "running..."
        else:
            duration = "—"

        print(f"{name:<30} {s_status:<20} {duration}")

    print()

    if status == "Succeeded":
        print("Pipeline succeeded. Approve the model in Model Registry then run:")
        print("  make endpoint")
    elif status == "Failed":
        print("Pipeline failed. Check the FailStep logs in CloudWatch for the rejection reason.")
    elif status == "Executing":
        print("Pipeline is still running. Re-run 'make status' to check progress.")


if __name__ == "__main__":
    main()
