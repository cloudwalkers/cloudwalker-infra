#!/bin/bash

# ============================================================================
# GITHUB PAGES SETUP SCRIPT
# ============================================================================
# This script helps you set up GitHub Pages for your Terraform documentation
# ============================================================================

set -e

echo "🚀 Setting up GitHub Pages for CloudWalker Infrastructure Documentation"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "This is not a git repository. Please run this script from your project root."
    exit 1
fi

# Get repository information
REPO_URL=$(git config --get remote.origin.url)
REPO_NAME=$(basename -s .git "$REPO_URL")
GITHUB_USER=$(echo "$REPO_URL" | sed -n 's/.*github\.com[:/]\([^/]*\)\/.*/\1/p')

print_info "Repository: $GITHUB_USER/$REPO_NAME"
print_info "GitHub Pages URL will be: https://$GITHUB_USER.github.io/$REPO_NAME"

echo ""
echo "📋 Setup Steps:"
echo ""

# Step 1: Check if docs workflow exists
if [ -f ".github/workflows/docs.yml" ]; then
    print_status "Documentation workflow already exists"
else
    print_warning "Documentation workflow not found. Please ensure .github/workflows/docs.yml exists."
fi

# Step 2: Create initial docs structure
print_info "Creating initial documentation structure..."

mkdir -p docs/assets/{css,js,images}
mkdir -p docs/{modules,examples}

# Create a basic index if it doesn't exist
if [ ! -f "docs/index.md" ]; then
    cat > docs/index.md << EOF
---
layout: home
title: Home
---

# CloudWalker Infrastructure Documentation

Welcome to the CloudWalker Infrastructure Terraform modules documentation.

## 🏗️ Available Modules

This repository contains production-ready Terraform modules for AWS infrastructure.

[View Module Documentation](modules.html)
EOF
    print_status "Created basic index.md"
fi

# Step 3: GitHub Pages configuration instructions
echo ""
print_info "GitHub Pages Configuration Steps:"
echo ""
echo "1. 🌐 Go to your GitHub repository: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "2. 📊 Click on 'Settings' tab"
echo "3. 📄 Scroll down to 'Pages' section"
echo "4. 🔧 Under 'Source', select 'GitHub Actions'"
echo "5. ✅ Save the settings"
echo ""

# Step 4: Workflow permissions
print_info "Required Workflow Permissions:"
echo ""
echo "1. 🔐 Go to Settings > Actions > General"
echo "2. 📝 Under 'Workflow permissions', select 'Read and write permissions'"
echo "3. ✅ Check 'Allow GitHub Actions to create and approve pull requests'"
echo "4. 💾 Save the settings"
echo ""

# Step 5: Environment setup
print_info "Environment Setup (if needed):"
echo ""
echo "1. 🌍 Go to Settings > Environments"
echo "2. ➕ Click 'New environment'"
echo "3. 📝 Name it 'github-pages'"
echo "4. ✅ Add any required protection rules"
echo ""

# Step 6: Test the setup
print_info "Testing the Setup:"
echo ""
echo "1. 🔄 Push your changes to the main branch:"
echo "   git add ."
echo "   git commit -m '📚 Set up GitHub Pages documentation'"
echo "   git push origin main"
echo ""
echo "2. 👀 Check the Actions tab to see the workflow running"
echo "3. 🌐 Once complete, visit: https://$GITHUB_USER.github.io/$REPO_NAME"
echo ""

# Step 7: Custom domain (optional)
print_info "Optional: Custom Domain Setup:"
echo ""
echo "1. 📝 Create a CNAME file in docs/ with your domain name"
echo "2. 🌐 Configure DNS to point to $GITHUB_USER.github.io"
echo "3. 🔧 Update the domain in GitHub Pages settings"
echo ""

# Step 8: Local testing
print_info "Local Testing (Optional):"
echo ""
echo "Install Jekyll for local testing:"
echo "  gem install bundler jekyll"
echo "  cd docs"
echo "  bundle init"
echo "  bundle add jekyll"
echo "  bundle exec jekyll serve"
echo ""

# Create a quick test
print_info "Creating test documentation..."

# Generate a quick test with terraform-docs if available
if command -v terraform-docs &> /dev/null; then
    print_status "terraform-docs found, generating sample documentation..."
    
    # Generate docs for any existing modules
    for module_dir in modules/*/; do
        if [ -d "$module_dir" ]; then
            module_name=$(basename "$module_dir")
            print_info "Generating docs for $module_name module..."
            
            if [ -f "${module_dir}README.md" ]; then
                terraform-docs markdown table --config .terraform-docs.yml --output-file README.md --output-mode inject "$module_dir" || true
            fi
        fi
    done
else
    print_warning "terraform-docs not found. Install it for automatic documentation generation:"
    echo "  brew install terraform-docs  # macOS"
    echo "  # or download from: https://terraform-docs.io/user-guide/installation/"
fi

echo ""
print_status "GitHub Pages setup complete!"
echo ""
print_info "Next steps:"
echo "1. 📤 Push your changes to GitHub"
echo "2. 🔧 Configure GitHub Pages settings as described above"
echo "3. ⏱️  Wait for the workflow to complete (usually 2-5 minutes)"
echo "4. 🌐 Visit your documentation site!"
echo ""
print_info "Your documentation will be available at:"
echo "   https://$GITHUB_USER.github.io/$REPO_NAME"
echo ""

# Create a reminder file
cat > GITHUB_PAGES_SETUP.md << EOF
# GitHub Pages Setup Reminder

## Repository Information
- **Repository**: $GITHUB_USER/$REPO_NAME
- **Documentation URL**: https://$GITHUB_USER.github.io/$REPO_NAME

## Setup Checklist

- [ ] Enable GitHub Pages in repository settings
- [ ] Set source to "GitHub Actions"
- [ ] Configure workflow permissions (Read and write)
- [ ] Push changes to trigger first build
- [ ] Verify documentation site is accessible

## Useful Commands

\`\`\`bash
# Generate documentation locally
terraform-docs --config .terraform-docs.yml .

# Test Jekyll site locally
cd docs && bundle exec jekyll serve

# Update documentation and deploy
git add . && git commit -m "📚 Update documentation" && git push
\`\`\`

## Troubleshooting

- Check Actions tab for workflow status
- Verify GitHub Pages settings in repository
- Ensure workflow has proper permissions
- Check that docs/ directory contains generated files
EOF

print_status "Created GITHUB_PAGES_SETUP.md with setup reminders"
echo ""
print_info "🎉 Setup complete! Follow the instructions above to activate GitHub Pages."