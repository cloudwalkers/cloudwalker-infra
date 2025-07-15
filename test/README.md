# Terraform Module Testing

This directory contains comprehensive tests for all Terraform modules using multiple testing approaches.

## Testing Approaches

### 1. Terratest (Go-based Integration Tests)
- **Location**: `*_test.go` files
- **Purpose**: End-to-end testing with real AWS resources
- **Benefits**: Tests actual resource creation and configuration

### 2. Terraform Validate Tests
- **Location**: `terraform_validate_test.go`
- **Purpose**: Syntax and configuration validation
- **Benefits**: Fast feedback without creating resources

### 3. Static Analysis Tests
- **Location**: `static_analysis_test.go`
- **Purpose**: Code quality and security checks
- **Benefits**: Catches common issues and security problems

## Prerequisites

### AWS Setup
```bash
# Configure AWS credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### Go Setup
```bash
# Install Go (version 1.21+)
# Initialize the module
go mod init
go mod tidy
```

### Required Tools
```bash
# Install additional tools
go install github.com/terraform-linters/tflint@latest
go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
```

## Running Tests

### All Tests
```bash
# Run all tests
go test -v ./...

# Run tests in parallel
go test -v -parallel 10 ./...

# Run with timeout
go test -v -timeout 30m ./...
```

### Specific Test Categories

#### Validation Tests (Fast)
```bash
# Run only validation tests
go test -v -run TestTerraformValidate ./...

# Run syntax checks
go test -v -run TestTerraformPlan ./...
```

#### Integration Tests (Slow)
```bash
# Run VPC tests
go test -v -run TestVPC ./...

# Run EC2 tests  
go test -v -run TestEC2 ./...

# Run ELB tests
go test -v -run TestELB ./...
```

#### Static Analysis Tests
```bash
# Run security and quality checks
go test -v -run TestStaticAnalysis ./...
```

## Test Structure

### Unit Tests
- Test individual modules in isolation
- Use mock data where possible
- Focus on configuration validation

### Integration Tests
- Test modules with real AWS resources
- Verify resource creation and configuration
- Test module interactions

### End-to-End Tests
- Test complete infrastructure stacks
- Verify cross-module integration
- Test realistic scenarios

## Test Examples

### Basic Module Test
```go
func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "name_prefix": "test",
            "vpc_cidr_block": "10.0.0.0/16",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

### Integration Test
```go
func TestVPCWithEC2Integration(t *testing.T) {
    // Create VPC first
    vpcOptions := &terraform.Options{...}
    terraform.InitAndApply(t, vpcOptions)
    
    // Use VPC outputs in EC2 module
    vpcId := terraform.Output(t, vpcOptions, "vpc_id")
    subnetIds := terraform.OutputList(t, vpcOptions, "public_subnet_ids")
    
    ec2Options := &terraform.Options{
        Vars: map[string]interface{}{
            "subnet_ids": subnetIds,
        },
    }
    
    terraform.InitAndApply(t, ec2Options)
}
```

## Best Practices

### Test Organization
- One test file per module
- Group related tests in the same file
- Use descriptive test names

### Resource Management
- Always use `defer terraform.Destroy()`
- Use unique resource names to avoid conflicts
- Clean up resources even if tests fail

### Test Data
- Use random values for resource names
- Use realistic but safe configuration values
- Avoid hardcoded values that might conflict

### Performance
- Run tests in parallel when possible
- Use validation tests for quick feedback
- Reserve integration tests for CI/CD

### Security
- Never commit AWS credentials
- Use least-privilege IAM policies for testing
- Clean up test resources promptly

## Continuous Integration

### GitHub Actions Example
```yaml
name: Terraform Tests
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v3
        with:
          go-version: '1.21'
      - name: Run validation tests
        run: go test -v -run TestTerraformValidate ./...

  integration:
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v3
        with:
          go-version: '1.21'
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2
      - name: Run integration tests
        run: go test -v -timeout 30m ./...
```

## Troubleshooting

### Common Issues
1. **AWS Credentials**: Ensure proper AWS configuration
2. **Resource Conflicts**: Use unique names and clean up resources
3. **Timeouts**: Increase timeout for slow resources (EKS, RDS)
4. **Permissions**: Ensure IAM permissions for all tested resources

### Debug Tips
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG

# Run single test with verbose output
go test -v -run TestSpecificTest ./...

# Keep resources for debugging (remove defer destroy)
# terraform.InitAndApply(t, terraformOptions)
# Don't destroy - inspect resources manually
```