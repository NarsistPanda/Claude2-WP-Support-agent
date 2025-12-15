#!/bin/bash

#================================================================================
# WhatsApp AI Support Agent - Azure Deployment Script
#================================================================================
# This script deploys the complete solution to Azure using ARM templates
# Usage: ./deploy-azure.sh [aci|aks|app-service]
#================================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI found"

    # Check if logged in
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Run 'az login' first"
        exit 1
    fi
    print_success "Logged in to Azure"

    # Check kubectl (only for AKS deployment)
    if [[ "$DEPLOYMENT_TYPE" == "aks" ]]; then
        if ! command -v kubectl &> /dev/null; then
            print_error "kubectl not found. Please install: az aks install-cli"
            exit 1
        fi
        print_success "kubectl found"
    fi

    # Check openssl
    if ! command -v openssl &> /dev/null; then
        print_error "openssl not found. Please install openssl"
        exit 1
    fi
    print_success "openssl found"
}

# Get user inputs
get_user_inputs() {
    print_header "Configuration"

    # Project name
    read -p "Project name (default: whatsapp-support): " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-whatsapp-support}
    print_info "Project name: $PROJECT_NAME"

    # Resource group
    read -p "Resource group name (default: ${PROJECT_NAME}-rg): " RESOURCE_GROUP
    RESOURCE_GROUP=${RESOURCE_GROUP:-${PROJECT_NAME}-rg}
    print_info "Resource group: $RESOURCE_GROUP"

    # Location
    echo ""
    print_info "Common Azure regions:"
    print_info "  - eastus (US East)"
    print_info "  - westus2 (US West 2)"
    print_info "  - westeurope (West Europe)"
    print_info "  - southeastasia (Southeast Asia)"
    read -p "Azure location (default: eastus): " LOCATION
    LOCATION=${LOCATION:-eastus}
    print_info "Location: $LOCATION"

    # WhatsApp credentials
    echo ""
    print_header "WhatsApp Credentials"
    print_info "Get these from Meta Developer Portal: https://developers.facebook.com/"
    read -p "WhatsApp Phone Number ID: " WHATSAPP_PHONE_NUMBER_ID
    read -sp "WhatsApp Access Token: " WHATSAPP_ACCESS_TOKEN
    echo ""

    # OpenAI credentials
    echo ""
    print_header "OpenAI Credentials"
    print_info "Get from: https://platform.openai.com/api-keys"
    read -sp "OpenAI API Key: " OPENAI_API_KEY
    echo ""

    # Generate secure passwords
    print_header "Generating Secure Passwords"
    POSTGRES_ADMIN_PASSWORD=$(openssl rand -base64 32)
    N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
    N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 32)
    WHATSAPP_VERIFY_TOKEN=$(openssl rand -hex 32)
    print_success "All passwords generated"
}

# Create resource group
create_resource_group() {
    print_header "Creating Resource Group"

    if az group exists --name "$RESOURCE_GROUP" | grep -q "true"; then
        print_warning "Resource group '$RESOURCE_GROUP' already exists"
    else
        az group create \
            --name "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --output none
        print_success "Resource group created: $RESOURCE_GROUP"
    fi
}

# Deploy using ARM template
deploy_arm_template() {
    print_header "Deploying ARM Template"

    print_info "This may take 10-15 minutes..."

    DEPLOYMENT_NAME="whatsapp-support-$(date +%Y%m%d-%H%M%S)"

    az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --template-file "../arm-templates/aci-deployment.json" \
        --parameters \
            projectName="$PROJECT_NAME" \
            location="$LOCATION" \
            whatsappPhoneNumberId="$WHATSAPP_PHONE_NUMBER_ID" \
            whatsappAccessToken="$WHATSAPP_ACCESS_TOKEN" \
            whatsappVerifyToken="$WHATSAPP_VERIFY_TOKEN" \
            openaiApiKey="$OPENAI_API_KEY" \
            n8nEncryptionKey="$N8N_ENCRYPTION_KEY" \
            n8nBasicAuthPassword="$N8N_BASIC_AUTH_PASSWORD" \
            postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD" \
        --output none

    print_success "ARM template deployed successfully"
}

