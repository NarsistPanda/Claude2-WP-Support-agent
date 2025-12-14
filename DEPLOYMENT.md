# Deployment Guide - n8n WhatsApp AI Support Agent

This guide will walk you through deploying the complete WhatsApp AI Support Agent solution.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [WhatsApp Business API Setup](#whatsapp-business-api-setup)
3. [n8n Installation](#n8n-installation)
4. [Database Setup](#database-setup)
5. [Workflow Import](#workflow-import)
6. [Configuration](#configuration)
7. [Webhook Configuration](#webhook-configuration)
8. [Testing](#testing)
9. [Production Deployment](#production-deployment)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, ensure you have:

- **Meta Business Account** - [Create one here](https://business.facebook.com/)
- **Meta Developer Account** - [Sign up here](https://developers.facebook.com/)
- **Phone Number** - For WhatsApp Business API (can't be used with regular WhatsApp)
- **OpenAI API Key** - [Get it here](https://platform.openai.com/api-keys)
- **Server/VPS** - With public IP and domain (for production)
- **Docker & Docker Compose** - [Install Docker](https://docs.docker.com/get-docker/)
- **PostgreSQL Database** - Version 14 or higher

**Estimated Setup Time**: 1-2 hours

---

## WhatsApp Business API Setup

### Step 1: Create a Meta App

1. Go to [Meta for Developers](https://developers.facebook.com/)
2. Click **"My Apps"** → **"Create App"**
3. Select **"Business"** as app type
4. Fill in app details:
   - **App Name**: "WhatsApp Support Agent"
   - **App Contact Email**: Your email
   - **Business Account**: Select your business account

### Step 2: Add WhatsApp Product

1. In your app dashboard, find **"WhatsApp"** in the products list
2. Click **"Set up"**
3. Select or create a **Business Portfolio**

### Step 3: Configure WhatsApp

1. Navigate to **WhatsApp** → **Getting Started**
2. Note down:
   - **Phone Number ID** (you'll need this)
   - **WhatsApp Business Account ID**
3. Generate a **Temporary Access Token** (24 hours)
   - For production, you'll need a **Permanent Access Token**

### Step 4: Generate Permanent Access Token

1. Go to **WhatsApp** → **Configuration**
2. Click **"Generate Token"**
3. Select permissions:
   - `whatsapp_business_management`
   - `whatsapp_business_messaging`
4. Copy and save the token securely

### Step 5: Add a Phone Number

**Option A: Use Test Number (for development)**
- Meta provides a test number
- Can send messages to 5 pre-registered numbers
- Good for initial testing

**Option B: Add Your Own Number (for production)**
1. Go to **WhatsApp** → **API Setup**
2. Click **"Add Phone Number"**
3. Follow verification steps
4. Complete business verification (may take 1-2 weeks)

### Step 6: Configure Webhook (Do this after n8n setup)

We'll come back to this after setting up n8n.

---

## n8n Installation

### Option 1: Docker Compose (Recommended)

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=${WEBHOOK_URL}
      - GENERIC_TIMEZONE=America/New_York
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${DB_NAME}
      - DB_POSTGRESDB_USER=${DB_USER}
      - DB_POSTGRESDB_PASSWORD=${DB_PASSWORD}
    volumes:
      - n8n_data:/home/node/.n8n
      - ./workflows:/home/node/workflows
    depends_on:
      - postgres
    networks:
      - n8n-network

  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database-schema.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - n8n-network
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - n8n-network

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - certbot_data:/var/www/certbot
    depends_on:
      - n8n
    networks:
      - n8n-network

  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - certbot_data:/var/www/certbot
      - ./ssl:/etc/letsencrypt
    command: certonly --webroot --webroot-path=/var/www/certbot --email your-email@example.com --agree-tos --no-eff-email -d your-domain.com

volumes:
  n8n_data:
  postgres_data:
  redis_data:
  certbot_data:

networks:
  n8n-network:
    driver: bridge
```

**Start the services:**

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your values
nano .env

# Generate encryption key
export N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
echo "N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY" >> .env

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f n8n
```

### Option 2: npm Installation

```bash
# Install n8n globally
npm install n8n -g

# Start n8n
n8n start

# Access at http://localhost:5678
```

### Option 3: n8n Cloud

1. Go to [n8n.cloud](https://n8n.cloud)
2. Sign up for an account
3. Choose a plan (starts at $20/month)
4. Instance is ready immediately with HTTPS

---

## Database Setup

### PostgreSQL Setup

**If using Docker Compose**, the database is automatically created.

**For manual setup:**

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE whatsapp_support_agent;

# Create user
CREATE USER n8n_user WITH PASSWORD 'your_secure_password';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE whatsapp_support_agent TO n8n_user;

# Exit
\q

# Import schema
psql -U n8n_user -d whatsapp_support_agent -f database-schema.sql
```

### Verify Database

```bash
# Connect to database
psql -U n8n_user -d whatsapp_support_agent

# List tables
\dt

# Should see: users, user_conversations, messages, ai_interactions, knowledge_base, etc.

# Check knowledge base
SELECT title FROM knowledge_base;
```

---

## Workflow Import

### Import the Workflow

1. Access your n8n instance: `https://your-domain.com` or `http://localhost:5678`
2. Create an account (first time)
3. Click **"Workflows"** in the left sidebar
4. Click **"Add Workflow"** → **"Import from File"**
5. Select `whatsapp-support-agent-workflow.json`
6. The workflow will be imported

### Configure Credentials

The workflow needs three credentials:

#### 1. WhatsApp Business Cloud

1. In the workflow, click any WhatsApp node
2. Click **"Create New Credential"**
3. Enter:
   - **Credential Name**: "WhatsApp Business Cloud"
   - **Access Token**: Your permanent access token from Meta
   - **Phone Number ID**: From Meta dashboard

#### 2. OpenAI

1. Click any OpenAI node
2. Click **"Create New Credential"**
3. Enter:
   - **Credential Name**: "OpenAI"
   - **API Key**: Your OpenAI API key from platform.openai.com

#### 3. PostgreSQL

1. Click any PostgreSQL node
2. Click **"Create New Credential"**
3. Enter:
   - **Credential Name**: "PostgreSQL"
   - **Host**: `postgres` (if using Docker) or `localhost`
   - **Database**: `whatsapp_support_agent`
   - **User**: Your database user
   - **Password**: Your database password
   - **Port**: `5432`
   - **SSL**: `false` (or `true` for production)

### Test Credentials

1. Click **"Test"** on each credential
2. Ensure all show ✓ Success

---

## Configuration

### Environment Variables

Edit your `.env` file:

```bash
# Required
WHATSAPP_PHONE_NUMBER_ID=123456789012345
WHATSAPP_ACCESS_TOKEN=EAAxxxxxxxxxxxxxxx
WHATSAPP_VERIFY_TOKEN=my_custom_verify_token_12345
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxx
DB_PASSWORD=your_secure_db_password

# Update these
N8N_WEBHOOK_URL=https://your-domain.com
WEBHOOK_URL=https://your-domain.com
```

### Webhook Verify Token

Choose a secure random string:

```bash
# Generate verify token
openssl rand -hex 32
```

Use this in:
- Your `.env` file as `WHATSAPP_VERIFY_TOKEN`
- Meta webhook configuration (next step)

---

## Webhook Configuration

### Get Your Webhook URL

Your webhook URL format:
```
https://your-domain.com/webhook/whatsapp-webhook
```

Or for testing:
```
https://your-domain.com/webhook-test/whatsapp-webhook
```

### Activate Workflow in n8n

1. Open your workflow in n8n
2. Click **"Active"** toggle in top right
3. Workflow is now listening for webhooks

### Configure Webhook in Meta

1. Go to Meta Developer Dashboard
2. Navigate to **WhatsApp** → **Configuration**
3. Click **"Edit"** in Webhook section
4. Enter:
   - **Callback URL**: `https://your-domain.com/webhook/whatsapp-webhook`
   - **Verify Token**: Your `WHATSAPP_VERIFY_TOKEN` from .env
5. Click **"Verify and Save"**

If successful, you'll see ✓ Verified

### Subscribe to Webhook Events

1. In the same Webhook section
2. Click **"Manage"**
3. Subscribe to:
   - ☑ `messages` - Required for receiving messages
   - ☑ `message_status` - Optional, for delivery status
4. Click **"Save"**

---

## Testing

### Test 1: Verify Webhook

Check n8n execution logs:
- You should see a successful execution from the webhook verification

### Test 2: Send a Test Message

1. Add your phone number as a recipient:
   - In Meta dashboard: **WhatsApp** → **API Setup**
   - Click **"Send a test message"**
   - Enter your phone number
2. Send a message to your WhatsApp Business number
3. Check n8n:
   - Should see new execution
   - Check execution log for the message flow

### Test 3: Text Message

Send: "What is n8n?"

Expected: AI response about n8n

### Test 4: Voice Message

Send a voice message saying: "Hello, I need help"

Expected: AI response based on transcription

### Test 5: Image

Send an image with caption: "What do you see?"

Expected: AI description of the image

### Test 6: Conversation Memory

1. Send: "My name is John"
2. Send: "What's my name?"

Expected: AI remembers "John"

### Debugging Tests

If tests fail:

```bash
# Check n8n logs
docker-compose logs -f n8n

# Check webhook executions in n8n UI
# Workflows → Your Workflow → Executions

# Test webhook manually
curl -X POST https://your-domain.com/webhook/whatsapp-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "from": "1234567890",
            "id": "test_message_id",
            "timestamp": "1234567890",
            "text": {"body": "Hello"},
            "type": "text"
          }],
          "contacts": [{"profile": {"name": "Test User"}}],
          "metadata": {"phone_number_id": "your_phone_number_id"}
        }
      }],
      "id": "your_business_account_id"
    }]
  }'
```

---

## Production Deployment

### Security Checklist

- ☑ Use HTTPS (Let's Encrypt)
- ☑ Strong database passwords
- ☑ Firewall rules (only allow ports 80, 443, 22)
- ☑ Regular backups
- ☑ Environment variables not committed to git
- ☑ Rate limiting enabled
- ☑ Error monitoring (Sentry)
- ☑ Update tokens to permanent (not temporary)

### SSL Certificate (Let's Encrypt)

```bash
# Using certbot
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo certbot renew --dry-run
```

### Nginx Configuration

Create `/etc/nginx/sites-available/n8n`:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Enable and restart:

```bash
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Monitoring

**Set up monitoring:**

```bash
# System monitoring
apt install htop iotop

# Database monitoring
psql -U n8n_user -d whatsapp_support_agent
SELECT * FROM message_stats ORDER BY date DESC LIMIT 7;
SELECT * FROM active_users_stats;
SELECT * FROM ai_performance_stats ORDER BY date DESC LIMIT 7;
```

**Error tracking with Sentry** (optional):

1. Sign up at [sentry.io](https://sentry.io)
2. Create a project
3. Add DSN to `.env`:
```bash
SENTRY_DSN=https://xxxxx@sentry.io/xxxxx
```

### Backup Strategy

**Automated backups:**

```bash
# Create backup script
cat > /usr/local/bin/backup-whatsapp-agent.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backups/whatsapp-agent"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
docker exec postgres pg_dump -U n8n_user whatsapp_support_agent | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Backup n8n data
docker exec n8n tar czf - /home/node/.n8n > $BACKUP_DIR/n8n_data_$DATE.tar.gz

# Keep only last 7 days
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /usr/local/bin/backup-whatsapp-agent.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * /usr/local/bin/backup-whatsapp-agent.sh
```

### Scaling Considerations

**For high traffic:**

1. **Use n8n Queue Mode**:
```yaml
# docker-compose.yml
environment:
  - EXECUTIONS_MODE=queue
  - QUEUE_BULL_REDIS_HOST=redis
```

2. **PostgreSQL Connection Pooling**:
```bash
# Use PgBouncer
docker run -d --name pgbouncer \
  -e POSTGRESQL_HOST=postgres \
  -e POSTGRESQL_DATABASE=whatsapp_support_agent \
  bitnami/pgbouncer:latest
```

3. **Horizontal Scaling**:
- Deploy multiple n8n workers
- Use load balancer (nginx, HAProxy)
- Shared database and Redis

### Cost Optimization

**Monitor API usage:**

```sql
-- Check daily token usage
SELECT
    DATE(created_at) as date,
    model_used,
    SUM(tokens_used) as total_tokens,
    COUNT(*) as requests
FROM ai_interactions
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at), model_used
ORDER BY date DESC;

-- Estimate costs (OpenAI GPT-4o-mini: ~$0.15/$0.60 per 1M tokens)
SELECT
    DATE(created_at) as date,
    SUM(tokens_used) * 0.00000015 as input_cost_usd,
    SUM(tokens_used) * 0.00000060 as output_cost_usd
FROM ai_interactions
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at);
```

**Optimize costs:**
- Use `gpt-4o-mini` instead of `gpt-4` (10x cheaper)
- Implement caching for common questions
- Limit conversation history to last 5-10 messages
- Use RAG to reduce token usage

---

## Troubleshooting

### Issue: Webhook not receiving messages

**Check:**
1. Is workflow active in n8n?
2. Is webhook URL correct in Meta dashboard?
3. Is verify token correct?
4. Check n8n logs: `docker-compose logs -f n8n`
5. Test webhook manually with curl
6. Check firewall: ports 80, 443 open?

**Solution:**
```bash
# Test connectivity
curl https://your-domain.com/webhook/whatsapp-webhook

# Should return 401 or require POST method
```

### Issue: Messages received but no reply

**Check:**
1. OpenAI credentials correct?
2. WhatsApp credentials correct?
3. Check execution logs in n8n UI
4. Look for error in specific node

**Solution:**
```bash
# Test OpenAI connection
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Check n8n execution logs
# Workflows → Executions → Click failed execution
```

### Issue: Voice transcription fails

**Check:**
1. OpenAI API has Whisper access
2. Audio file downloaded correctly
3. Audio format supported (ogg, mp3, mp4, etc.)

**Solution:**
```sql
-- Check failed messages
SELECT * FROM error_logs
WHERE error_type LIKE '%transcribe%'
ORDER BY created_at DESC LIMIT 10;
```

### Issue: Database connection fails

**Check:**
1. PostgreSQL running: `docker-compose ps`
2. Credentials correct in n8n
3. Database exists: `psql -U n8n_user -l`

**Solution:**
```bash
# Restart database
docker-compose restart postgres

# Check logs
docker-compose logs postgres

# Test connection
psql -U n8n_user -h localhost -d whatsapp_support_agent
```

### Issue: High costs

**Check:**
```sql
-- Find expensive interactions
SELECT
    phone_number,
    COUNT(*) as interactions,
    SUM(tokens_used) as total_tokens,
    AVG(tokens_used) as avg_tokens
FROM ai_interactions
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY phone_number
ORDER BY total_tokens DESC
LIMIT 10;
```

**Solution:**
- Reduce `max_tokens` in AI node (current: 500)
- Shorten system prompt
- Limit conversation history
- Implement rate limiting per user

### Issue: SSL certificate errors

**Solution:**
```bash
# Renew certificate
sudo certbot renew

# Check certificate expiry
sudo certbot certificates

# Force renewal
sudo certbot renew --force-renewal
```

### Getting Help

- **n8n Community**: https://community.n8n.io
- **n8n Documentation**: https://docs.n8n.io
- **WhatsApp Business API Docs**: https://developers.facebook.com/docs/whatsapp
- **OpenAI API Docs**: https://platform.openai.com/docs

---

## Next Steps

After successful deployment:

1. **Customize AI Prompt**: Edit the system message in the AI Agent node
2. **Add Knowledge Base**: Insert your company's FAQs into `knowledge_base` table
3. **Enable RAG**: Implement vector search for better answers
4. **Add Analytics Dashboard**: Create Grafana dashboard
5. **Human Handoff**: Integrate with customer support platform
6. **Multi-language**: Add language detection and translation
7. **Template Messages**: Use WhatsApp templates for notifications

Congratulations! Your WhatsApp AI Support Agent is now live! 🎉
