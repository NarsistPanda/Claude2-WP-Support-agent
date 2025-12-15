# Azure Deployment Artifacts

This directory contains all necessary files and templates for deploying the WhatsApp AI Support Agent solution to Microsoft Azure.

## 📁 Directory Structure

```
azure/
├── README.md                           # This file
├── arm-templates/                      # Azure Resource Manager templates
│   ├── aci-deployment.json            # Complete ACI deployment
│   └── parameters.json                # ARM template parameters
├── bicep/                             # Bicep templates (IaC alternative to ARM)
├── github-actions/                     # CI/CD workflows
│   └── azure-deployment.yml           # GitHub Actions workflow
├── kubernetes/                         # Kubernetes manifests for AKS
│   ├── namespace.yaml                 # Kubernetes namespace
│   ├── configmap.yaml                 # Configuration data
│   ├── n8n-deployment.yaml            # n8n deployment
│   ├── n8n-service.yaml               # n8n service
│   ├── n8n-ingress.yaml               # Ingress controller
│   └── hpa.yaml                       # Horizontal Pod Autoscaler
├── scripts/                           # Deployment scripts
│   └── deploy-azure.sh                # Interactive Azure deployment script
└── terraform/                         # Terraform configurations (alternative IaC)
```

## 🚀 Quick Start

### Option 1: Automated Deployment Script (Recommended)

```bash
# Navigate to scripts directory
cd azure/scripts

# Make script executable
chmod +x deploy-azure.sh

# Run deployment
./deploy-azure.sh aci
```

The script will:
1. Check prerequisites
2. Collect credentials
3. Create Azure resources
4. Deploy the solution
5. Initialize database
6. Provide access credentials

### Option 2: Manual ARM Template Deployment

```bash
# Set variables
RESOURCE_GROUP="whatsapp-support-rg"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy ARM template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file arm-templates/aci-deployment.json \
  --parameters arm-templates/parameters.json
```

### Option 3: AKS Deployment with Kubectl

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group whatsapp-support-rg \
  --name whatsapp-support-aks

# Apply Kubernetes manifests
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/n8n-deployment.yaml
kubectl apply -f kubernetes/n8n-service.yaml
kubectl apply -f kubernetes/hpa.yaml
kubectl apply -f kubernetes/n8n-ingress.yaml
```

## 📄 File Descriptions

### ARM Templates

#### `arm-templates/aci-deployment.json`
Complete ARM template that deploys:
- Azure Container Instances (n8n)
- Azure Database for PostgreSQL Flexible Server
- Azure Cache for Redis
- Azure Blob Storage (3 containers)
- Azure Key Vault
- Azure Container Registry
- Azure Application Insights

**Usage:**
```bash
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file arm-templates/aci-deployment.json \
  --parameters @arm-templates/parameters.json
```

#### `arm-templates/parameters.json`
Parameter file for the ARM template. References Azure Key Vault for secrets.

**Before using:**
1. Replace `{subscription-id}` with your Azure subscription ID
2. Replace `{rg-name}` with your resource group name
3. Replace `{vault-name}` with your Key Vault name
4. Store secrets in Key Vault first

### Kubernetes Manifests

#### `kubernetes/namespace.yaml`
Creates the `whatsapp-support` namespace for all resources.

#### `kubernetes/configmap.yaml`
Non-sensitive configuration data for n8n and the application.

#### `kubernetes/n8n-deployment.yaml`
Defines the n8n deployment with:
- 3 replicas by default
- Resource limits and requests
- Health checks (liveness and readiness probes)
- Persistent volume for n8n data
- Environment variables from ConfigMap and Secrets

#### `kubernetes/n8n-service.yaml`
ClusterIP service exposing n8n internally on port 80.

#### `kubernetes/n8n-ingress.yaml`
Ingress resource for external access with:
- Nginx ingress controller
- SSL/TLS termination
- Cert-manager integration for Let's Encrypt
- Custom annotations for proxy settings

**Before deploying:**
- Replace `your-domain.com` with your actual domain
- Ensure DNS points to the ingress LoadBalancer IP

#### `kubernetes/hpa.yaml`
Horizontal Pod Autoscaler that:
- Scales between 2-10 pods
- Based on CPU (70%) and Memory (80%) utilization
- Smart scale-up/scale-down policies

### Scripts

#### `scripts/deploy-azure.sh`
Interactive deployment script that:
- Validates prerequisites
- Collects credentials securely
- Generates strong passwords
- Deploys infrastructure
- Initializes databases
- Saves credentials to file

**Features:**
- Color-coded output
- Error handling
- Progress indicators
- Credential management
- Post-deployment instructions

**Usage:**
```bash
./deploy-azure.sh [aci|aks|app-service]
```

### GitHub Actions

#### `github-actions/azure-deployment.yml`
Complete CI/CD pipeline for Azure deployment with:
- Automated builds on push to main/production
- Manual workflow dispatch with environment selection
- Docker image build and push to ACR
- Infrastructure deployment via ARM templates
- AKS deployment with rolling updates
- Slack notifications

**Required Secrets:**
```
AZURE_CREDENTIALS
AZURE_SUBSCRIPTION_ID
ACR_LOGIN_SERVER
ACR_USERNAME
ACR_PASSWORD
WHATSAPP_PHONE_NUMBER_ID
WHATSAPP_ACCESS_TOKEN
WHATSAPP_VERIFY_TOKEN
OPENAI_API_KEY
N8N_ENCRYPTION_KEY
N8N_BASIC_AUTH_PASSWORD
POSTGRES_ADMIN_PASSWORD
AZURE_POSTGRES_HOST
AZURE_POSTGRES_USER
AZURE_POSTGRES_PASSWORD
AZURE_REDIS_HOST
AZURE_REDIS_PASSWORD
AZURE_STORAGE_ACCOUNT
AZURE_STORAGE_KEY
SLACK_WEBHOOK_URL (optional)
```

## 🔐 Security Best Practices

### 1. Use Azure Key Vault

Store all secrets in Azure Key Vault:

```bash
# Create Key Vault
az keyvault create \
  --resource-group $RESOURCE_GROUP \
  --name my-keyvault \
  --location $LOCATION

