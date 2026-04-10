TERRAFORM_DIR := terraform

.PHONY: deploy upload run status endpoint destroy fmt validate help

help:
	@echo ""
	@echo "  sagemaker-secure-pipeline"
	@echo ""
	@echo "  make deploy     provision all infrastructure (VPC, KMS, IAM, S3, SageMaker, CloudWatch)"
	@echo "  make upload     upload training data to S3"
	@echo "  make run        trigger the SageMaker Pipeline execution"
	@echo "  make status     poll pipeline execution status"
	@echo "  make endpoint   provision the real-time inference endpoint (run after pipeline completes)"
	@echo "  make destroy    tear down all AWS resources"
	@echo "  make fmt        run terraform fmt across all modules"
	@echo "  make validate   run terraform validate"
	@echo ""

deploy:
	cd $(TERRAFORM_DIR) && terraform init
	cd $(TERRAFORM_DIR) && terraform validate
	cd $(TERRAFORM_DIR) && terraform plan -out=tfplan
	cd $(TERRAFORM_DIR) && terraform apply tfplan

upload:
	bash scripts/upload_training_data.sh

run:
	python scripts/run_pipeline.py

status:
	python scripts/check_pipeline_status.py

endpoint:
	cd $(TERRAFORM_DIR) && terraform apply -target=module.endpoint

destroy:
	cd $(TERRAFORM_DIR) && terraform destroy

fmt:
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

validate:
	cd $(TERRAFORM_DIR) && terraform init -backend=false && terraform validate