# Get deployment outputs
get_deployment_outputs() {
    print_header "Deployment Information"

    # Get the latest deployment
    DEPLOYMENT_NAME=$(az deployment group list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[0].name" -o tsv)

    # Get outputs
    N8N_URL=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs.n8nUrl.value" -o tsv)

    POSTGRES_HOST=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs.postgresHost.value" -o tsv)

    REDIS_HOST=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs.redisHost.value" -o tsv)

    STORAGE_ACCOUNT=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs.storageAccount.value" -o tsv)

    KEYVAULT_NAME=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs.keyVaultName.value" -o tsv)

    ACR_NAME=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs.containerRegistry.value" -o tsv)
}

# Initialize database
initialize_database() {
    print_header "Initializing Database"

    print_info "Installing PostgreSQL client..."
    if ! command -v psql &> /dev/null; then
        print_warning "psql not found. Skipping database initialization."
        print_warning "Please install PostgreSQL client and run:"
        print_warning "  PGPASSWORD='$POSTGRES_ADMIN_PASSWORD' psql -h $POSTGRES_HOST -U n8nadmin -d whatsapp_support_agent -f ../../database-schema.sql"
        print_warning "  PGPASSWORD='$POSTGRES_ADMIN_PASSWORD' psql -h $POSTGRES_HOST -U n8nadmin -d whatsapp_support_agent -f ../../database-schema-enhanced.sql"
        return
    fi

    print_info "Initializing base schema..."
    PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql \
        -h "$POSTGRES_HOST" \
        -U n8nadmin \
        -d whatsapp_support_agent \
        -f "../../database-schema.sql" \
        --quiet

    print_info "Initializing enhanced schema..."
    PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql \
        -h "$POSTGRES_HOST" \
        -U n8nadmin \
        -d whatsapp_support_agent \
        -f "../../database-schema-enhanced.sql" \
        --quiet

    print_success "Database initialized"
}

# Save credentials
save_credentials() {
    print_header "Saving Credentials"

    CREDS_FILE="deployment-credentials-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$CREDS_FILE" <<EOF
========================================
WhatsApp AI Support Agent - Deployment Credentials
========================================
Deployment Date: $(date)
Resource Group: $RESOURCE_GROUP
Location: $LOCATION

========================================
n8n Access
========================================
URL: $N8N_URL
Username: admin
Password: $N8N_BASIC_AUTH_PASSWORD

========================================
Database Access
========================================
Host: $POSTGRES_HOST
Database: whatsapp_support_agent
Username: n8nadmin
Password: $POSTGRES_ADMIN_PASSWORD

========================================
Redis Access
========================================
Host: $REDIS_HOST
Port: 6380 (SSL)
Password: (stored in Key Vault)

========================================
Azure Storage
========================================
Account: $STORAGE_ACCOUNT
Containers:
  - whatsapp-videos
  - whatsapp-voice
  - whatsapp-media

========================================
Azure Key Vault
========================================
Name: $KEYVAULT_NAME

========================================
Azure Container Registry
========================================
Server: $ACR_NAME

========================================
WhatsApp Configuration
========================================
Phone Number ID: $WHATSAPP_PHONE_NUMBER_ID
Verify Token: $WHATSAPP_VERIFY_TOKEN
Webhook URL: ${N8N_URL}/webhook/whatsapp-webhook

========================================
IMPORTANT: Store this file securely!
========================================
EOF

    print_success "Credentials saved to: $CREDS_FILE"
    print_warning "IMPORTANT: Store this file securely and delete it after saving credentials elsewhere!"
}

# Print next steps
print_next_steps() {
    print_header "Deployment Complete! 🎉"

    echo ""
    print_info "Next Steps:"
    echo ""
    print_info "1. Access n8n:"
    print_info "   URL: $N8N_URL"
    print_info "   Username: admin"
    print_info "   Password: $N8N_BASIC_AUTH_PASSWORD"
    echo ""
    print_info "2. Import workflows:"
    print_info "   - whatsapp-support-agent-workflow.json"
    print_info "   - workflows/proactive-messaging-workflow.json"
    echo ""
    print_info "3. Configure WhatsApp webhook in Meta Dashboard:"
    print_info "   Callback URL: ${N8N_URL}/webhook/whatsapp-webhook"
    print_info "   Verify Token: $WHATSAPP_VERIFY_TOKEN"
    echo ""
    print_info "4. Subscribe to webhook events: messages"
    echo ""
    print_info "5. Test by sending a WhatsApp message!"
    echo ""
    print_success "All credentials saved to: $CREDS_FILE"
    echo ""
}

# Main deployment flow
main() {
    clear
    print_header "WhatsApp AI Support Agent - Azure Deployment"

    # Get deployment type
    DEPLOYMENT_TYPE="${1:-aci}"
    print_info "Deployment Type: $DEPLOYMENT_TYPE"

    # Run deployment steps
    check_prerequisites
    get_user_inputs
    create_resource_group
    deploy_arm_template
    get_deployment_outputs
    initialize_database
    save_credentials
    print_next_steps
}

# Run main function
main "$@"
