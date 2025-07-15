# 🧪 Comprehensive Terraform Module Testing Guide

This document provides a complete testing strategy for Terraform modules using multiple approaches and tools.

## 📋 **Testing Strategy Overview**

### **Testing Pyramid**
```
                    ┌─────────────────┐
                    │  Integration    │  ← Slow, Expensive, High Confidence
                    │     Tests       │
                    └─────────────────┘
                  ┌───────────────────────┐
                  │    Unit Tests         │  ← Medium Speed, Medium Cost
                  │  (Plan/Validate)      │
                  └───────────────────────┘
              ┌─────────────────────────────────┐
              │      Static Analysis            │  ← Fast, Cheap, Low Confidence
              │  (Lint/Format/Security)         │
              └─────────────────────────────────┘
```

## 🛠️ **Testing Tools & Frameworks**

### **1. Terratest (Go-based)**
- **Purpose**: End-to-end integration testing
- **Benefits**: Tests real AWS resources, comprehensive validation
- **Use Cases**: Module functionality, resource creation, integration testing

### **2. Terraform Native Tools**
- **terraform validate**: Syntax and configuration validation
- **terraform plan**: Dry-run testing without resource creation
- **terraform fmt**: Code formatting validation

### **3. Static Analysis Tools**
- **TFLint**: Terraform-specific linting and best practices
- **TFSec**: Security vulnerability scanning
- **Checkov**: Policy-as-code security scanning

### **4. Documentation Tools**
- **terraform-docs**: Automatic documentation generation
- **Custom scripts**: README validation and structure checks

## 📁 **Test Structure**

```
test/
├── go.mod                      # Go module dependencies
├── README.md                   # Testing documentation
├── vpc_test.go                 # VPC module tests
├── ec2_test.go                 # EC2 module tests
├── elb_test.go                 # ELB module tests
├── ecs_test.go                 # ECS module tests
├── eks_test.go                 # EKS module tests
├── storage_test.go             # Storage module tests
├── integration_test.go         # Cross-module integration tests
├── terraform_validate_test.go  # Validation tests
└── static_analysis_test.go     # Static analysis tests

examples/
├── vpc-basic/                  # Basic VPC example for testing
├── ec2-basic/                  # Basic EC2 example for testing
└── complete-stack/             # Full stack integration example

scripts/
└── test.sh                     # Comprehensive testing script

.github/workflows/
└── terraform-tests.yml         # CI/CD pipeline
```

## 🚀 **Quick Start**

### **Prerequisites**
```bash
# Install required tools
go install github.com/terraform-linters/tflint@latest
go install github.com/aquasecurity/tfsec/cmd/tfsec@latest

# Configure AWS credentials
aws configure
# or
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-west-2"
```

### **Run Tests**
```bash
# Quick validation (no AWS resources)
./scripts/test.sh fast

# Full test suite (creates AWS resources)
./scripts/test.sh all

# Specific test categories
./scripts/test.sh validate    # Syntax validation
./scripts/test.sh static      # Security & linting
./scripts/test.sh unit        # Plan tests
./scripts/test.sh integration # Real resource tests
```

## 📊 **Test Categories**

### **1. Static Analysis Tests** ⚡ (Fast)
```bash
# Run static analysis
go test -v -run TestStaticAnalysis ./...
```

**What it tests:**
- ✅ Terraform syntax and formatting
- ✅ Security vulnerabilities (TFSec)
- ✅ Best practices and linting (TFLint)
- ✅ Module structure and documentation
- ✅ Variable and output descriptions

**Benefits:**
- Very fast execution (seconds)
- No AWS costs
- Catches common issues early
- Enforces coding standards

### **2. Validation Tests** ⚡ (Fast)
```bash
# Run validation tests
go test -v -run TestTerraformValidate ./...
```

**What it tests:**
- ✅ Terraform configuration syntax
- ✅ Provider version constraints
- ✅ Resource configuration validity
- ✅ Variable type validation

**Benefits:**
- Fast execution (under 1 minute)
- No AWS costs
- Validates configuration correctness

### **3. Unit Tests** 🔄 (Medium)
```bash
# Run unit tests
go test -v -run TestTerraformPlan ./...
```

**What it tests:**
- ✅ Terraform plan generation
- ✅ Resource dependencies
- ✅ Configuration logic
- ✅ Variable interpolation

**Benefits:**
- Medium execution time (1-5 minutes)
- No AWS costs
- Tests configuration logic

### **4. Integration Tests** 🐌 (Slow)
```bash
# Run integration tests
go test -v -timeout 30m -run "TestVPC|TestEC2|TestELB" ./...
```

**What it tests:**
- ✅ Real AWS resource creation
- ✅ Resource configuration accuracy
- ✅ Cross-module integration
- ✅ End-to-end functionality

**Benefits:**
- High confidence testing
- Tests real-world scenarios
- Validates actual AWS behavior

