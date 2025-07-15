package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TestTerraformValidateAllModules validates the syntax of all Terraform modules
func TestTerraformValidateAllModules(t *testing.T) {
	modules := []string{
		"../modules/vpc",
		"../modules/ec2",
		"../modules/ecs",
		"../modules/eks",
		"../modules/elb",
		"../modules/storage",
	}

	for _, module := range modules {
		t.Run(module, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: module,
			}

			// Run terraform validate
			terraform.Validate(t, terraformOptions)
		})
	}
}

// TestTerraformPlanAllModules runs terraform plan on all modules to check for syntax errors
func TestTerraformPlanAllModules(t *testing.T) {
	modules := []string{
		"../modules/vpc",
		"../modules/ec2", 
		"../modules/ecs",
		"../modules/eks",
		"../modules/elb",
		"../modules/storage",
	}

	for _, module := range modules {
		t.Run(module, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: module,
				PlanFilePath: "tfplan",
			}

			// Run terraform init and plan
			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}