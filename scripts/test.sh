#!/bin/bash

# Terraform Module Testing Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    # Check if go is installed
    if ! command -v go &> /dev/null; then
        print_error "Go is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_warning "AWS credentials not configured or invalid"
        print_warning "Some tests may fail"
    fi
    
    print_success "Prerequisites check completed"
}

# Install testing tools
install_tools() {
    print_status "Installing testing tools..."
    
    # Install tflint
    if ! command -v tflint &> /dev/null; then
        print_status "Installing tflint..."
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    fi
    
    # Install tfsec
    if ! command -v tfsec &> /dev/null; then
        print_status "Installing tfsec..."
        go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
    fi
    
    print_success "Testing tools installed"
}

# Format all Terraform files
format_terraform() {
    print_status "Formatting Terraform files..."
    
    find . -name "*.tf" -exec terraform fmt {} \;
    
    print_success "Terraform files formatted"
}

# Run validation tests
run_validation_tests() {
    print_status "Running validation tests..."
    
    cd test
    go test -v -run TestTerraformValidate ./...
    
    print_success "Validation tests completed"
}

# Run static analysis tests
run_static_analysis() {
    print_status "Running static analysis..."
    
    cd test
    go test -v -run TestStaticAnalysis ./...
    
    print_success "Static analysis completed"
}

# Run unit tests (fast tests that don't create resources)
run_unit_tests() {
    print_status "Running unit tests..."
    
    cd test
    go test -v -run TestTerraformPlan ./...
    
    print_success "Unit tests completed"
}

# Run integration tests (slow tests that create real resources)
run_integration_tests() {
    print_status "Running integration tests..."
    print_warning "This will create real AWS resources and may incur costs"
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Integration tests skipped"
        return
    fi
    
    cd test
    go test -v -timeout 30m -run "TestVPC|TestEC2|TestELB" ./...
    
    print_success "Integration tests completed"
}

# Clean up test resources
cleanup() {
    print_status "Cleaning up test resources..."
    
    # This would typically involve running terraform destroy on any test infrastructure
    # For now, we'll just clean up any temporary files
    find . -name "*.tfplan" -delete
    find . -name "*.tfstate*" -delete
    find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    
    print_success "Cleanup completed"
}

# Main function
main() {
    print_status "Starting Terraform module testing..."
    
    # Parse command line arguments
    case "${1:-all}" in
        "prereq")
            check_prerequisites
            ;;
        "install")
            install_tools
            ;;
        "format")
            format_terraform
            ;;
        "validate")
            check_prerequisites
            run_validation_tests
            ;;
        "static")
            check_prerequisites
            install_tools
            run_static_analysis
            ;;
        "unit")
            check_prerequisites
            run_unit_tests
            ;;
        "integration")
            check_prerequisites
            run_integration_tests
            ;;
        "fast")
            check_prerequisites
            format_terraform
            run_validation_tests
            run_static_analysis
            run_unit_tests
            ;;
        "all")
            check_prerequisites
            install_tools
            format_terraform
            run_validation_tests
            run_static_analysis
            run_unit_tests
            run_integration_tests
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            echo "Usage: $0 {prereq|install|format|validate|static|unit|integration|fast|all|cleanup}"
            echo ""
            echo "Commands:"
            echo "  prereq      - Check prerequisites"
            echo "  install     - Install testing tools"
            echo "  format      - Format Terraform files"
            echo "  validate    - Run validation tests"
            echo "  static      - Run static analysis"
            echo "  unit        - Run unit tests"
            echo "  integration - Run integration tests (creates real resources)"
            echo "  fast        - Run all fast tests (no resource creation)"
            echo "  all         - Run all tests"
            echo "  cleanup     - Clean up test artifacts"
            exit 1
            ;;
    esac
    
    print_success "Testing completed successfully!"
}

# Run main function
main "$@"