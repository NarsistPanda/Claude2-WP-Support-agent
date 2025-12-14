# Complete Deployment Guide - WhatsApp AI Support Agent v2.0

**Comprehensive step-by-step guide to deploy all components including enhanced features**

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture Components](#architecture-components)
4. [Phase 1: Infrastructure Setup](#phase-1-infrastructure-setup)
5. [Phase 2: WhatsApp Business API](#phase-2-whatsapp-business-api)
6. [Phase 3: Database Setup](#phase-3-database-setup)
7. [Phase 4: Vector Database (Optional)](#phase-4-vector-database-optional)
8. [Phase 5: n8n Installation](#phase-5-n8n-installation)
9. [Phase 6: Workflow Deployment](#phase-6-workflow-deployment)
10. [Phase 7: Enhanced Features Setup](#phase-7-enhanced-features-setup)
11. [Phase 8: Testing](#phase-8-testing)
12. [Phase 9: Production Deployment](#phase-9-production-deployment)
13. [Phase 10: Monitoring & Maintenance](#phase-10-monitoring--maintenance)
14. [Troubleshooting](#troubleshooting)

---

## Overview

This guide covers deploying the complete WhatsApp AI Support Agent with all v2.0 enhanced features:

- ✅ Core AI chatbot with multimodal support
- ✅ Human handoff system
- ✅ Proactive messaging & campaigns
- ✅ Voice responses (TTS)
- ✅ Video message processing
- ✅ RAG with vector database
- ✅ Complete analytics & monitoring

**Total Deployment Time**: 2-4 hours

---

## Prerequisites

### Required Accounts

- [ ] **Meta Business Account** - [Create here](https://business.facebook.com/)
- [ ] **Meta Developer Account** - [Sign up here](https://developers.facebook.com/)
- [ ] **OpenAI Account** - [Get API key](https://platform.openai.com/api-keys)
- [ ] **Domain Name** - For production deployment
- [ ] **SSL Certificate** - Let's Encrypt (free) or purchased

### Required Infrastructure

- [ ] **Server/VPS** - Minimum specs:
  - 4 GB RAM
  - 2 CPU cores
  - 40 GB SSD storage
  - Ubuntu 22.04 LTS (recommended)
  - Public IP address

- [ ] **Software Installed**:
  - Docker 24.0+ ([Install](https://docs.docker.com/engine/install/))
  - Docker Compose 2.0+ ([Install](https://docs.docker.com/compose/install/))
  - Git ([Install](https://git-scm.com/downloads))
  - curl, wget, openssl

### Optional (for Enhanced Features)

- [ ] **Slack Workspace** - For human handoff notifications
- [ ] **AWS Account** - For video storage (S3)
- [ ] **SMTP Server** - For email notifications (Gmail, SendGrid, etc.)

### Verify Prerequisites

```bash
# Check Docker
docker --version
# Should show: Docker version 24.0.0 or higher

# Check Docker Compose
docker-compose --version
# Should show: Docker Compose version 2.0.0 or higher

# Check Git
git --version

# Check system resources
free -h  # Check RAM
df -h    # Check disk space
nproc    # Check CPU cores
```

---

## Architecture Components

Understanding what you're deploying:

```
┌─────────────────────────────────────────────────────────────┐
│                     Infrastructure Layer                     │
├─────────────────────────────────────────────────────────────┤
│  Docker Compose Stack:                                      │
│  - n8n (Workflow Engine)                                    │
│  - PostgreSQL (Primary Database)                            │
│  - Redis (Cache & Queue)                                    │
│  - Qdrant (Vector Database - Optional)                      │
│  - Nginx (Reverse Proxy)                                    │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
├─────────────────────────────────────────────────────────────┤
│  n8n Workflows:                                             │
│  1. Main WhatsApp Support Agent Workflow                    │
│  2. Proactive Messaging Workflow                            │
│  3. Human Handoff Workflow (if enabled)                     │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Integration Layer                          │
├─────────────────────────────────────────────────────────────┤
│  - WhatsApp Business API (Meta)                             │
│  - OpenAI API (GPT-4, Whisper, TTS, Vision)                 │
│  - Slack API (Optional - for handoffs)                      │
│  - Email/SMTP (Optional - for notifications)                │
│  - AWS S3 (Optional - for video storage)                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Infrastructure Setup

### Step 1.1: Prepare Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git openssl ufw

# Configure firewall
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

### Step 1.2: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again, then verify
docker run hello-world
```

### Step 1.3: Install Docker Compose

```bash
# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Step 1.4: Clone Repository

```bash
# Clone the repository
git clone https://github.com/yourusername/whatsapp-n8n-agent.git
cd whatsapp-n8n-agent

# Check files
ls -la
# Should see: docker-compose.yml, .env.example, database-schema.sql, etc.
```

### Step 1.5: Configure Domain (Production)

```bash
# Point your domain to server IP
# In your domain registrar's DNS settings:
# A Record: your-domain.com → YOUR_SERVER_IP
# A Record: www.your-domain.com → YOUR_SERVER_IP

# Verify DNS propagation
ping your-domain.com
```

---

## Phase 2: WhatsApp Business API

### Step 2.1: Create Meta App

1. Go to [Meta for Developers](https://developers.facebook.com/apps)
2. Click **"Create App"**
3. Choose **"Business"** as app type
4. Fill in:
   - **App Name**: "WhatsApp Support Agent"
   - **Contact Email**: your@email.com
5. Click **"Create App"**

### Step 2.2: Add WhatsApp Product

1. In app dashboard, find **"WhatsApp"** product
2. Click **"Set up"**
3. Select or create **Business Portfolio**
4. You'll be taken to WhatsApp setup page

### Step 2.3: Get Credentials

On the **WhatsApp > Getting Started** page:

```
📋 Copy these values:

1. Phone Number ID: ________________
2. WhatsApp Business Account ID: ________________
3. Temporary Access Token: ________________
```

### Step 2.4: Generate Permanent Token

1. Go to **WhatsApp > Configuration**
2. Scroll to **"Access Tokens"**
3. Click **"Generate Token"**
4. Select permissions:
   - ✅ `whatsapp_business_management`
   - ✅ `whatsapp_business_messaging`
5. Click **"Generate"**
6. **Copy and save the token** (you won't see it again!)

```
📋 Permanent Access Token: ________________
```

### Step 2.5: Add Test Phone Number

For initial testing:

1. In **WhatsApp > API Setup**
2. Find **"To"** section under "Send and receive messages"
3. Click **"Manage phone number list"**
4. Add your phone number (include country code)
5. Verify with the code sent to WhatsApp

---

## Phase 3: Database Setup

### Step 3.1: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Generate encryption key
export N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
echo "N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY" >> .env

# Generate verify token
export WHATSAPP_VERIFY_TOKEN=$(openssl rand -hex 16)
echo "WHATSAPP_VERIFY_TOKEN=$WHATSAPP_VERIFY_TOKEN" >> .env

# Edit .env file
nano .env
```

### Step 3.2: Fill in Required Variables

Edit `.env` with your values:

```bash
# ===== REQUIRED - WhatsApp =====
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id
WHATSAPP_BUSINESS_ACCOUNT_ID=your_business_account_id
WHATSAPP_ACCESS_TOKEN=your_permanent_access_token
WHATSAPP_VERIFY_TOKEN=your_generated_verify_token

# ===== REQUIRED - OpenAI =====
OPENAI_API_KEY=sk-your_openai_api_key_here
OPENAI_MODEL=gpt-4o-mini
OPENAI_TEMPERATURE=0.7
OPENAI_MAX_TOKENS=500

# ===== REQUIRED - Database =====
DB_NAME=whatsapp_support_agent
DB_USER=n8n_user
DB_PASSWORD=$(openssl rand -base64 32)  # Generate strong password

# ===== REQUIRED - n8n =====
N8N_HOST=your-domain.com  # or IP address
N8N_WEBHOOK_URL=https://your-domain.com
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 16)  # Generate strong password

# Already set above:
# N8N_ENCRYPTION_KEY=...
# WHATSAPP_VERIFY_TOKEN=...
```

Save and close (Ctrl+X, Y, Enter).

### Step 3.3: Start Database Container

```bash
# Start only PostgreSQL first
docker-compose up -d postgres

# Wait for it to be ready (15-30 seconds)
sleep 30

# Verify it's running
docker-compose ps postgres
# Should show "Up"

# Check logs
docker-compose logs postgres
# Should see "database system is ready to accept connections"
```

### Step 3.4: Initialize Base Database Schema

```bash
# Copy schema file into container
docker cp database-schema.sql postgres:/tmp/

# Execute base schema
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent -f /tmp/database-schema.sql

# Verify tables created
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent -c "\dt"

# Should see tables:
# - users
# - user_conversations
# - messages
# - ai_interactions
# - knowledge_base
# - analytics
# - feedback
# - error_logs
```

### Step 3.5: Apply Enhanced Features Schema

```bash
# Copy enhanced schema
docker cp database-schema-enhanced.sql postgres:/tmp/

# Execute enhanced schema
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent -f /tmp/database-schema-enhanced.sql

# Verify new tables
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent -c "\dt"

# Should now also see:
# - handoff_requests
# - agent_availability
# - active_handoffs
# - scheduled_messages
# - message_templates
# - message_campaigns
# - user_voice_preferences
# - voice_responses
# - video_processing
```

### Step 3.6: Verify Database Setup

```bash
# Connect to database
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent

# List all tables
\dt

# Check sample data
SELECT * FROM knowledge_base;
SELECT * FROM message_templates;
SELECT * FROM agent_availability;

# Exit
\q
```

You should see:
- ✅ 5 knowledge base entries
- ✅ 4 message templates
- ✅ 3 sample agents

---

## Phase 4: Vector Database (Optional)

For RAG (Retrieval Augmented Generation) support, set up Qdrant.

### Step 4.1: Enable Qdrant in Docker Compose

```bash
# Start Qdrant
docker-compose --profile rag up -d qdrant

# Verify it's running
docker-compose ps qdrant
curl http://localhost:6333/collections
```

### Step 4.2: Create Collection

```bash
# Create collection for knowledge base
curl -X PUT http://localhost:6333/collections/whatsapp-knowledge \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 1536,
      "distance": "Cosine"
    }
  }'

# Verify collection
curl http://localhost:6333/collections/whatsapp-knowledge
```

### Step 4.3: Update Environment

```bash
# Add to .env
echo "QDRANT_URL=http://qdrant:6333" >> .env
echo "QDRANT_COLLECTION=whatsapp-knowledge" >> .env
echo "ENABLE_RAG=true" >> .env
```

---

## Phase 5: n8n Installation

### Step 5.1: Start All Core Services

```bash
# Start n8n, PostgreSQL, Redis
docker-compose up -d n8n postgres redis

# Check all services are running
docker-compose ps

# Should show:
# n8n       Up
# postgres  Up
# redis     Up
```

### Step 5.2: Access n8n

```bash
# For local/testing access:
http://YOUR_SERVER_IP:5678

# For production with domain:
https://your-domain.com
```

### Step 5.3: Initial n8n Setup

1. Open n8n in browser
2. Create owner account:
   - **Email**: your@email.com
   - **First Name**: Your Name
   - **Last Name**: Your Name
   - **Password**: (choose strong password)
3. Click **"Continue"**
4. You'll see the n8n dashboard

### Step 5.4: Configure n8n Credentials

We need to add 3 credentials:

#### A. WhatsApp Business Cloud Credential

1. In n8n, click **"Credentials"** in left menu
2. Click **"Add Credential"**
3. Search for **"WhatsApp Business Cloud"**
4. Fill in:
   - **Name**: WhatsApp Business Cloud
   - **Access Token**: [Your permanent token from Phase 2]
   - **Phone Number ID**: [From Phase 2]
5. Click **"Save"**

#### B. OpenAI Credential

1. Click **"Add Credential"**
2. Search for **"OpenAI"**
3. Fill in:
   - **Name**: OpenAI
   - **API Key**: [Your OpenAI key]
4. Click **"Save"**

#### C. PostgreSQL Credential

1. Click **"Add Credential"**
2. Search for **"Postgres"**
3. Fill in:
   - **Name**: PostgreSQL
   - **Host**: `postgres`
   - **Database**: `whatsapp_support_agent`
   - **User**: `n8n_user`
   - **Password**: [From your .env file]
   - **Port**: `5432`
   - **SSL**: Disable
4. Click **"Test"** - should show success
5. Click **"Save"**

---

## Phase 6: Workflow Deployment

### Step 6.1: Import Main Workflow

1. In n8n, click **"Workflows"** in left menu
2. Click **"Add workflow"** (+ icon)
3. Click menu (⋮) → **"Import from File"**
4. Select: `whatsapp-support-agent-workflow.json`
5. Click **"Import"**

The workflow will load with all nodes!

### Step 6.2: Update Workflow Credentials

The workflow will show credential errors. Fix them:

1. Click any **WhatsApp** node (orange icon)
2. In node panel, click **"Select Credential"**
3. Choose **"WhatsApp Business Cloud"** (created earlier)
4. Repeat for all WhatsApp nodes

5. Click any **OpenAI** node (purple icon)
6. Select **"OpenAI"** credential
7. Repeat for all OpenAI nodes

8. Click any **PostgreSQL** node (elephant icon)
9. Select **"PostgreSQL"** credential
10. Repeat for all PostgreSQL nodes

### Step 6.3: Activate Main Workflow

1. Click **"Save"** button (top right)
2. Toggle **"Inactive"** to **"Active"** (top right)
3. Workflow is now live! ✅

### Step 6.4: Get Webhook URL

1. Click the **"Webhook Messages"** node
2. Copy the **Production URL**:
   ```
   https://your-domain.com/webhook/whatsapp-webhook
   ```
3. Save this - you'll need it for Meta configuration

### Step 6.5: Import Proactive Messaging Workflow

1. Click **"Workflows"** in left menu
2. Click **"Add workflow"**
3. Click menu → **"Import from File"**
4. Select: `workflows/proactive-messaging-workflow.json`
5. Click **"Import"**
6. Update all credentials (WhatsApp, PostgreSQL)
7. Click **"Save"**
8. Toggle to **"Active"**

This workflow runs every 5 minutes to send scheduled messages.

---

## Phase 7: Enhanced Features Setup

### 7.1: Human Handoff Setup

#### Option A: Slack Integration

**Step 1: Create Slack App**

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **"Create New App"** → **"From scratch"**
3. Name: "WhatsApp Support Agent"
4. Choose your workspace
5. Click **"Create App"**

**Step 2: Enable Incoming Webhooks**

1. In app settings, click **"Incoming Webhooks"**
2. Toggle **"Activate Incoming Webhooks"** to ON
3. Click **"Add New Webhook to Workspace"**
4. Select channel: **#customer-support** (create if needed)
5. Click **"Allow"**
6. Copy the webhook URL

**Step 3: Configure in Environment**

```bash
# Edit .env
nano .env

# Add Slack configuration
ENABLE_HUMAN_HANDOFF=true
SLACK_ENABLED=true
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_HANDOFF_CHANNEL=#customer-support
```

**Step 4: Add Agents to Database**

```bash
# Connect to database
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent

# Add your support agents
INSERT INTO agent_availability (agent_id, agent_name, agent_email, status, skills) VALUES
    ('john_smith', 'John Smith', 'john@company.com', 'online', ARRAY['technical', 'billing']),
    ('sarah_jones', 'Sarah Jones', 'sarah@company.com', 'online', ARRAY['sales', 'general']);

# Verify
SELECT * FROM agent_availability;

# Exit
\q
```

#### Option B: Email Integration

```bash
# Edit .env
nano .env

# Add email configuration
ENABLE_HUMAN_HANDOFF=true
EMAIL_HANDOFF_ENABLED=true
HANDOFF_EMAIL_TO=support@company.com
HANDOFF_EMAIL_FROM=whatsapp-bot@company.com

# Gmail example
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password  # Generate at myaccount.google.com/apppasswords
SMTP_SECURE=true
```

#### Option C: Custom Webhook

```bash
# For CRM integration
ENABLE_HUMAN_HANDOFF=true
CUSTOM_WEBHOOK_ENABLED=true
HANDOFF_WEBHOOK_URL=https://your-crm.com/api/handoff
HANDOFF_WEBHOOK_AUTH=Bearer your-api-key
HANDOFF_WEBHOOK_METHOD=POST
```

### 7.2: Proactive Messaging Setup

Already active! The workflow is checking every 5 minutes.

**Test scheduling a message:**

```bash
# Connect to database
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent

# Schedule a test message (change phone number!)
SELECT schedule_message(
    '1234567890',  -- Your phone number
    'This is a test scheduled message from WhatsApp Support Agent!',
    NOW() + INTERVAL '2 minutes',  -- Send in 2 minutes
    'notification'
);

# Check scheduled messages
SELECT * FROM scheduled_messages WHERE status = 'scheduled';

# Exit
\q
```

Wait 2-5 minutes and check your WhatsApp!

### 7.3: Voice Responses Setup

```bash
# Edit .env
nano .env

# Add voice configuration
ENABLE_VOICE_RESPONSES=true
VOICE_RESPONSE_AUTO=false  # Users must opt-in
OPENAI_TTS_VOICE=alloy  # Options: alloy, echo, fable, onyx, nova, shimmer
OPENAI_TTS_SPEED=1.0
VOICE_RESPONSE_MAX_LENGTH=500
```

**Enable voice for a test user:**

```sql
-- Connect to database
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent

-- Enable voice for your number
INSERT INTO user_voice_preferences (phone_number, voice_enabled, voice_name)
VALUES ('1234567890', true, 'alloy')
ON CONFLICT (phone_number) DO UPDATE SET voice_enabled = true;

-- Check
SELECT * FROM user_voice_preferences;

\q
```

### 7.4: Video Support Setup

#### Option A: AWS S3 Storage

**Step 1: Create S3 Bucket**

1. Go to [AWS S3 Console](https://s3.console.aws.amazon.com/)
2. Click **"Create bucket"**
3. Bucket name: `whatsapp-videos-your-company`
4. Region: Choose closest to your server
5. Block all public access: **Enabled**
6. Click **"Create bucket"**

**Step 2: Create IAM User**

1. Go to [IAM Console](https://console.aws.amazon.com/iam/)
2. Users → **"Add users"**
3. User name: `whatsapp-agent-s3`
4. Access type: **Access key - Programmatic access**
5. Click **"Next: Permissions"**
6. Attach policies: `AmazonS3FullAccess` (or create custom policy)
7. Click through to **"Create user"**
8. **Save Access Key ID and Secret Access Key**

**Step 3: Configure Environment**

```bash
# Edit .env
nano .env

# Add AWS configuration
ENABLE_VIDEO_SUPPORT=true
VIDEO_MAX_SIZE_MB=16
VIDEO_PROCESSING_TIMEOUT=60
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
AWS_S3_BUCKET=whatsapp-videos-your-company
AWS_REGION=us-east-1
```

#### Option B: Google Cloud Storage

```bash
# Create GCS bucket and service account
# Download service account JSON key

# Configure in .env
ENABLE_VIDEO_SUPPORT=true
GCS_ENABLED=true
GCS_PROJECT_ID=your-project-id
GCS_BUCKET=whatsapp-videos
GCS_KEY_FILE=/path/to/service-account.json
```

### 7.5: Restart Services

After configuring all features:

```bash
# Restart to apply new environment variables
docker-compose down
docker-compose up -d

# Verify all services are running
docker-compose ps

# Check n8n logs
docker-compose logs -f n8n
```

---

## Phase 8: Testing

### Step 8.1: Configure WhatsApp Webhook

Now we connect Meta to your n8n instance.

1. Go to [Meta Developer Dashboard](https://developers.facebook.com/apps)
2. Select your app → **WhatsApp** → **Configuration**
3. Find **"Webhook"** section
4. Click **"Edit"**

5. Fill in:
   - **Callback URL**: `https://your-domain.com/webhook/whatsapp-webhook`
   - **Verify Token**: [Your WHATSAPP_VERIFY_TOKEN from .env]

6. Click **"Verify and Save"**

If successful, you'll see ✅ **Verified**

7. Click **"Manage"** button
8. Subscribe to fields:
   - ✅ **messages**
9. Click **"Save"**

### Step 8.2: Test Basic Message

**Send from Meta Dashboard:**

1. In Meta Dashboard → **WhatsApp** → **API Setup**
2. Find **"Send and receive messages"** section
3. Select your test phone number
4. Click **"Send message"**

**Check n8n:**

1. Go to n8n → **Executions** tab
2. You should see a new execution
3. Click it to see the flow
4. All nodes should be green ✅

**Send from Your Phone:**

1. Open WhatsApp on your phone
2. Send message to the test number: `Hello!`
3. Wait 2-3 seconds
4. You should receive an AI reply! 🎉

### Step 8.3: Test Multimodal Support

**Test Voice Message:**

1. Send a voice message: "What is n8n?"
2. Should receive a text response based on transcription

**Test Image:**

1. Send an image with caption: "What do you see?"
2. Should receive a description of the image

**Test Document:**

1. Send a PDF file
2. Should acknowledge receipt

**Test Video (if enabled):**

1. Send a short video (under 16MB)
2. Should acknowledge and analyze

### Step 8.4: Test Human Handoff

**Trigger handoff:**

1. Send message: "I want to speak to a human"
2. Check your Slack channel or email
3. You should receive a handoff notification

**Verify in database:**

```bash
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent

SELECT * FROM handoff_requests ORDER BY created_at DESC LIMIT 5;

\q
```

### Step 8.5: Test Proactive Messaging

We already tested this in Phase 7.2. Check if message was sent!

```bash
# Check message status
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent

SELECT id, phone_number, message_content, status, sent_at
FROM scheduled_messages
ORDER BY created_at DESC
LIMIT 5;

\q
```

### Step 8.6: Test Voice Response (if enabled)

**Enable voice for your number and send a long question:**

1. Send: "Can you explain how n8n workflows work?"
2. If enabled, should receive audio response

**Check logs:**

```sql
SELECT * FROM voice_responses ORDER BY created_at DESC LIMIT 3;
```

### Step 8.7: Check Analytics

```sql
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent

-- Daily stats
SELECT * FROM message_stats ORDER BY date DESC LIMIT 7;

-- AI performance
SELECT * FROM ai_performance_stats ORDER BY date DESC LIMIT 7;

-- Active users
SELECT * FROM active_users_stats;

\q
```

---

## Phase 9: Production Deployment

### Step 9.1: SSL Certificate Setup

**Using Let's Encrypt (Free):**

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Stop nginx if running
docker-compose down nginx

# Get certificate
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Certificates will be at:
# /etc/letsencrypt/live/your-domain.com/fullchain.pem
# /etc/letsencrypt/live/your-domain.com/privkey.pem
```

### Step 9.2: Configure Nginx

```bash
# Edit nginx configuration
nano nginx/nginx.conf

# Update server_name
server_name your-domain.com;  # Line 67

# Update SSL paths
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
```

### Step 9.3: Update Docker Compose for Production

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Uncomment nginx and certbot services (remove 'profiles: production')
# Save and close
```

### Step 9.4: Start Production Stack

```bash
# Start with nginx
docker-compose --profile production up -d

# Or if you removed profiles:
docker-compose up -d

# Verify all services
docker-compose ps

# Should show all services as "Up":
# - n8n
# - postgres
# - redis
# - nginx
# - qdrant (if enabled)
```

### Step 9.5: Configure Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Set up auto-renewal cron
sudo crontab -e

# Add this line:
0 0 1 * * certbot renew --quiet && docker-compose restart nginx
```

### Step 9.6: Security Hardening

```bash
# Change default passwords
nano .env
# Update:
# - N8N_BASIC_AUTH_PASSWORD
# - DB_PASSWORD

# Restart services
docker-compose down
docker-compose up -d

# Disable root SSH login
sudo nano /etc/ssh/sshd_config
# Change: PermitRootLogin no
sudo systemctl restart sshd

# Set up fail2ban
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Step 9.7: Update WhatsApp Webhook to HTTPS

1. Go to Meta Developer Dashboard
2. WhatsApp → Configuration → Webhook
3. Edit Callback URL to: `https://your-domain.com/webhook/whatsapp-webhook`
4. Verify and save

### Step 9.8: Verify Production Setup

```bash
# Test HTTPS
curl https://your-domain.com/healthz

# Test webhook
curl -X POST https://your-domain.com/webhook/whatsapp-webhook \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Send test WhatsApp message
# Should work!
```

---

## Phase 10: Monitoring & Maintenance

### Step 10.1: Set Up Automated Backups

```bash
# Create backup script
sudo mkdir -p /opt/backups
sudo nano /opt/backups/backup-whatsapp-agent.sh
```

Add this content:

```bash
#!/bin/bash
BACKUP_DIR="/opt/backups/whatsapp-agent"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
docker exec postgres pg_dump -U n8n_user whatsapp_support_agent | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Backup n8n data
docker exec n8n tar czf - /home/node/.n8n > $BACKUP_DIR/n8n_data_$DATE.tar.gz

# Keep only last 7 days
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup completed: $DATE"

# Optional: Upload to S3
# aws s3 sync $BACKUP_DIR s3://your-backup-bucket/whatsapp-agent/
```

Make executable and schedule:

```bash
sudo chmod +x /opt/backups/backup-whatsapp-agent.sh

# Add to cron
sudo crontab -e

# Add daily backup at 2 AM
0 2 * * * /opt/backups/backup-whatsapp-agent.sh >> /var/log/backup.log 2>&1
```

### Step 10.2: Set Up Monitoring

**Install monitoring tools:**

```bash
# Install htop for resource monitoring
sudo apt install -y htop

# Monitor docker containers
docker stats

# Monitor n8n
docker-compose logs -f n8n

# Monitor specific service
docker-compose logs -f postgres
```

**Create monitoring dashboard:**

```bash
# Install Grafana (optional)
docker run -d -p 3000:3000 --name=grafana grafana/grafana

# Access at http://YOUR_IP:3000
# Default: admin/admin
```

### Step 10.3: Database Maintenance

Create maintenance script:

```bash
sudo nano /opt/backups/db-maintenance.sh
```

```bash
#!/bin/bash

# Cleanup old conversations (90+ days)
docker-compose exec -T postgres psql -U n8n_user -d whatsapp_support_agent <<EOF
SELECT cleanup_old_conversations(90);
DELETE FROM error_logs WHERE created_at < NOW() - INTERVAL '30 days';
DELETE FROM video_processing WHERE created_at < NOW() - INTERVAL '30 days' AND processing_status = 'completed';
VACUUM ANALYZE;
EOF

echo "Database maintenance completed: $(date)"
```

Schedule weekly:

```bash
sudo chmod +x /opt/backups/db-maintenance.sh
sudo crontab -e

# Add weekly maintenance on Sunday at 3 AM
0 3 * * 0 /opt/backups/db-maintenance.sh >> /var/log/db-maintenance.log 2>&1
```

### Step 10.4: Log Management

```bash
# Set up log rotation
sudo nano /etc/logrotate.d/docker-containers

# Add:
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=100M
    missingok
    delaycompress
    copytruncate
}

# Test
sudo logrotate -f /etc/logrotate.d/docker-containers
```

### Step 10.5: Health Checks

Create health check script:

```bash
sudo nano /usr/local/bin/check-whatsapp-agent.sh
```

```bash
#!/bin/bash

# Check n8n
if ! curl -f http://localhost:5678/healthz > /dev/null 2>&1; then
    echo "n8n is down! Restarting..."
    docker-compose restart n8n
fi

# Check PostgreSQL
if ! docker-compose exec -T postgres pg_isready -U n8n_user > /dev/null 2>&1; then
    echo "PostgreSQL is down! Restarting..."
    docker-compose restart postgres
fi

# Check Redis
if ! docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "Redis is down! Restarting..."
    docker-compose restart redis
fi

echo "Health check completed: $(date)"
```

Schedule every 5 minutes:

```bash
sudo chmod +x /usr/local/bin/check-whatsapp-agent.sh
crontab -e

# Add:
*/5 * * * * /usr/local/bin/check-whatsapp-agent.sh >> /var/log/health-check.log 2>&1
```

### Step 10.6: Cost Monitoring

```bash
# Create cost monitoring script
nano /opt/backups/check-costs.sh
```

```bash
#!/bin/bash

docker-compose exec -T postgres psql -U n8n_user -d whatsapp_support_agent <<EOF
-- Monthly AI costs
SELECT
    'AI Cost' as category,
    SUM(tokens_used) * 0.00000015 as cost_usd
FROM ai_interactions
WHERE created_at > NOW() - INTERVAL '30 days'
UNION ALL
SELECT
    'Voice Cost' as category,
    SUM(cost_usd) as cost_usd
FROM voice_responses
WHERE created_at > NOW() - INTERVAL '30 days';

-- Total
SELECT
    'Total Monthly Cost' as category,
    (SELECT SUM(tokens_used) * 0.00000015 FROM ai_interactions WHERE created_at > NOW() - INTERVAL '30 days') +
    (SELECT COALESCE(SUM(cost_usd), 0) FROM voice_responses WHERE created_at > NOW() - INTERVAL '30 days')
    as cost_usd;
EOF
```

Run weekly:

```bash
chmod +x /opt/backups/check-costs.sh
crontab -e

# Every Monday at 9 AM
0 9 * * 1 /opt/backups/check-costs.sh | mail -s "WhatsApp Agent Weekly Cost Report" admin@company.com
```

---

## Troubleshooting

### Issue 1: Webhook Not Receiving Messages

**Symptoms:** Messages sent to WhatsApp don't trigger workflow

**Diagnosis:**

```bash
# Check if n8n is accessible
curl https://your-domain.com/healthz

# Check workflow is active
# In n8n UI: Check workflow status is "Active"

# Check webhook in Meta
# Meta Dashboard → WhatsApp → Configuration → Webhook
# Should show "Verified"

# Check n8n logs
docker-compose logs -f n8n | grep webhook
```

**Solutions:**

1. Verify webhook URL is correct and accessible
2. Check WHATSAPP_VERIFY_TOKEN matches in .env and Meta
3. Ensure workflow is active (green toggle)
4. Check firewall allows ports 80/443

### Issue 2: Database Connection Failed

**Symptoms:** PostgreSQL nodes fail in workflow

**Diagnosis:**

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent -c "SELECT 1;"
```

**Solutions:**

1. Restart PostgreSQL: `docker-compose restart postgres`
2. Verify credentials in n8n match .env
3. Check database exists: `docker-compose exec postgres psql -U n8n_user -l`

### Issue 3: OpenAI API Errors

**Symptoms:** AI responses fail, "API key invalid" errors

**Diagnosis:**

```bash
# Test OpenAI API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"

# Check n8n logs for OpenAI errors
docker-compose logs n8n | grep -i openai
```

**Solutions:**

1. Verify API key is correct in n8n credentials
2. Check API key has sufficient credits
3. Check API key has required permissions
4. Try regenerating API key

### Issue 4: Scheduled Messages Not Sending

**Symptoms:** Proactive messaging workflow not sending messages

**Diagnosis:**

```bash
# Check workflow is active
# In n8n: Check "Proactive Messaging" workflow is Active

# Check for pending messages
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent \
  -c "SELECT * FROM scheduled_messages WHERE status = 'scheduled' AND scheduled_for < NOW();"

# Check workflow executions
# In n8n: Executions tab → Look for Proactive Messaging workflow
```

**Solutions:**

1. Ensure workflow is active
2. Check scheduled_for time is in the past
3. Check workflow execution logs for errors
4. Manually trigger workflow to test

### Issue 5: Video Processing Fails

**Symptoms:** Videos not being processed or analyzed

**Diagnosis:**

```bash
# Check video processing table
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent \
  -c "SELECT * FROM video_processing WHERE processing_status = 'failed' ORDER BY created_at DESC LIMIT 5;"

# Check S3 credentials
aws s3 ls s3://your-bucket-name --profile your-profile

# Check logs
docker-compose logs n8n | grep -i video
```

**Solutions:**

1. Verify AWS/GCS credentials are correct
2. Check video is under 16MB
3. Ensure ENABLE_VIDEO_SUPPORT=true in .env
4. Check cloud storage bucket exists and is accessible

### Issue 6: SSL Certificate Issues

**Symptoms:** HTTPS not working, certificate errors

**Diagnosis:**

```bash
# Check certificate files exist
sudo ls -la /etc/letsencrypt/live/your-domain.com/

# Test SSL
curl -v https://your-domain.com

# Check nginx logs
docker-compose logs nginx
```

**Solutions:**

1. Regenerate certificate: `sudo certbot certonly --standalone -d your-domain.com`
2. Check nginx SSL paths in nginx/nginx.conf
3. Restart nginx: `docker-compose restart nginx`

### Issue 7: High CPU/Memory Usage

**Diagnosis:**

```bash
# Check resource usage
docker stats

# Check specific container
docker stats n8n --no-stream

# Check system resources
htop
```

**Solutions:**

1. Increase server resources (RAM, CPU)
2. Optimize workflow execution
3. Enable queue mode for high traffic
4. Reduce max concurrent executions

### Issue 8: Handoff Notifications Not Received

**Symptoms:** Slack/Email notifications not arriving

**Diagnosis:**

```bash
# Check handoff table
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent \
  -c "SELECT * FROM handoff_requests ORDER BY created_at DESC LIMIT 5;"

# Test Slack webhook
curl -X POST YOUR_SLACK_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{"text": "Test message"}'

# Check logs
docker-compose logs n8n | grep -i handoff
```

**Solutions:**

1. Verify Slack webhook URL is correct
2. Check SMTP credentials for email
3. Ensure ENABLE_HUMAN_HANDOFF=true
4. Check agent_availability table has active agents

---

## Quick Command Reference

```bash
# === Service Management ===
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker-compose restart n8n        # Restart n8n
docker-compose ps                 # Check service status
docker-compose logs -f n8n        # View n8n logs

# === Database ===
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent
\dt                              # List tables
\d table_name                    # Describe table
SELECT * FROM users LIMIT 5;     # Query data
\q                              # Exit

# === Backups ===
docker exec postgres pg_dump -U n8n_user whatsapp_support_agent > backup.sql
docker exec -i postgres psql -U n8n_user whatsapp_support_agent < backup.sql

# === Monitoring ===
docker stats                     # Container resources
docker-compose logs --tail=100 n8n  # Last 100 log lines
htop                            # System resources

# === Updates ===
docker-compose pull              # Pull latest images
docker-compose up -d             # Restart with new images

# === Cleanup ===
docker system prune -a           # Remove unused images/containers
docker volume prune              # Remove unused volumes
```

---

## Deployment Checklist

Use this checklist to ensure everything is set up correctly:

### Pre-Deployment

- [ ] Server meets minimum requirements (4GB RAM, 2 CPU, 40GB disk)
- [ ] Domain name configured and pointing to server IP
- [ ] Docker and Docker Compose installed
- [ ] Firewall configured (ports 22, 80, 443)
- [ ] Repository cloned

### Phase 1: Infrastructure

- [ ] Environment file created from template
- [ ] All required environment variables filled
- [ ] Encryption keys generated
- [ ] Strong passwords set

### Phase 2: WhatsApp

- [ ] Meta Business Account created
- [ ] WhatsApp Business API app created
- [ ] Phone Number ID obtained
- [ ] Permanent access token generated
- [ ] Test phone number added

### Phase 3: Database

- [ ] PostgreSQL container started
- [ ] Base schema applied successfully
- [ ] Enhanced schema applied successfully
- [ ] Sample data verified
- [ ] All tables created

### Phase 4: n8n

- [ ] n8n container started
- [ ] Owner account created
- [ ] WhatsApp credential added
- [ ] OpenAI credential added
- [ ] PostgreSQL credential added

### Phase 5: Workflows

- [ ] Main workflow imported
- [ ] Main workflow credentials updated
- [ ] Main workflow activated
- [ ] Webhook URL noted
- [ ] Proactive messaging workflow imported
- [ ] Proactive messaging workflow activated

### Phase 6: Features

- [ ] Human handoff configured (Slack/Email/Webhook)
- [ ] Sample agents added to database
- [ ] Voice responses configured (if using)
- [ ] Video support configured (if using)
- [ ] Cloud storage configured (if using videos)

### Phase 7: Testing

- [ ] Webhook configured in Meta and verified
- [ ] Test message sent successfully
- [ ] AI response received
- [ ] Voice message transcription works
- [ ] Image analysis works
- [ ] Handoff test successful
- [ ] Scheduled message test successful

### Phase 8: Production

- [ ] SSL certificate obtained
- [ ] Nginx configured and running
- [ ] HTTPS working
- [ ] Production webhook updated
- [ ] Passwords changed from defaults
- [ ] Firewall rules verified
- [ ] Backups configured
- [ ] Monitoring set up

### Post-Deployment

- [ ] Daily backups running
- [ ] Health checks running
- [ ] Log rotation configured
- [ ] Cost monitoring set up
- [ ] Documentation updated with your specifics
- [ ] Team trained on system

---

## Support & Resources

- **Documentation**: [README.md](README.md), [FEATURES.md](FEATURES.md), [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- **n8n Community**: https://community.n8n.io
- **WhatsApp Business Docs**: https://developers.facebook.com/docs/whatsapp
- **OpenAI API Docs**: https://platform.openai.com/docs
- **Docker Docs**: https://docs.docker.com

---

**Congratulations!** 🎉 You've successfully deployed the complete WhatsApp AI Support Agent with all enhanced features!

Your system is now ready to handle:
- ✅ AI-powered customer support
- ✅ Multimodal conversations (text, voice, images, video)
- ✅ Human handoff when needed
- ✅ Proactive notifications and campaigns
- ✅ Voice responses
- ✅ Video message analysis
- ✅ Complete analytics and monitoring

For ongoing support, refer to the [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for common commands and [FEATURES.md](FEATURES.md) for feature-specific guides.
