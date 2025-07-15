plan:
	@terraform plan -var-file=terraform.tfvars -out=tfplan
	@terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0] == "create") | .address' | sort -u > create_resources.txt
	@terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0] == "update") | .address' | sort -u > update_resources.txt
	@terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0] == "delete") | .address' | sort -u > delete_resources.txt
	@echo "Resources to be created:"
	@cat create_resources.txt
	@echo "Resources to be updated:"
	@cat update_resources.txt
	@echo "Resources to be deleted:"
	@cat delete_resources.txt
	@echo "Plan completed. Review the output above for details."

apply:	
	@terraform apply tfplan
	@echo "Terraform apply completed successfully."

destroy:
	@terraform plan -destroy -var-file=terraform.tfvars -out=destroy.tfplan
	@terraform apply destroy.tfplan
	@echo "Terraform destroy completed successfully."
init:
	@terraform init
	@echo "Terraform initialized successfully."
validate:
	@terraform validate
	@echo "Terraform configuration validated successfully."
format:
	@terraform fmt
	@echo "Terraform configuration formatted successfully."
lint:
	@terraform fmt -check
	@terraform validate
	@echo "Terraform configuration linted successfully."
import:
	@terraform import -var-file=terraform.tfvars <resource_type>.<resource_name> <resource_id>
	@echo "Terraform resource imported successfully."
output:
	@terraform output
	@echo "Terraform output displayed successfully."
refresh:
	@terraform refresh
	@echo "Terraform state refreshed successfully."
show:
	@terraform show
	@echo "Terraform state displayed successfully."
state:
	@terraform state list
	@echo "Terraform state listed successfully."
workspace-list:
	@terraform workspace list
	@terraform workspace show
	@echo "Current workspace displayed above."

workspace-new:
	@terraform workspace new $(NAME)
	@echo "New workspace '$(NAME)' created and selected."

workspace-select:
	@terraform workspace select $(NAME)
	@echo "Switched to workspace '$(NAME)'."

workspace-delete:
	@terraform workspace delete $(NAME)
	@echo "Workspace '$(NAME)' deleted."
variables:
	@terraform output -json | jq -r 'keys[]' > variables.txt
	@echo "Output variables saved to variables.txt"
	@cat variables.txt

clean:
	@rm -f tfplan destroy.tfplan *.txt
	@echo "Cleaned up temporary files."

help:
	@echo "Available targets:"
	@echo "  init          - Initialize Terraform"
	@echo "  validate      - Validate Terraform configuration"
	@echo "  format        - Format Terraform files"
	@echo "  lint          - Check formatting and validate"
	@echo "  plan          - Create execution plan"
	@echo "  apply         - Apply changes from plan"
	@echo "  destroy       - Destroy infrastructure"
	@echo "  output        - Show output values"
	@echo "  variables     - List output variables"
	@echo "  state         - List resources in state"
	@echo "  show          - Show current state"
	@echo "  refresh       - Refresh state"
	@echo "  clean         - Clean temporary files"
	@echo "  workspace-list    - List workspaces"
	@echo "  workspace-new     - Create new workspace (use NAME=<name>)"
	@echo "  workspace-select  - Select workspace (use NAME=<name>)"
	@echo "  workspace-delete  - Delete workspace (use NAME=<name>)"
	@echo ""
	@echo "Usage examples:"
	@echo "  make plan"
	@echo "  make apply"
	@echo "  make workspace-new NAME=staging"
	@echo "  make workspace-select NAME=production"

.PHONY: plan apply destroy init validate format lint import output refresh show state workspace-list workspace-new workspace-select workspace-delete variables clean help