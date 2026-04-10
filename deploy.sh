#!/bin/bash
# Initialize Terraform environment and deploy infrastructure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Docker-Apps Terraform Deployment Script               ║"
echo "╚════════════════════════════════════════════════════════════════╝"

# Check prerequisites
echo ""
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not installed. Installing..."
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - 2>/dev/null || true
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" 2>/dev/null || true
    sudo apt-get update 2>/dev/null || true
    sudo apt-get install -y terraform
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not installed. Please install kubectl first."
    exit 1
fi

# Verify kubectl access
echo ""
echo "🔗 Verifying Kubernetes access..."
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ Unable to access Kubernetes cluster"
    exit 1
fi

NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
echo "✅ Kubernetes cluster found with $NODE_COUNT nodes"

# Menu
select action in "init" "validate" "plan" "apply" "destroy" "refresh-state" "import-resource" "quit"; do
    case $action in
        init)
            echo ""
            echo "🔧 Initializing Terraform..."
            terraform init
            echo "✅ Terraform initialized"
            ;;
        validate)
            echo ""
            echo "✓ Validating Terraform configuration..."
            terraform validate
            terraform fmt -recursive -check
            echo "✅ Configuration valid"
            ;;
        plan)
            echo ""
            echo "📋 Planning Terraform changes..."
            terraform plan -out=tfplan
            echo ""
            echo "✅ Plan saved to tfplan"
            ;;
        apply)
            echo ""
            echo "🚀 Applying Terraform changes..."
            if [ -f tfplan ]; then
                terraform apply tfplan
                rm tfplan
            else
                terraform apply
            fi
            echo ""
            echo "✅ Deployment complete!"
            echo ""
            echo "View outputs:"
            terraform output
            ;;
        destroy)
            echo ""
            echo "⚠️  DESTROYING ALL RESOURCES"
            read -p "Type 'yes' to confirm: " confirm
            if [ "$confirm" = "yes" ]; then
                terraform destroy
                echo "✅ Resources destroyed"
            else
                echo "❌ Destroy cancelled"
            fi
            ;;
        refresh-state)
            echo ""
            echo "🔄 Refreshing Terraform state..."
            terraform refresh
            echo "✅ State refreshed"
            ;;
        import-resource)
            echo ""
            read -p "Enter resource type (e.g., kubernetes_deployment.portfolio): " res_type
            read -p "Enter Kubernetes resource ID (e.g., portfolio/portfolio-web): " res_id
            terraform import "$res_type" "$res_id"
            echo "✅ Resource imported"
            ;;
        quit)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    echo ""
    echo "What next?"
done
