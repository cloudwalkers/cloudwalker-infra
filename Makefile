plan:
	@terraform plan -var-file=terraform.tfvars
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
	@terraform apply -var-file=terraform.tfvars -auto-approve
	@terraform apply -var-file=terraform.tfvars -auto-approve -out=tfplan
	@terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0] == "create") | .address' | sort -u > create_resources.txt
	@terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0] == "update") | .address' | sort -u > update_resources.txt
	@terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0] == "delete") | .address' | sort -u > delete_resources.txt
	@echo "Resources to be created:"
	@cat create_resources.txt
	@echo "Resources to be updated:"
	@cat update_resources.txt
	@echo "Resources to be deleted:"
	@cat delete_resources.txt
	@echo "Terraform apply completed successfully."

destroy:
	@terraform destroy -var-file=terraform.tfvars
	@terraform destroy -var-file=terraform.tfvars -out=tfplan
	@terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0] == "create") | .address' | sort -u > create_resources.txt
	@terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0] == "update") | .address' | sort -u > update_resources.txt
	@terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0] == "delete") | .address' | sort -u > delete_resources.txt
	@echo "Resources to be created:"
	@cat create_resources.txt
	@echo "Resources to be updated:"
	@cat update_resources.txt
	@echo "Resources to be deleted:"
	@cat delete_resources.txt
	@echo "Destroy completed. Review the output above for details."
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
workspace:
	@terraform workspace list
	@echo "Terraform workspaces listed successfully."
	@terraform workspace new <workspace_name>
	@echo "New Terraform workspace created successfully."
	@terraform workspace select <workspace_name>
	@echo "Switched to Terraform workspace successfully."
	@terraform workspace delete <workspace_name>
	@echo "Terraform workspace deleted successfully."
	@terraform workspace select default
	@echo "Switched back to default Terraform workspace successfully."
	@terraform workspace show
	@echo "Current Terraform workspace displayed successfully."
variables:
	@terraform output -json | jq -r 'keys[]' > variables.txt
	@echo "Terraform variables listed successfully."
	@cat variables.txt
	@echo "Terraform variables displayed successfully."
	@echo "Terraform variables saved to variables.txt."
	@echo "Terraform variables listed successfully."
	@terraform output -json | jq -r '.[].value' > variables_values.txt
	@echo "Terraform variable values saved to variables_values.txt."
	@echo "Terraform variable values listed successfully."
	@cat variables_values.txt
	@echo "Terraform variable values displayed successfully."
	@echo "Terraform variable values listed successfully."
	@terraform output -json | jq -r '.[].sensitive' > sensitive_variables.txt
	@echo "Terraform sensitive variables saved to sensitive_variables.txt."
	@echo "Terraform sensitive variables listed successfully."
	@cat sensitive_variables.txt
	@echo "Terraform sensitive variables displayed successfully."
	@echo "Terraform sensitive variables listed successfully."
	@terraform output -json | jq -r '.[].type' > variable_types.txt
	@echo "Terraform variable types saved to variable_types.txt."
	@echo "Terraform variable types listed successfully."
	@cat variable_types.txt
	@echo "Terraform variable types displayed successfully."
	@echo "Terraform variable types listed successfully."
	@terraform output -json | jq -r '.[].description' > variable_descriptions.txt
	@echo "Terraform variable descriptions saved to variable_descriptions.txt."
	@echo "Terraform variable descriptions listed successfully."
	@cat variable_descriptions.txt
	@echo "Terraform variable descriptions displayed successfully."
	@echo "Terraform variable descriptions listed successfully."
	@terraform output -json | jq -r '.[].depends_on' > variable_dependencies.txt
	@echo "Terraform variable dependencies saved to variable_dependencies.txt."
	@echo "Terraform variable dependencies listed successfully."
	@cat variable_dependencies.txt
	@echo "Terraform variable dependencies displayed successfully."
	@echo "Terraform variable dependencies listed successfully."
	@terraform output -json | jq -r '.[].sensitive' > sensitive_variables.txt

