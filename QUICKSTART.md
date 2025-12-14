# Quick Start Guide - 10 Minutes to Your First WhatsApp AI Agent

Get your WhatsApp AI Support Agent up and running in just 10 minutes!

## ⚠️ Important Note

This quick start guide is designed for **testing and development only**. It sets up the **basic features**:
- ✅ Text message handling
- ✅ Voice transcription (Whisper)
- ✅ Image analysis (GPT-4 Vision)
- ✅ Basic conversation memory
- ✅ AI responses

**For production deployment with all v2.0 enhanced features**, use the comprehensive deployment guide:

### v2.0 Enhanced Features (Production)
- 🎯 **Human Handoff** - Transfer to live agents when needed
- 📢 **Proactive Messaging** - Scheduled notifications and campaigns
- 🎙️ **Voice Responses** - Text-to-speech audio replies
- 🎥 **Video Support** - Process and analyze video messages

👉 **[DEPLOYMENT-V2.md](DEPLOYMENT-V2.md)** - Complete step-by-step deployment guide for all features

---

## Prerequisites Checklist

Before you start, have these ready:

- ☐ **Meta Business Account** - [Sign up here](https://business.facebook.com/)
- ☐ **OpenAI API Key** - [Get it here](https://platform.openai.com/api-keys)
- ☐ **Docker installed** - [Install Docker](https://docs.docker.com/get-docker/)
- ☐ **Phone number** for testing WhatsApp

**Note**: For production, you'll need a domain with SSL. For testing, we can use ngrok or similar.

---

## Step 1: Get WhatsApp API Credentials (3 minutes)

### 1.1 Create Meta App

1. Go to [Meta for Developers](https://developers.facebook.com/apps)
2. Click **"Create App"** → Choose **"Business"** type
3. Name it "WhatsApp Support Agent"
4. Click **"Create App"**

### 1.2 Add WhatsApp Product

1. Find **"WhatsApp"** in products list
2. Click **"Set up"**
3. You'll see the WhatsApp API Setup page

### 1.3 Get Your Credentials

On the WhatsApp Getting Started page, note down:

```
Phone Number ID: 123456789012345 (copy this!)
WhatsApp Business Account ID: 987654321098765 (copy this!)
```

Click **"Generate Token"** and copy the temporary access token:
```
Access Token: EAAxxxxxxxxxxxxxxxxx (copy this!)
```

**Important**: This token expires in 24 hours. We'll generate a permanent one later.

---

## Step 2: Get OpenAI API Key (1 minute)

1. Go to [OpenAI API Keys](https://platform.openai.com/api-keys)
2. Click **"Create new secret key"**
3. Name it "WhatsApp Agent"
4. Copy the key (starts with `sk-`)

```
OpenAI Key: sk-xxxxxxxxxxxxxxxx (copy this!)
```

---

## Step 3: Deploy Locally (3 minutes)

### 3.1 Clone and Configure

```bash
# Clone the repository
git clone https://github.com/yourusername/whatsapp-n8n-agent.git
cd whatsapp-n8n-agent

# Copy environment template
cp .env.example .env
```

### 3.2 Edit .env File

Open `.env` in your text editor and fill in:

```bash
# WhatsApp Credentials (from Step 1)
WHATSAPP_PHONE_NUMBER_ID=123456789012345
WHATSAPP_BUSINESS_ACCOUNT_ID=987654321098765
WHATSAPP_ACCESS_TOKEN=EAAxxxxxxxxxxxxxxxxx
WHATSAPP_VERIFY_TOKEN=my_random_verify_token_12345  # Make up any random string

# OpenAI (from Step 2)
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxx

# Database (use these defaults for local testing)
DB_NAME=whatsapp_support_agent
DB_USER=n8n_user
DB_PASSWORD=change_this_password_123

# n8n (will configure later)
N8N_ENCRYPTION_KEY=  # Leave empty, we'll generate this
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=admin123

# For local testing
N8N_WEBHOOK_URL=http://localhost:5678
```

### 3.3 Generate Encryption Key

```bash
# Generate and add to .env
echo "N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)" >> .env
```

### 3.4 Start Services

```bash
# Start all services
docker-compose up -d

# Check if everything is running
docker-compose ps

# Should see: n8n, postgres, redis all "Up"
```

**Wait about 30 seconds for services to fully start.**

---

## Step 4: Configure n8n (2 minutes)

### 4.1 Access n8n

1. Open browser: `http://localhost:5678`
2. Create your account:
   - Email: your@email.com
   - Password: (choose a strong password)

### 4.2 Import Workflow

1. Click **"Workflows"** in left sidebar
2. Click **"Add Workflow"** (plus icon)
3. Click the menu (⋮) → **"Import from File"**
4. Select `whatsapp-support-agent-workflow.json`
5. Click **"Import"**

The workflow will load with all nodes!

### 4.3 Add Credentials

**WhatsApp Business Cloud:**
1. Click any orange WhatsApp node (shows credential error)
2. Click **"Create New Credential"**
3. Fill in:
   - **Name**: WhatsApp Business Cloud
   - **Access Token**: (paste from Step 1)
   - **Phone Number ID**: (paste from Step 1)
4. Click **"Save"**

**OpenAI:**
1. Click any purple OpenAI node
2. Click **"Create New Credential"**
3. Fill in:
   - **Name**: OpenAI
   - **API Key**: (paste from Step 2)
4. Click **"Save"**

**PostgreSQL:**
1. Click any elephant-icon PostgreSQL node
2. Click **"Create New Credential"**
3. Fill in:
   - **Name**: PostgreSQL
   - **Host**: `postgres`
   - **Database**: `whatsapp_support_agent`
   - **User**: `n8n_user`
   - **Password**: (from your .env)
   - **Port**: `5432`
   - **SSL**: Disable
4. Click **"Save"**

### 4.4 Activate Workflow

1. Click the toggle switch at top: **"Inactive"** → **"Active"**
2. Workflow is now live! 🎉

---

## Step 5: Expose Webhook (for testing only, 1 minute)

For local testing, we need to expose n8n to the internet so WhatsApp can reach it.

**Using ngrok** (easiest):

```bash
# Install ngrok: https://ngrok.com/download
# Then run:
ngrok http 5678

# You'll see output like:
# Forwarding: https://abc123.ngrok.io -> http://localhost:5678
```

Copy the `https://abc123.ngrok.io` URL (your URL will be different).

**Your webhook URL is:**
```
https://abc123.ngrok.io/webhook/whatsapp-webhook
```

---

## Step 6: Configure Webhook in Meta (2 minutes)

### 6.1 Add Webhook

1. Go back to [Meta Developer Dashboard](https://developers.facebook.com/apps)
2. Select your app → **WhatsApp** → **Configuration**
3. Find **"Webhook"** section
4. Click **"Edit"**

### 6.2 Enter Webhook Details

Fill in:
- **Callback URL**: `https://abc123.ngrok.io/webhook/whatsapp-webhook`
- **Verify Token**: (same as `WHATSAPP_VERIFY_TOKEN` from your .env)

Click **"Verify and Save"**

✅ You should see **"Verified"** if successful!

### 6.3 Subscribe to Events

1. Still in Webhook section
2. Click **"Manage"**
3. Subscribe to:
   - ☑️ **messages**
4. Click **"Done"**

---

## Step 7: Test Your Agent! (1 minute)

### 7.1 Add Test Number

1. In Meta dashboard: **WhatsApp** → **API Setup**
2. Find **"Send and receive messages"** section
3. Under **"To"**, click **"Manage phone number list"**
4. Click **"Add phone number"**
5. Enter your WhatsApp number (include country code)
6. You'll receive a code on WhatsApp - enter it

### 7.2 Send Test Message

**From Meta Dashboard** (quick test):
1. In **"API Setup"** page, find the test message box
2. Select your number
3. Click **"Send message"**
4. Check n8n executions (in n8n, click "Executions" tab)

**From Your WhatsApp** (real test):
1. Open WhatsApp on your phone
2. Send any message to the test number shown in Meta dashboard
3. Wait 2-3 seconds
4. You should receive an AI response! 🎉

### Test Messages to Try

```
"What is n8n?"
"How do I create a workflow?"
"I need help with webhooks"
```

**Send a voice message** - it should transcribe and respond!

**Send an image** - it should analyze and describe it!

---

## Congratulations! 🎉

Your WhatsApp AI Support Agent is now live!

### What You've Built

✅ AI-powered WhatsApp bot
✅ Handles text, voice, images
✅ Conversation memory
✅ Running on your local machine

---

## Next Steps

### Make It Production-Ready

1. **Get Permanent Access Token**
   - In Meta dashboard: WhatsApp → Configuration
   - Generate permanent token
   - Update `.env` with new token

2. **Deploy to Server**
   - Get a VPS (DigitalOcean, AWS, etc.)
   - Get a domain name
   - Setup SSL certificate
   - See [DEPLOYMENT.md](DEPLOYMENT.md) for details

3. **Customize the Bot**
   - Edit system prompt in AI Agent node
   - Add your company knowledge to database
   - Adjust response length and style

4. **Add v2.0 Enhanced Features**
   - See **[FEATURES.md](FEATURES.md)** for detailed guides on:
     - Human Handoff (Slack, Email, Custom integrations)
     - Proactive Messaging (Campaigns, Templates, Scheduling)
     - Voice Responses (Text-to-speech with 6 voice options)
     - Video Support (Cloud storage + AI analysis)
   - Enable RAG (Retrieval Augmented Generation)
   - Integrate with your CRM
   - Add analytics dashboard

### Monitoring

Check what's happening:

```bash
# View logs
docker-compose logs -f n8n

# Check database
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent

# Query messages
SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;

# Check active users
SELECT * FROM active_users_stats;
```

### Troubleshooting

**Bot not responding?**
- Check n8n executions for errors
- Verify credentials are correct
- Check webhook is verified in Meta dashboard
- Look at logs: `docker-compose logs -f n8n`

**"Webhook verification failed"?**
- Make sure verify tokens match exactly
- Check ngrok is still running
- Ensure workflow is active

**Database errors?**
- Check PostgreSQL is running: `docker-compose ps`
- Verify credentials in n8n match `.env`

See [DEPLOYMENT.md#troubleshooting](DEPLOYMENT.md#troubleshooting) for more help.

---

## Resources

### Documentation
- 📖 **[DEPLOYMENT-V2.md](DEPLOYMENT-V2.md)** - Complete v2.0 deployment guide with all features
- 📋 **[DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)** - Printable deployment tracker
- 🎯 **[FEATURES.md](FEATURES.md)** - Enhanced features implementation guide
- 🏗️ **[ARCHITECTURE-V2.md](ARCHITECTURE-V2.md)** - Complete v2.0 architecture
- ⚡ **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Essential commands and queries
- 📖 [DEPLOYMENT.md](DEPLOYMENT.md) - Navigation hub for all deployment docs

### Community
- 💬 [n8n Community](https://community.n8n.io) - Get help from the community

---

## Support

Having issues?

1. Check the [Troubleshooting section](DEPLOYMENT.md#troubleshooting)
2. Review execution logs in n8n
3. Ask on [n8n Community Forum](https://community.n8n.io)
4. Open an [issue on GitHub](https://github.com/yourusername/whatsapp-n8n-agent/issues)

---

**You did it!** Now you have a working WhatsApp AI Support Agent. Time to customize it for your business! 🚀
