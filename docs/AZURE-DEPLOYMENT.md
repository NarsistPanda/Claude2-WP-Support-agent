# Azure Deployment Guide - WhatsApp AI Support Agent v2.0

**Complete guide for deploying the WhatsApp AI Support Agent solution to Microsoft Azure**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Azure Services Architecture](#azure-services-architecture)
3. [Deployment Options](#deployment-options)
4. [Prerequisites](#prerequisites)
5. [Quick Start - Azure Container Instances](#quick-start---azure-container-instances)
6. [Production Deployment - Azure Kubernetes Service](#production-deployment---azure-kubernetes-service)
7. [Azure Database Services Setup](#azure-database-services-setup)
8. [Azure Storage Configuration](#azure-storage-configuration)
9. [Azure Key Vault for Secrets](#azure-key-vault-for-secrets)
10. [Monitoring with Azure Application Insights](#monitoring-with-azure-application-insights)
11. [CI/CD with GitHub Actions](#cicd-with-github-actions)
12. [Cost Optimization](#cost-optimization)
13. [Security Best Practices](#security-best-practices)
14. [Troubleshooting](#troubleshooting)
15. [Scaling Strategies](#scaling-strategies)

---

## Overview

This guide provides multiple deployment strategies for running the WhatsApp AI Support Agent on Microsoft Azure, from simple container deployments to enterprise-grade Kubernetes clusters.

### What You'll Deploy

**Core Services:**
- **Compute**: Azure Container Instances (ACI) or Azure Kubernetes Service (AKS)
- **Database**: Azure Database for PostgreSQL Flexible Server
- **Cache**: Azure Cache for Redis
- **Storage**: Azure Blob Storage (for videos/media)
- **Secrets**: Azure Key Vault
- **Monitoring**: Azure Application Insights & Azure Monitor
- **Registry**: Azure Container Registry (ACR)

**v2.0 Features Supported:**
- ✅ Human Handoff (via Azure Logic Apps or Functions)
- ✅ Proactive Messaging (scheduled via Azure Functions)
- ✅ Voice Responses (audio files in Blob Storage)
- ✅ Video Support (stored in Blob Storage with CDN)

---

## Azure Services Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Front Door                        │
│                    (CDN + Load Balancing)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────┴────────────────────────────────────┐
│                    Azure Application Gateway                     │
│                  (WAF + SSL Termination)                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
    ┌─────────▼──────────┐      ┌──────────▼──────────┐
    │  Azure Kubernetes  │      │ Azure Container     │
    │  Service (AKS)     │  OR  │ Instances (ACI)     │
    │                    │      │                     │
    │  - n8n Pods        │      │ - n8n Container     │
    │  - Worker Pods     │      │ - Worker Container  │
    └─────────┬──────────┘      └──────────┬──────────┘
              │                            │
              └──────────────┬─────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌────────▼────────┐  ┌──────▼────────┐
│ Azure Database │  │ Azure Cache     │  │ Azure Blob    │
│ for PostgreSQL │  │ for Redis       │  │ Storage       │
│                │  │                 │  │               │
│ - pgvector     │  │ - Queue         │  │ - Videos      │
│ - 18 tables    │  │ - Sessions      │  │ - Voice       │
│ - Automated    │  │ - Cache         │  │ - Media       │
│   backups      │  │                 │  │               │
└────────────────┘  └─────────────────┘  └───────────────┘

┌──────────────────────────────────────────────────────────┐
│              Supporting Services                          │
├──────────────────────────────────────────────────────────┤
│ Azure Key Vault          │ Secrets & Keys                │
│ Azure Monitor            │ Logs & Metrics                │
│ Azure Application        │ APM & Tracing                 │
│   Insights               │                               │
│ Azure Container Registry │ Docker Images                 │
│ Azure Virtual Network    │ Network Isolation             │
│ Azure Logic Apps         │ Human Handoff Workflows       │
│ Azure Functions          │ Proactive Messaging           │
└──────────────────────────────────────────────────────────┘
```

### Service Comparison

| Service | Use Case | Cost | Scalability | Complexity |
|---------|----------|------|-------------|------------|
| **Azure Container Instances** | Development, Testing, Small-scale | $ | Manual | Low |
| **Azure App Service** | Small to Medium Production | $$ | Auto (limited) | Medium |
| **Azure Container Apps** | Modern Microservices | $$ | Auto | Medium |
| **Azure Kubernetes Service** | Enterprise, High-scale | $$$ | Auto (advanced) | High |

---

## Deployment Options

### Option 1: Azure Container Instances (ACI)
**Best for**: Development, testing, proof-of-concept
- **Pros**: Quick setup, serverless, pay-per-second
- **Cons**: Limited scaling, no auto-healing
- **Cost**: ~$50-100/month
- **Setup Time**: 15 minutes

### Option 2: Azure App Service
**Best for**: Small to medium production deployments
- **Pros**: Managed platform, easy deployment, built-in autoscale
- **Cons**: Docker support limitations, less flexible
- **Cost**: ~$100-300/month
- **Setup Time**: 30 minutes

### Option 3: Azure Container Apps
**Best for**: Modern cloud-native applications
- **Pros**: Kubernetes-based, event-driven scaling, KEDA support
- **Cons**: Newer service, fewer community resources
- **Cost**: ~$150-400/month
- **Setup Time**: 45 minutes

### Option 4: Azure Kubernetes Service (AKS)
**Best for**: Enterprise production, high-scale, multi-region
- **Pros**: Full control, advanced scaling, multi-region support
- **Cons**: Complex setup, requires Kubernetes expertise
- **Cost**: ~$300-1000+/month
- **Setup Time**: 2-4 hours

---

## Prerequisites

### Required Tools

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Kubectl (for AKS)
az aks install-cli

# Helm (for AKS)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Terraform (optional)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Azure Account Setup

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your Subscription Name"

# Verify
az account show

# Register required resource providers
az provider register --namespace Microsoft.ContainerInstance
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.Cache
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Insights
```

### Required Credentials

Before deploying, gather:

1. **WhatsApp Business API** (from Meta):
   - Phone Number ID
   - Business Account ID
   - Permanent Access Token
   - Verify Token

2. **OpenAI API**:
   - API Key
   - Organization ID (if applicable)

3. **Azure Subscription**:
   - Subscription ID
   - Resource Group location preference

---

## Quick Start - Azure Container Instances

This is the fastest way to get the solution running on Azure. Suitable for development and testing.

### Step 1: Create Resource Group

```bash
# Set variables
RESOURCE_GROUP="whatsapp-support-rg"
LOCATION="eastus"  # or westeurope, southeastasia, etc.
PROJECT_NAME="whatsapp-support"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

### Step 2: Create Azure Container Registry

```bash
ACR_NAME="${PROJECT_NAME}acr$(openssl rand -hex 3)"

# Create container registry
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)

# Login to ACR
az acr login --name $ACR_NAME
```

### Step 3: Build and Push Docker Images

```bash
# Clone repository
git clone https://github.com/yourusername/Claude2-WP-Support-agent.git
cd Claude2-WP-Support-agent

# Build n8n custom image (if needed) or use official
# For this deployment, we'll use official images and configure via environment

# Tag and push n8n image (we'll configure it with env vars)
docker pull n8nio/n8n:latest
docker tag n8nio/n8n:latest $ACR_LOGIN_SERVER/n8n:latest
docker push $ACR_LOGIN_SERVER/n8n:latest
```

### Step 4: Create Azure Database for PostgreSQL

```bash
POSTGRES_SERVER="${PROJECT_NAME}-postgres"
POSTGRES_ADMIN_USER="n8nadmin"
POSTGRES_ADMIN_PASSWORD=$(openssl rand -base64 32)
POSTGRES_DATABASE="whatsapp_support_agent"

# Create PostgreSQL Flexible Server
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --location $LOCATION \
  --admin-user $POSTGRES_ADMIN_USER \
  --admin-password $POSTGRES_ADMIN_PASSWORD \
  --sku-name Standard_B2s \
  --tier Burstable \
  --version 15 \
  --storage-size 32 \
  --public-access 0.0.0.0-255.255.255.255 \
  --yes

# Create database
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER \
  --database-name $POSTGRES_DATABASE

# Enable pgvector extension
az postgres flexible-server parameter set \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER \
  --name azure.extensions \
  --value vector

# Get connection string
POSTGRES_HOST=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --query fullyQualifiedDomainName -o tsv)

# Initialize database schema
PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql \
  -h $POSTGRES_HOST \
  -U $POSTGRES_ADMIN_USER \
  -d $POSTGRES_DATABASE \
  -f database-schema.sql

PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql \
  -h $POSTGRES_HOST \
  -U $POSTGRES_ADMIN_USER \
  -d $POSTGRES_DATABASE \
  -f database-schema-enhanced.sql
```

### Step 5: Create Azure Cache for Redis

```bash
REDIS_NAME="${PROJECT_NAME}-redis"

# Create Redis Cache
az redis create \
  --resource-group $RESOURCE_GROUP \
  --name $REDIS_NAME \
  --location $LOCATION \
  --sku Basic \
  --vm-size c0 \
  --enable-non-ssl-port false

# Get Redis connection details
REDIS_HOST=$(az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query hostName -o tsv)
REDIS_KEY=$(az redis list-keys --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query primaryKey -o tsv)
REDIS_PORT=6380  # SSL port
```

### Step 6: Create Azure Blob Storage

```bash
STORAGE_ACCOUNT="${PROJECT_NAME}storage$(openssl rand -hex 3)"

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot

# Get storage connection string
STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query connectionString -o tsv)

# Create blob containers
az storage container create \
  --name whatsapp-videos \
  --connection-string $STORAGE_CONNECTION_STRING

az storage container create \
  --name whatsapp-voice \
  --connection-string $STORAGE_CONNECTION_STRING

az storage container create \
  --name whatsapp-media \
  --connection-string $STORAGE_CONNECTION_STRING

# Get storage account key
STORAGE_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query [0].value -o tsv)
```

### Step 7: Create Azure Key Vault

```bash
KEYVAULT_NAME="${PROJECT_NAME}-kv-$(openssl rand -hex 3)"

# Create Key Vault
az keyvault create \
  --resource-group $RESOURCE_GROUP \
  --name $KEYVAULT_NAME \
  --location $LOCATION \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true

# Store secrets
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 32)
WHATSAPP_VERIFY_TOKEN=$(openssl rand -hex 32)

az keyvault secret set --vault-name $KEYVAULT_NAME --name "postgres-password" --value "$POSTGRES_ADMIN_PASSWORD"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "redis-key" --value "$REDIS_KEY"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "storage-key" --value "$STORAGE_KEY"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "n8n-encryption-key" --value "$N8N_ENCRYPTION_KEY"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "n8n-basic-auth-password" --value "$N8N_BASIC_AUTH_PASSWORD"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "whatsapp-verify-token" --value "$WHATSAPP_VERIFY_TOKEN"

# You'll manually add these through Azure Portal:
# - whatsapp-access-token
# - whatsapp-phone-number-id
# - whatsapp-business-account-id
# - openai-api-key

echo "Add the following secrets manually in Azure Portal:"
echo "- whatsapp-access-token"
echo "- whatsapp-phone-number-id"
echo "- whatsapp-business-account-id"
echo "- openai-api-key"
```

### Step 8: Deploy n8n Container Instance

```bash
# Create .env file for secrets
cat > aci-secrets.txt <<EOF
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id
WHATSAPP_ACCESS_TOKEN=your_access_token
WHATSAPP_VERIFY_TOKEN=$WHATSAPP_VERIFY_TOKEN
OPENAI_API_KEY=your_openai_key
DB_HOST=$POSTGRES_HOST
DB_USER=$POSTGRES_ADMIN_USER
DB_PASSWORD=$POSTGRES_ADMIN_PASSWORD
DB_NAME=$POSTGRES_DATABASE
REDIS_HOST=$REDIS_HOST
REDIS_PASSWORD=$REDIS_KEY
AZURE_STORAGE_ACCOUNT=$STORAGE_ACCOUNT
AZURE_STORAGE_KEY=$STORAGE_KEY
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
N8N_BASIC_AUTH_PASSWORD=$N8N_BASIC_AUTH_PASSWORD
EOF

# Deploy using ARM template (see azure/arm-templates/aci-deployment.json)
# Or use CLI:

DNS_LABEL="${PROJECT_NAME}-n8n"

az container create \
  --resource-group $RESOURCE_GROUP \
  --name whatsapp-support-n8n \
  --image $ACR_LOGIN_SERVER/n8n:latest \
  --registry-login-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --dns-name-label $DNS_LABEL \
  --ports 5678 \
  --cpu 2 \
  --memory 4 \
  --environment-variables \
    N8N_HOST=0.0.0.0 \
    N8N_PORT=5678 \
    N8N_PROTOCOL=https \
    N8N_BASIC_AUTH_ACTIVE=true \
    N8N_BASIC_AUTH_USER=admin \
    DB_TYPE=postgresdb \
    DB_POSTGRESDB_HOST=$POSTGRES_HOST \
    DB_POSTGRESDB_PORT=5432 \
    DB_POSTGRESDB_DATABASE=$POSTGRES_DATABASE \
    DB_POSTGRESDB_USER=$POSTGRES_ADMIN_USER \
    EXECUTIONS_MODE=queue \
    QUEUE_BULL_REDIS_HOST=$REDIS_HOST \
    QUEUE_BULL_REDIS_PORT=6380 \
    QUEUE_BULL_REDIS_TLS=true \
    AZURE_STORAGE_ENABLED=true \
    AZURE_STORAGE_ACCOUNT=$STORAGE_ACCOUNT \
  --secure-environment-variables \
    DB_POSTGRESDB_PASSWORD=$POSTGRES_ADMIN_PASSWORD \
    QUEUE_BULL_REDIS_PASSWORD=$REDIS_KEY \
    N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY \
    N8N_BASIC_AUTH_PASSWORD=$N8N_BASIC_AUTH_PASSWORD \
    WHATSAPP_ACCESS_TOKEN=$WHATSAPP_ACCESS_TOKEN \
    OPENAI_API_KEY=$OPENAI_API_KEY \
    AZURE_STORAGE_KEY=$STORAGE_KEY

# Get container URL
CONTAINER_FQDN=$(az container show \
  --resource-group $RESOURCE_GROUP \
  --name whatsapp-support-n8n \
  --query ipAddress.fqdn -o tsv)

echo "n8n is now accessible at: https://$CONTAINER_FQDN:5678"
echo "Username: admin"
echo "Password: $N8N_BASIC_AUTH_PASSWORD"
```

### Step 9: Configure Application Insights

```bash
# Create Application Insights
az monitor app-insights component create \
  --resource-group $RESOURCE_GROUP \
  --app whatsapp-support-insights \
  --location $LOCATION \
  --kind web \
  --application-type web

# Get instrumentation key
APPINSIGHTS_CONNECTION_STRING=$(az monitor app-insights component show \
  --resource-group $RESOURCE_GROUP \
  --app whatsapp-support-insights \
  --query connectionString -o tsv)

# Store in Key Vault
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name "appinsights-connection-string" \
  --value "$APPINSIGHTS_CONNECTION_STRING"

echo "Application Insights Connection String: $APPINSIGHTS_CONNECTION_STRING"
```

### Step 10: Import Workflows and Configure

```bash
# Access n8n web interface
echo "Open https://$CONTAINER_FQDN:5678 in your browser"
echo ""
echo "Import these workflows:"
echo "1. whatsapp-support-agent-workflow.json"
echo "2. workflows/proactive-messaging-workflow.json"
echo ""
echo "Configure WhatsApp webhook URL in Meta Dashboard:"
echo "https://$CONTAINER_FQDN:5678/webhook/whatsapp-webhook"
```

---

## Production Deployment - Azure Kubernetes Service

For production-grade deployments with auto-scaling, high availability, and advanced features.

### Architecture Overview

```
AKS Cluster
├── System Node Pool (system workloads)
├── User Node Pool (application workloads)
├── Namespaces
│   ├── whatsapp-support (main application)
│   ├── monitoring (Prometheus, Grafana)
│   └── ingress-nginx (ingress controller)
└── Services
    ├── n8n (Deployment with 3 replicas)
    ├── n8n-worker (Deployment with auto-scaling)
    ├── PostgreSQL (External - Azure Database)
    ├── Redis (External - Azure Cache)
    └── Storage (External - Azure Blob)
```

### Step 1: Create AKS Cluster

```bash
AKS_CLUSTER_NAME="${PROJECT_NAME}-aks"
AKS_NODE_COUNT=3
AKS_NODE_SIZE="Standard_D2s_v3"

# Create AKS cluster
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --location $LOCATION \
  --node-count $AKS_NODE_COUNT \
  --node-vm-size $AKS_NODE_SIZE \
  --enable-managed-identity \
  --attach-acr $ACR_NAME \
  --enable-addons monitoring \
  --network-plugin azure \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10 \
  --generate-ssh-keys

# Get AKS credentials
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME

# Verify connection
kubectl get nodes
```

### Step 2: Install NGINX Ingress Controller

```bash
# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

# Get external IP
kubectl get svc -n ingress-nginx
```

### Step 3: Install Cert-Manager for SSL

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=120s

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f azure/kubernetes/cert-issuer.yaml
```

### Step 4: Create Kubernetes Secrets

```bash
# Create namespace
kubectl create namespace whatsapp-support

# Create secrets from Key Vault
kubectl create secret generic whatsapp-secrets \
  --namespace whatsapp-support \
  --from-literal=WHATSAPP_ACCESS_TOKEN="$WHATSAPP_ACCESS_TOKEN" \
  --from-literal=WHATSAPP_PHONE_NUMBER_ID="$WHATSAPP_PHONE_NUMBER_ID" \
  --from-literal=WHATSAPP_VERIFY_TOKEN="$WHATSAPP_VERIFY_TOKEN"

kubectl create secret generic openai-secrets \
  --namespace whatsapp-support \
  --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY"

kubectl create secret generic database-secrets \
  --namespace whatsapp-support \
  --from-literal=DB_HOST="$POSTGRES_HOST" \
  --from-literal=DB_USER="$POSTGRES_ADMIN_USER" \
  --from-literal=DB_PASSWORD="$POSTGRES_ADMIN_PASSWORD" \
  --from-literal=DB_NAME="$POSTGRES_DATABASE"

kubectl create secret generic redis-secrets \
  --namespace whatsapp-support \
  --from-literal=REDIS_HOST="$REDIS_HOST" \
  --from-literal=REDIS_PASSWORD="$REDIS_KEY"

kubectl create secret generic storage-secrets \
  --namespace whatsapp-support \
  --from-literal=AZURE_STORAGE_ACCOUNT="$STORAGE_ACCOUNT" \
  --from-literal=AZURE_STORAGE_KEY="$STORAGE_KEY"

kubectl create secret generic n8n-secrets \
  --namespace whatsapp-support \
  --from-literal=N8N_ENCRYPTION_KEY="$N8N_ENCRYPTION_KEY" \
  --from-literal=N8N_BASIC_AUTH_PASSWORD="$N8N_BASIC_AUTH_PASSWORD"
```

### Step 5: Deploy Application to AKS

```bash
# Apply Kubernetes manifests
kubectl apply -f azure/kubernetes/configmap.yaml
kubectl apply -f azure/kubernetes/n8n-deployment.yaml
kubectl apply -f azure/kubernetes/n8n-service.yaml
kubectl apply -f azure/kubernetes/n8n-ingress.yaml

# Check deployment status
kubectl get pods -n whatsapp-support
kubectl get svc -n whatsapp-support
kubectl get ingress -n whatsapp-support

# View logs
kubectl logs -f deployment/whatsapp-support-n8n -n whatsapp-support
```

### Step 6: Configure Auto-scaling

```bash
# Apply Horizontal Pod Autoscaler
kubectl apply -f azure/kubernetes/hpa.yaml

# Verify HPA
kubectl get hpa -n whatsapp-support
```

### Step 7: Setup Monitoring

```bash
# Install Prometheus & Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword="$GRAFANA_PASSWORD"

# Get Grafana URL
kubectl get svc -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## Azure Database Services Setup

### PostgreSQL Configuration

```bash
# Performance tuning
az postgres flexible-server parameter set \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER \
  --name max_connections \
  --value 200

az postgres flexible-server parameter set \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER \
  --name shared_buffers \
  --value 524288  # 512MB in 8KB pages

# Enable pgvector
az postgres flexible-server parameter set \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER \
  --name shared_preload_libraries \
  --value vector

# Configure automated backups
az postgres flexible-server backup create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER

# Enable High Availability (production only)
az postgres flexible-server update \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --high-availability Enabled \
  --standby-availability-zone 2
```

### Redis Configuration

```bash
# Scale Redis (production)
az redis update \
  --resource-group $RESOURCE_GROUP \
  --name $REDIS_NAME \
  --sku Standard \
  --vm-size c1

# Enable persistence
az redis patch-schedule create \
  --resource-group $RESOURCE_GROUP \
  --name $REDIS_NAME \
  --schedule-entries '[{"dayOfWeek":"Sunday","startHourUtc":2,"maintenanceWindow":"PT5H"}]'

# Configure firewall rules
az redis firewall-rules create \
  --resource-group $RESOURCE_GROUP \
  --name $REDIS_NAME \
  --rule-name AllowAKS \
  --start-ip 10.0.0.0 \
  --end-ip 10.0.255.255
```

---

## Azure Storage Configuration

### Blob Storage Setup

```bash
# Enable soft delete
az storage blob service-properties delete-policy update \
  --account-name $STORAGE_ACCOUNT \
  --enable true \
  --days-retained 7

# Configure lifecycle management
az storage account management-policy create \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --policy @azure/scripts/storage-lifecycle-policy.json

# Enable Azure CDN (for video delivery)
az cdn profile create \
  --resource-group $RESOURCE_GROUP \
  --name ${PROJECT_NAME}-cdn \
  --sku Standard_Microsoft

az cdn endpoint create \
  --resource-group $RESOURCE_GROUP \
  --profile-name ${PROJECT_NAME}-cdn \
  --name ${PROJECT_NAME}-media \
  --origin $STORAGE_ACCOUNT.blob.core.windows.net \
  --origin-host-header $STORAGE_ACCOUNT.blob.core.windows.net
```

---

## Azure Key Vault for Secrets

### Best Practices

```bash
# Create managed identity for AKS
AKS_IDENTITY=$(az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --query identityProfile.kubeletidentity.clientId -o tsv)

# Grant Key Vault access to AKS
az keyvault set-policy \
  --name $KEYVAULT_NAME \
  --spn $AKS_IDENTITY \
  --secret-permissions get list

# Install CSI driver for Key Vault
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm install csi csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system

# Deploy SecretProviderClass
kubectl apply -f azure/kubernetes/secret-provider.yaml
```

---

## Monitoring with Azure Application Insights

### Setup Application Insights

```bash
# The Application Insights was created in Quick Start step 9
# Configure n8n to send telemetry

# Add to n8n environment:
# AZURE_APPINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONNECTION_STRING

# Create custom dashboard
az portal dashboard create \
  --resource-group $RESOURCE_GROUP \
  --name "WhatsApp Support Dashboard" \
  --input-path azure/dashboards/main-dashboard.json
```

### Key Metrics to Monitor

1. **n8n Metrics**:
   - Workflow execution count
   - Execution success/failure rate
   - Average execution time
   - Queue depth

2. **Database Metrics**:
   - Connection pool usage
   - Query duration
   - CPU and memory usage
   - Storage usage

3. **Redis Metrics**:
   - Hit/miss ratio
   - Memory usage
   - Connected clients
   - Commands per second

4. **Application Metrics**:
   - HTTP request rate
   - Response time
   - Error rate
   - Active users

---

## CI/CD with GitHub Actions

See the complete GitHub Actions workflow in `azure/github-actions/azure-deployment.yml`.

### Setup GitHub Secrets

```bash
# Create service principal
SP_JSON=$(az ad sp create-for-rbac \
  --name "whatsapp-support-github" \
  --role contributor \
  --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth)

echo "Add this to GitHub Secrets as AZURE_CREDENTIALS:"
echo $SP_JSON

# Additional secrets to add to GitHub:
# - ACR_LOGIN_SERVER
# - ACR_USERNAME
# - ACR_PASSWORD
# - AKS_CLUSTER_NAME
# - RESOURCE_GROUP
```

---

## Cost Optimization

### Estimated Monthly Costs

#### Development/Testing (ACI)
| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| Container Instances | 2 vCPU, 4GB RAM | $35 |
| PostgreSQL Flexible | Burstable B2s | $25 |
| Redis Cache | Basic C0 | $16 |
| Blob Storage | 100GB | $2 |
| Application Insights | Basic | $5 |
| **Total** | | **~$83** |

#### Production (AKS)
| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| AKS | 3 x Standard_D2s_v3 | $210 |
| PostgreSQL Flexible | General Purpose D4s | $180 |
| Redis Cache | Standard C1 | $75 |
| Blob Storage | 500GB + CDN | $12 |
| Application Insights | Standard | $15 |
| Key Vault | Standard | $3 |
| Load Balancer | Standard | $22 |
| **Total** | | **~$517** |

### Cost Saving Tips

1. **Use Azure Reserved Instances**: Save 30-50% on compute
2. **Auto-shutdown**: Stop ACI containers during off-hours
3. **Blob Storage Lifecycle**: Move old data to cool/archive tiers
4. **Right-size Resources**: Start small and scale based on actual usage
5. **Use Azure Hybrid Benefit**: If you have Windows licenses
6. **Enable Azure Advisor**: Get personalized cost recommendations

```bash
# Enable Azure Cost Management alerts
az consumption budget create \
  --resource-group $RESOURCE_GROUP \
  --budget-name whatsapp-support-budget \
  --amount 500 \
  --time-grain Monthly \
  --start-date $(date -u +%Y-%m-01T00:00:00Z) \
  --end-date $(date -u -d "+1 year" +%Y-%m-01T00:00:00Z)
```

---

## Security Best Practices

### Network Security

```bash
# Create Network Security Group
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name ${PROJECT_NAME}-nsg

# Allow only HTTPS inbound
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name ${PROJECT_NAME}-nsg \
  --name AllowHTTPS \
  --priority 100 \
  --source-address-prefixes '*' \
  --destination-port-ranges 443 \
  --access Allow \
  --protocol Tcp
```

### Enable Azure Security Center

```bash
# Enable Security Center Standard tier
az security pricing create \
  --name VirtualMachines \
  --tier standard

# Enable for databases
az security pricing create \
  --name SqlServers \
  --tier standard

# Enable for storage
az security pricing create \
  --name StorageAccounts \
  --tier standard
```

### Implement Azure Private Link

```bash
# For PostgreSQL
az postgres flexible-server update \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --public-access Disabled

# Create private endpoint
az network private-endpoint create \
  --resource-group $RESOURCE_GROUP \
  --name postgres-private-endpoint \
  --vnet-name $AZURE_VNET_NAME \
  --subnet default \
  --private-connection-resource-id $(az postgres flexible-server show --resource-group $RESOURCE_GROUP --name $POSTGRES_SERVER --query id -o tsv) \
  --group-id postgresqlServer \
  --connection-name postgres-connection
```

---

## Troubleshooting

### Common Issues

#### 1. Container Won't Start

```bash
# Check container logs
az container logs \
  --resource-group $RESOURCE_GROUP \
  --name whatsapp-support-n8n

# Check events
az container show \
  --resource-group $RESOURCE_GROUP \
  --name whatsapp-support-n8n \
  --query instanceView.events
```

#### 2. Database Connection Issues

```bash
# Test connection
PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql \
  -h $POSTGRES_HOST \
  -U $POSTGRES_ADMIN_USER \
  -d $POSTGRES_DATABASE \
  -c "SELECT version();"

# Check firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER
```

#### 3. Redis Connection Issues

```bash
# Test Redis connection
redis-cli -h $REDIS_HOST -p 6380 --tls -a $REDIS_KEY ping

# Check Redis status
az redis show \
  --resource-group $RESOURCE_GROUP \
  --name $REDIS_NAME \
  --query provisioningState
```

#### 4. Storage Access Issues

```bash
# Test storage connectivity
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name whatsapp-videos

# Check container permissions
az storage container show-permission \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --name whatsapp-videos
```

---

## Scaling Strategies

### Vertical Scaling

```bash
# Scale PostgreSQL
az postgres flexible-server update \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --sku-name Standard_D4s_v3

# Scale Redis
az redis update \
  --resource-group $RESOURCE_GROUP \
  --name $REDIS_NAME \
  --sku Premium \
  --vm-size P1
```

### Horizontal Scaling (AKS)

```bash
# Scale number of pods
kubectl scale deployment whatsapp-support-n8n \
  --replicas=5 \
  --namespace whatsapp-support

# Scale AKS nodes
az aks scale \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --node-count 5
```

### Multi-Region Deployment

For global deployments:

1. **Deploy to multiple Azure regions**
2. **Use Azure Traffic Manager** for global load balancing
3. **Replicate data** using PostgreSQL read replicas
4. **Use Azure Front Door** for CDN and failover

```bash
# Create Traffic Manager profile
az network traffic-manager profile create \
  --resource-group $RESOURCE_GROUP \
  --name whatsapp-support-tm \
  --routing-method Performance \
  --unique-dns-name whatsapp-support-global
```

---

## Next Steps

After deployment:

1. ✅ **Import n8n workflows** from the repository
2. ✅ **Configure WhatsApp webhook** in Meta Dashboard
3. ✅ **Test the complete flow** with a WhatsApp message
4. ✅ **Setup monitoring alerts** in Application Insights
5. ✅ **Configure backup retention** policies
6. ✅ **Enable auto-scaling** based on metrics
7. ✅ **Setup CI/CD pipeline** with GitHub Actions
8. ✅ **Implement disaster recovery** plan
9. ✅ **Configure cost budgets** and alerts
10. ✅ **Security audit** with Azure Security Center

---

## Additional Resources

### Azure Documentation
- [Azure Container Instances](https://learn.microsoft.com/en-us/azure/container-instances/)
- [Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/)
- [Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/)
- [Azure Cache for Redis](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/)
- [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/)

### Deployment Artifacts
- ARM Templates: `azure/arm-templates/`
- Bicep Files: `azure/bicep/`
- Terraform: `azure/terraform/`
- Kubernetes Manifests: `azure/kubernetes/`
- Scripts: `azure/scripts/`
- GitHub Actions: `azure/github-actions/`

---

**Congratulations!** You now have a production-ready WhatsApp AI Support Agent running on Azure! 🎉🚀

For support, refer to:
- DEPLOYMENT-V2.md(DEPLOYMENT-V2.md) - General deployment guide
- [DOCKER-DEPLOYMENT.md](DOCKER-DEPLOYMENT.md) - Docker deployment
- FEATURES.md(FEATURES.md) - v2.0 features documentation
- [TROUBLESHOOTING.md](azure/TROUBLESHOOTING.md) - Azure-specific troubleshooting