# Store secrets
az keyvault secret set --vault-name my-keyvault --name "whatsapp-token" --value "your-token"
```

### 2. Enable Managed Identity

For AKS, use managed identities to access Azure resources without credentials:

```bash
# Enable managed identity on AKS
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --enable-managed-identity
```

### 3. Network Security

- Use Azure Virtual Network for isolation
- Enable Private Endpoints for PostgreSQL and Redis
- Use Network Security Groups (NSG)
- Enable Azure Firewall

### 4. Enable Azure Security Center

```bash
# Enable Security Center Standard tier
az security pricing create --name VirtualMachines --tier standard
az security pricing create --name SqlServers --tier standard
az security pricing create --name StorageAccounts --tier standard
```

## 💰 Cost Estimation

### Development (ACI)
- Container Instances: ~$35/month
- PostgreSQL Burstable: ~$25/month
- Redis Basic: ~$16/month
- Storage: ~$2/month
- Application Insights: ~$5/month
**Total: ~$83/month**

### Production (AKS)
- AKS (3 nodes): ~$210/month
- PostgreSQL General Purpose: ~$180/month
- Redis Standard: ~$75/month
- Storage + CDN: ~$12/month
- Application Insights: ~$15/month
- Load Balancer: ~$22/month
**Total: ~$517/month**

### Cost Optimization Tips
1. Use Azure Reserved Instances (save 30-50%)
2. Auto-shutdown for non-production environments
3. Use Blob Storage lifecycle management
4. Enable Azure Advisor recommendations
5. Monitor with Azure Cost Management

## 📊 Monitoring

### Azure Application Insights

View metrics and logs:

```bash
# Get Application Insights key
az monitor app-insights component show \
  --resource-group $RESOURCE_GROUP \
  --app whatsapp-support-insights \
  --query instrumentationKey -o tsv
```

### Azure Monitor Logs

Query logs:

```bash
# Enable diagnostic settings
az monitor diagnostic-settings create \
  --resource $RESOURCE_ID \
  --name diagnostics \
  --logs '[{"category": "AllLogs", "enabled": true}]' \
  --workspace $LOG_ANALYTICS_WORKSPACE_ID
```

### Kubernetes Monitoring (AKS)

```bash
# View pods
kubectl get pods -n whatsapp-support

# View logs
kubectl logs -f deployment/whatsapp-support-n8n -n whatsapp-support

# View metrics
kubectl top pods -n whatsapp-support
```

## 🔄 CI/CD Setup

### 1. Setup GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions

Add all required secrets listed in the GitHub Actions section above.

### 2. Setup Azure Service Principal

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-whatsapp-support" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth
```

Copy the output and add to GitHub Secrets as `AZURE_CREDENTIALS`.

### 3. Trigger Deployment

Push to main branch or manually trigger from GitHub Actions tab.

## 🐛 Troubleshooting

### Container Won't Start

```bash
# View logs
az container logs --resource-group $RESOURCE_GROUP --name whatsapp-support-n8n

# Check events
az container show --resource-group $RESOURCE_GROUP --name whatsapp-support-n8n --query instanceView.events
```

### Database Connection Issues

```bash
# Test connection
PGPASSWORD=$PASSWORD psql -h $HOST -U $USER -d $DATABASE -c "SELECT version();"

# Check firewall
az postgres flexible-server firewall-rule list --resource-group $RESOURCE_GROUP --name $SERVER_NAME
```

### AKS Deployment Issues

```bash
# Check pod status
kubectl describe pod -n whatsapp-support

# View events
kubectl get events -n whatsapp-support --sort-by='.lastTimestamp'

# Check logs
kubectl logs -f deployment/whatsapp-support-n8n -n whatsapp-support
```

## 📚 Additional Resources

- [Azure Documentation](https://docs.microsoft.com/en-us/azure/)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [ARM Template Reference](https://docs.microsoft.com/en-us/azure/templates/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Main Deployment Guide](../AZURE-DEPLOYMENT.md)

## 🆘 Support

For Azure-specific issues:
1. Check [AZURE-DEPLOYMENT.md](../AZURE-DEPLOYMENT.md)
2. Review Azure Portal for resource status
3. Check Application Insights for errors
4. Review AKS logs if using Kubernetes

For application issues:
1. Check [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
2. Review [FEATURES.md](../FEATURES.md)
3. Check n8n execution logs

---

**Ready to deploy?** Start with the automated script for the easiest experience:

```bash
cd azure/scripts
./deploy-azure.sh
```
