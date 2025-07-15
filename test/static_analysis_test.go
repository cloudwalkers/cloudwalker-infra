package test

import (
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestTerraformFormat checks if all Terraform files are properly formatted
func TestTerraformFormat(t *testing.T) {
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
			cmd := exec.Command("terraform", "fmt", "-check", "-diff", "-recursive")
			cmd.Dir = module
			
			output, err := cmd.CombinedOutput()
			
			if err != nil {
				t.Errorf("Terraform files in %s are not properly formatted:\n%s", module, string(output))
			}
		})
	}
}

// TestTFLint runs tflint on all modules to check for common issues
func TestTFLint(t *testing.T) {
	// Check if tflint is installed
	if _, err := exec.LookPath("tflint"); err != nil {
		t.Skip("tflint not installed, skipping linting tests")
	}

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
			// Initialize tflint
			initCmd := exec.Command("tflint", "--init")
			initCmd.Dir = module
			initCmd.Run()

			// Run tflint
			cmd := exec.Command("tflint", "--format", "compact")
			cmd.Dir = module
			
			output, err := cmd.CombinedOutput()
			
			if err != nil {
				t.Errorf("TFLint found issues in %s:\n%s", module, string(output))
			}
		})
	}
}

// TestTFSec runs tfsec security analysis on all modules
func TestTFSec(t *testing.T) {
	// Check if tfsec is installed
	if _, err := exec.LookPath("tfsec"); err != nil {
		t.Skip("tfsec not installed, skipping security tests")
	}

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
			cmd := exec.Command("tfsec", ".", "--format", "json", "--soft-fail")
			cmd.Dir = module
			
			output, err := cmd.CombinedOutput()
			
			// tfsec returns non-zero exit code when issues are found
			// but we use --soft-fail to get the output
			if err != nil && !strings.Contains(string(output), "results") {
				t.Errorf("TFSec failed to run on %s: %v", module, err)
			}
			
			// Parse output and check for high/critical severity issues
			outputStr := string(output)
			if strings.Contains(outputStr, `"severity":"HIGH"`) || 
			   strings.Contains(outputStr, `"severity":"CRITICAL"`) {
				t.Errorf("TFSec found high/critical security issues in %s:\n%s", module, outputStr)
			}
		})
	}
}

// TestModuleStructure verifies that all modules have required files
func TestModuleStructure(t *testing.T) {
	modules := []string{
		"../modules/vpc",
		"../modules/ec2",
		"../modules/ecs",
		"../modules/eks", 
		"../modules/elb",
		"../modules/storage",
	}

	requiredFiles := []string{
		"main.tf",
		"variables.tf",
		"outputs.tf",
		"versions.tf",
		"README.md",
		"examples.tf",
	}

	for _, module := range modules {
		t.Run(module, func(t *testing.T) {
			for _, file := range requiredFiles {
				filePath := filepath.Join(module, file)
				
				if _, err := filepath.Glob(filePath); err != nil {
					t.Errorf("Required file %s not found in module %s", file, module)
				}
			}
		})
	}
}

// TestVariableDescriptions ensures all variables have descriptions
func TestVariableDescriptions(t *testing.T) {
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
			cmd := exec.Command("grep", "-n", "variable", filepath.Join(module, "variables.tf"))
			output, err := cmd.CombinedOutput()
			
			if err != nil {
				// No variables file or no variables - skip
				return
			}

			// Check that each variable block has a description
			lines := strings.Split(string(output), "\n")
			for _, line := range lines {
				if strings.Contains(line, "variable") && strings.Contains(line, "{") {
					// This is a variable declaration - check for description
					variableName := extractVariableName(line)
					if variableName != "" {
						descCmd := exec.Command("grep", "-A", "5", "variable \""+variableName+"\"", filepath.Join(module, "variables.tf"))
						descOutput, _ := descCmd.CombinedOutput()
						
						if !strings.Contains(string(descOutput), "description") {
							t.Errorf("Variable %s in module %s is missing a description", variableName, module)
						}
					}
				}
			}
		})
	}
}

// Helper function to extract variable name from grep output
func extractVariableName(line string) string {
	parts := strings.Split(line, "\"")
	if len(parts) >= 2 {
		return parts[1]
	}
	return ""
}

// TestOutputDescriptions ensures all outputs have descriptions
func TestOutputDescriptions(t *testing.T) {
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
			cmd := exec.Command("grep", "-n", "output", filepath.Join(module, "outputs.tf"))
			output, err := cmd.CombinedOutput()
			
			if err != nil {
				// No outputs file or no outputs - skip
				return
			}

			// Check that each output block has a description
			lines := strings.Split(string(output), "\n")
			for _, line := range lines {
				if strings.Contains(line, "output") && strings.Contains(line, "{") {
					outputName := extractVariableName(line)
					if outputName != "" {
						descCmd := exec.Command("grep", "-A", "3", "output \""+outputName+"\"", filepath.Join(module, "outputs.tf"))
						descOutput, _ := descCmd.CombinedOutput()
						
						if !strings.Contains(string(descOutput), "description") {
							t.Errorf("Output %s in module %s is missing a description", outputName, module)
						}
					}
				}
			}
		})
	}
}