#!/bin/bash

# ============================================================================
# CLEANUP REDUNDANT VERSIONS.TF FILES
# ============================================================================
# This script removes redundant versions.tf files from all modules
# since we now have centralized version management at the root level
# ============================================================================

set -e

echo "🧹 Cleaning up redundant versions.tf files from modules..."

# List of modules to clean up
MODULES=(
    "ec2"
    "ecs" 
    "efs"
    "eks"
    "elb"
    "iam"
    "route53"
    "s3"
    "sns"
    "sqs"
    "vpc"
    "vpc-endpoints"
    "vpc-transit-gw"
)

# Counter for tracking deletions
DELETED_COUNT=0

# Remove versions.tf from each module
for module in "${MODULES[@]}"; do
    MODULE_PATH="modules/${module}/versions.tf"
    
    if [ -f "$MODULE_PATH" ]; then
        echo "  ❌ Removing $MODULE_PATH"
        rm "$MODULE_PATH"
        ((DELETED_COUNT++))
    else
        echo "  ⚠️  $MODULE_PATH not found (already removed?)"
    fi
done

echo ""
echo "✅ Cleanup complete!"
echo "   📊 Removed $DELETED_COUNT versions.tf files"
echo "   🎯 Version constraints are now centralized in root versions.tf"
echo ""
echo "📋 Next steps:"
echo "   1. Review the root versions.tf file"
echo "   2. Run 'terraform init' to reinitialize with new provider constraints"
echo "   3. Test module functionality to ensure compatibility"
echo ""