**Costs:**
- Creates real AWS resources
- Incurs AWS charges
- Longer execution time (10-30 minutes)

## 🔧 **Test Examples**

### **Basic Module Test**
```go
func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "name_prefix": "test-vpc",
            "vpc_cidr_block": "10.0.0.0/16",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

### **Integration Test**
```go
func TestVPCWithEC2Integration(t *testing.T) {
    // Create VPC
    vpcOptions := createVPCOptions()
    defer terraform.Destroy(t, vpcOptions)
    terraform.InitAndApply(t, vpcOptions)
    
    // Get VPC outputs
    vpcId := terraform.Output(t, vpcOptions, "vpc_id")
    subnetIds := terraform.OutputList(t, vpcOptions, "public_subnet_ids")
    
    // Create EC2 using VPC outputs
    ec2Options := &terraform.Options{
        Vars: map[string]interface{}{
            "subnet_ids": subnetIds,
        },
    }
    
    defer terraform.Destroy(t, ec2Options)
    terraform.InitAndApply(t, ec2Options)
    
    // Verify integration
    asgName := terraform.Output(t, ec2Options, "autoscaling_group_name")
    assert.NotEmpty(t, asgName)
}
```

## 🔄 **CI/CD Integration**

### **GitHub Actions Workflow**
The project includes a comprehensive GitHub Actions workflow that:

1. **Validation Stage**: Fast syntax and format checks
2. **Static Analysis**: Security and linting
3. **Unit Tests**: Plan validation
4. **Integration Tests**: Real resource testing (main branch only)
5. **Security Scanning**: Checkov policy validation
6. **Documentation**: terraform-docs validation
7. **Cost Estimation**: Infracost integration

### **Pipeline Stages**
```yaml
validate → static-analysis → integration → security → docs
    ↓           ↓              ↓          ↓       ↓
  Fast        Medium         Slow      Fast    Fast
 (30s)       (2min)        (30min)    (1min)  (30s)
```

## 💰 **Cost Management**

### **Cost-Effective Testing**
1. **Use Spot Instances**: For non-critical test resources
2. **Small Instance Types**: t2.micro, t3.nano for testing
3. **Automatic Cleanup**: Always use `defer terraform.Destroy()`
4. **Parallel Testing**: Reduce total execution time
5. **Conditional Integration**: Only run on main branch

### **Resource Cleanup**
```go
// Always clean up resources
defer terraform.Destroy(t, terraformOptions)

// Use unique names to avoid conflicts
namePrefix := random.UniqueId()

// Set reasonable timeouts
terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    // ... configuration
})
```

## 🛡️ **Security Testing**

### **Security Checks**
- **TFSec**: Scans for security vulnerabilities
- **Checkov**: Policy-as-code validation
- **Custom Rules**: Organization-specific security policies

### **Security Test Example**
```bash
# Run security scan
tfsec modules/ --format json --soft-fail

# Check for high/critical issues
if grep -q '"severity":"HIGH"' results.json; then
    echo "High severity security issues found!"
    exit 1
fi
```

## 📈 **Best Practices**

### **Test Organization**
- ✅ One test file per module
- ✅ Group related tests together
- ✅ Use descriptive test names
- ✅ Include both positive and negative tests

### **Resource Management**
- ✅ Always use `defer terraform.Destroy()`
- ✅ Use unique resource names
- ✅ Set appropriate timeouts
- ✅ Handle test failures gracefully

### **Performance**
- ✅ Run tests in parallel when possible
- ✅ Use validation tests for quick feedback
- ✅ Reserve integration tests for critical paths
- ✅ Cache dependencies in CI/CD

### **Maintainability**
- ✅ Keep tests simple and focused
- ✅ Use helper functions for common operations
- ✅ Document complex test scenarios
- ✅ Regular test maintenance and updates

## 🔍 **Troubleshooting**

### **Common Issues**
1. **AWS Credentials**: Ensure proper AWS configuration
2. **Resource Conflicts**: Use unique names and clean up
3. **Timeouts**: Increase timeout for slow resources (EKS, RDS)
4. **Permissions**: Ensure IAM permissions for all tested resources

### **Debug Tips**
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG

# Run single test with verbose output
go test -v -run TestSpecificTest ./...

# Keep resources for manual inspection
# Comment out: defer terraform.Destroy(t, terraformOptions)
```

## 📚 **Additional Resources**

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Terraform Testing Best Practices](https://www.terraform.io/docs/extend/testing/index.html)
- [TFLint Rules](https://github.com/terraform-linters/tflint/tree/master/docs/rules)
- [TFSec Checks](https://aquasecurity.github.io/tfsec/latest/checks/)

---

This comprehensive testing strategy ensures your Terraform modules are reliable, secure, and maintainable while providing fast feedback during development and thorough validation before production deployment.