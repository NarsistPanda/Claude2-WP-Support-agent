# WhatsApp AI Support Agent with n8n

<div align="center">

![n8n](https://img.shields.io/badge/n8n-Workflow-EA4B71?style=for-the-badge&logo=n8n)
![WhatsApp](https://img.shields.io/badge/WhatsApp-Business-25D366?style=for-the-badge&logo=whatsapp)
![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-412991?style=for-the-badge&logo=openai)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-316192?style=for-the-badge&logo=postgresql)

**A complete, production-ready AI support agent for WhatsApp built with n8n**

[Features](#features) • [Demo](#demo) • [Quick Start](#quick-start) • [Documentation](#documentation) • [Architecture](#architecture)

</div>

---

## Overview

This project provides a **complete end-to-end solution** for building an AI-powered support agent that works on WhatsApp using n8n workflow automation. Users can interact with the agent via WhatsApp, and it responds intelligently using AI.

### What This Solution Includes

✅ **Complete n8n Workflow** - Ready-to-import JSON configuration
✅ **Multimodal Support** - Text, voice, images, PDFs, and videos
✅ **AI-Powered Responses** - Using OpenAI GPT-4
✅ **Conversation Memory** - Context-aware responses
✅ **Human Handoff** - Transfer to live agents when needed ⭐ NEW
✅ **Proactive Messaging** - Scheduled notifications and campaigns ⭐ NEW
✅ **Voice Responses** - Text-to-speech audio replies ⭐ NEW
✅ **Video Support** - Process and analyze video messages ⭐ NEW
✅ **RAG Support** - Knowledge base integration
✅ **Database Schema** - PostgreSQL schema for data storage
✅ **Deployment Guides** - Complete setup instructions
✅ **Docker Compose** - One-command deployment
✅ **Production Ready** - Security, monitoring, backups

---

## Features

### 🤖 Intelligent AI Agent

- **Natural Language Understanding** - Powered by OpenAI GPT-4
- **Context Awareness** - Remembers conversation history
- **Knowledge Base** - Retrieval Augmented Generation (RAG)
- **Customizable Personality** - Tailor responses to your brand

### 📱 Multimodal Support

- **Text Messages** - Natural conversation flow
- **Voice Messages** - Automatic transcription with Whisper
- **Images** - Visual analysis with GPT-4 Vision
- **PDF Documents** - Text extraction and Q&A
- **Video Messages** ⭐ NEW - Process and analyze videos
- **Location & Contacts** - Handle special message types

### 🎯 Enhanced Features (NEW!)

- **Human Handoff** ⭐ - Transfer conversations to live agents
  - Automatic escalation based on sentiment
  - Slack, email, or CRM integration
  - Agent availability management
  - Performance tracking

- **Proactive Messaging** ⭐ - Send scheduled notifications
  - Order updates and shipping notifications
  - Appointment reminders
  - Marketing campaigns
  - Template management

- **Voice Responses** ⭐ - Send audio replies
  - Text-to-speech with OpenAI TTS
  - Multiple voice options
  - User preferences
  - Cost-efficient caching

- **Video Support** ⭐ - Handle video messages
  - Download and store videos
  - AI-powered frame analysis
  - Content recognition
  - Automatic response generation

### 💾 Data Management

- **Conversation History** - Persistent storage in PostgreSQL
- **User Profiles** - Track user information and preferences
- **Analytics** - Message stats, AI performance, user engagement
- **Feedback System** - Collect user satisfaction ratings
- **Handoff Tracking** - Monitor agent performance
- **Campaign Analytics** - Track proactive message success

### 🚀 Production Features

- **Webhook Handling** - Secure WhatsApp API integration
- **Error Handling** - Graceful fallbacks and retries
- **Rate Limiting** - Protect against abuse
- **Logging** - Comprehensive error tracking
- **Monitoring** - Built-in analytics views
- **Backups** - Automated database backups

---

## Demo

### Text Conversation

```
User: What is n8n?
Bot: n8n is a powerful workflow automation tool that lets you connect
     different services and create automated workflows. It can be
     self-hosted or used via n8n Cloud. How can I help you with n8n?

User: How do I create a workflow?
Bot: To create a workflow: 1) Click + in top right, 2) Add nodes by
     clicking +, 3) Connect nodes, 4) Configure settings, 5) Test and
     activate. Need help with a specific step?
```

### Voice Message Support

```
User: [Sends voice message: "I'm having trouble with webhooks"]
Bot: I heard you're having trouble with webhooks. The Webhook trigger
     node listens for HTTP requests. Make sure your webhook URL is
     correct and the workflow is active. What specific issue are you
     facing?
```

### Image Analysis

```
User: [Sends screenshot of error]
Bot: I can see an error message about authentication. This usually means
     your credentials need to be updated. Go to Credentials > WhatsApp
     Business Cloud and verify your access token is still valid.
```

---

## Quick Start

### Prerequisites

- Meta Business Account + WhatsApp Business API access
- OpenAI API key
- Server with Docker installed (or n8n Cloud account)
- Domain name with SSL (for production)

### Installation (5 minutes)

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/whatsapp-n8n-agent.git
cd whatsapp-n8n-agent
```

2. **Configure environment**

```bash
cp .env.example .env
nano .env  # Edit with your credentials
```

3. **Start services**

```bash
docker-compose up -d
```

4. **Import workflow**

- Open n8n at `http://localhost:5678`
- Import `whatsapp-support-agent-workflow.json`
- Add credentials (WhatsApp, OpenAI, PostgreSQL)
- Activate workflow

5. **Configure webhook in Meta**

- Go to Meta Developer Dashboard
- WhatsApp > Configuration > Webhook
- Add your webhook URL: `https://yourdomain.com/webhook/whatsapp-webhook`
- Subscribe to `messages` events

6. **Test it!**

Send a WhatsApp message to your business number and get an AI response!

### Full Documentation

📖 **[Complete Deployment Guide (v2.0)](docs/DEPLOYMENT-V2.md)** - Comprehensive step-by-step with all features
🐳 **[Docker Compose Deployment](docs/DOCKER-DEPLOYMENT.md)** - Production-ready Docker deployment
☁️ **[Azure Deployment Guide](docs/AZURE-DEPLOYMENT.md)** - Complete Azure deployment (ACI, AKS, App Service)
📋 **[Deployment Checklist](docs/DEPLOYMENT-CHECKLIST.md)** - Printable deployment tracker
⚡ **[Quick Start Guide](docs/QUICKSTART.md)** - 10-minute setup for testing
🎯 **[Enhanced Features Guide](docs/FEATURES.md)** - Human handoff, proactive messaging, voice & video
🏗️ **[Architecture Documentation](docs/ARCHITECTURE.md)** - System design details
💡 **[Quick Reference](docs/QUICK-REFERENCE.md)** - Essential commands and queries

---

## Architecture

### High-Level Flow

```
WhatsApp User → WhatsApp Business API → n8n Webhook →
Message Router → Media Processor → Memory Manager →
AI Agent (RAG) → Response Handler → WhatsApp Reply
```

### Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Workflow Engine** | n8n | Orchestrates the entire flow |
| **Messaging** | WhatsApp Business Cloud API | Send/receive messages |
| **AI Model** | OpenAI GPT-4o-mini | Generate intelligent responses |
| **Transcription** | OpenAI Whisper | Convert voice to text |
| **Vision** | GPT-4 Vision | Analyze images |
| **Database** | PostgreSQL | Store conversations and data |
| **Cache** | Redis | Session management |
| **Vector DB** | Pinecone/Qdrant | Knowledge base search (optional) |

### Key Features by Component

#### 1. Webhook Handler
- Validates Meta webhook verification
- Parses incoming WhatsApp messages
- Handles all message types

#### 2. Message Router
- Routes by message type (text, audio, image, document)
- Parallel processing for efficiency
- Error handling and logging

#### 3. Media Processor
- Downloads media from WhatsApp
- Transcribes audio with Whisper
- Analyzes images with GPT-4 Vision
- Extracts text from PDFs

#### 4. Memory Manager
- Loads conversation history
- Maintains context window
- Saves new messages
- User session management

#### 5. AI Agent (RAG)
- Generates responses using GPT-4
- Searches knowledge base
- Context injection
- Source citations

#### 6. Response Handler
- Formats responses for WhatsApp
- Saves to conversation history
- Sends reply via WhatsApp API

---

## Configuration

### Environment Variables

Key configurations in `.env`:

```bash
# WhatsApp
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id
WHATSAPP_ACCESS_TOKEN=your_access_token
WHATSAPP_VERIFY_TOKEN=your_verify_token

# OpenAI
OPENAI_API_KEY=sk-your_api_key
OPENAI_MODEL=gpt-4o-mini

# Database
DB_HOST=postgres
DB_NAME=whatsapp_support_agent
DB_USER=n8n_user
DB_PASSWORD=your_password

# n8n
N8N_WEBHOOK_URL=https://your-domain.com
```

See [`.env.example`](.env.example) for all options.

### Customizing the AI Agent

Edit the system prompt in the AI Agent node:

```javascript
You are a helpful AI support assistant for [YOUR COMPANY].

Your role:
1. Answer questions about [YOUR PRODUCT]
2. Help troubleshoot issues
3. Provide friendly, concise responses

Key information:
- [YOUR PRODUCT INFO]
- [SUPPORT POLICIES]
- [CONTACT INFO]
```

### Adding Knowledge Base Content

Insert your FAQs into the database:

```sql
INSERT INTO knowledge_base (title, content, category, tags) VALUES
    (
        'How to reset password',
        'To reset your password: 1) Go to login page, 2) Click "Forgot Password", 3) Enter your email, 4) Check your inbox for reset link',
        'account',
        ARRAY['password', 'reset', 'account']
    );
```

---

## Database Schema

### Main Tables

- **`users`** - WhatsApp user profiles
- **`user_conversations`** - Conversation history (JSONB)
- **`messages`** - Detailed message log
- **`ai_interactions`** - AI performance tracking
- **`knowledge_base`** - FAQs and documentation
- **`feedback`** - User satisfaction ratings
- **`error_logs`** - Error tracking

### Analytics Views

- **`active_users_stats`** - DAU, WAU, MAU
- **`message_stats`** - Daily message volumes
- **`ai_performance_stats`** - Response times, token usage

See [`database-schema.sql`](database-schema.sql) for complete schema.

---

## Deployment Options

### Option 1: Docker Compose (Recommended)

**Pros:** Easy setup, includes all services, production-ready
**Time:** 30 minutes

```bash
docker-compose up -d
```

### Option 2: n8n Cloud

**Pros:** Managed service, instant setup, automatic scaling
**Cons:** Monthly cost ($20+), less control
**Time:** 15 minutes

1. Sign up at [n8n.cloud](https://n8n.cloud)
2. Import workflow
3. Configure credentials
4. Done!

### Option 3: Manual Installation

**Pros:** Full control, custom setup
**Cons:** More complex, requires maintenance
**Time:** 1-2 hours

Follow the [complete deployment guide](DEPLOYMENT.md).

---

## Monitoring & Analytics

### Built-in Analytics

Query your data:

```sql
-- Daily active users
SELECT * FROM active_users_stats;

-- Message volume trends
SELECT * FROM message_stats ORDER BY date DESC LIMIT 7;

-- AI performance
SELECT * FROM ai_performance_stats ORDER BY date DESC LIMIT 7;

-- Top users
SELECT phone_number, COUNT(*) as messages
FROM messages
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY phone_number
ORDER BY messages DESC
LIMIT 10;
```

### Cost Monitoring

Track OpenAI API costs:

```sql
SELECT
    DATE(created_at) as date,
    SUM(tokens_used) as total_tokens,
    SUM(tokens_used) * 0.00000015 as estimated_cost_usd
FROM ai_interactions
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### Health Checks

```bash
# Check n8n status
curl https://your-domain.com/healthz

# Check database
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent -c "SELECT COUNT(*) FROM users;"

# Check logs
docker-compose logs -f n8n
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Webhook not receiving | Check workflow is active, verify token matches |
| No AI response | Verify OpenAI credentials, check API quota |
| Database connection error | Check DB credentials, ensure PostgreSQL is running |
| Voice transcription fails | Verify OpenAI has Whisper access |
| High API costs | Reduce max_tokens, limit history, use gpt-4o-mini |

See [Troubleshooting section in DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting) for detailed solutions.

---

## What's New in v2.0! 🎉

We've added four major enhancements:

### 1. Human Handoff
- Automatically detect when AI can't help
- Transfer to live agents via Slack, Email, or CRM
- Track agent performance and response times
- See **[FEATURES.md#human-handoff](FEATURES.md#1-human-handoff)** for full guide

### 2. Proactive Messaging
- Schedule individual messages or mass broadcasts
- Send order updates, reminders, and notifications
- Campaign management and analytics
- See **[FEATURES.md#proactive-messaging](FEATURES.md#2-proactive-messaging)** for full guide

### 3. Voice Responses
- Convert text responses to audio using OpenAI TTS
- 6 different voice options
- User preferences and automatic mode
- See **[FEATURES.md#voice-responses](FEATURES.md#3-voice-responses)** for full guide

### 4. Video Support
- Receive and analyze video messages
- AI-powered frame extraction and analysis
- Automatic content recognition
- See **[FEATURES.md#video-support](FEATURES.md#4-video-support)** for full guide

📖 **[Read the complete Enhanced Features Guide →](FEATURES.md)**

---

## Roadmap

### Recently Completed ✅

- [x] **Human handoff** - Transfer to live agent
- [x] **Voice replies** - Send audio responses
- [x] **Video support** - Handle video messages
- [x] **Scheduled messages** - Proactive notifications

### Planned Features

- [ ] **Multi-language support** - Auto-translate conversations
- [ ] **Sentiment analysis** - Real-time mood detection
- [ ] **Interactive buttons** - WhatsApp button templates
- [ ] **CRM integration** - Sync with Salesforce, HubSpot
- [ ] **A/B testing** - Optimize response strategies
- [ ] **Admin dashboard** - Web UI for monitoring
- [ ] **Auto-categorization** - Tag conversations by topic
- [ ] **Smart routing** - Route by product/department

### Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## Cost Estimation

### Monthly Costs (1000 conversations)

| Service | Cost | Notes |
|---------|------|-------|
| **WhatsApp Business API** | $5-30 | Conversation-based pricing |
| **OpenAI API** | $10-50 | Depends on usage, gpt-4o-mini cheaper |
| **n8n** | $0-50 | Free if self-hosted, $20+ for cloud |
| **VPS/Hosting** | $10-50 | For self-hosting |
| **Database** | $0-20 | Included in VPS or separate |
| **Vector DB** | $0-70 | Free if Qdrant self-hosted, Pinecone $70 |
| **Total** | **$25-270** | Highly variable by usage |

**Cost-saving tips:**
- Use `gpt-4o-mini` (10x cheaper than gpt-4)
- Self-host n8n, PostgreSQL, Qdrant
- Implement caching for common questions
- Limit conversation history to 5-10 messages
- Use simple VPS ($10/month) for moderate traffic

---

## Security

### Best Practices Implemented

✅ HTTPS/SSL encryption
✅ Environment variables for secrets
✅ Webhook verification token
✅ Database password encryption
✅ Rate limiting
✅ Input validation
✅ Error handling without exposing internals
✅ Regular security updates

### Additional Recommendations

- Use firewall (UFW, iptables)
- Regular backups (automated)
- Monitor logs for suspicious activity
- Rotate credentials periodically
- Use permanent tokens (not temporary)
- Implement 2FA for n8n access

---

## Tech Stack

- **n8n** - Workflow automation
- **WhatsApp Business Cloud API** - Messaging platform
- **OpenAI GPT-4** - Language model
- **OpenAI Whisper** - Speech-to-text
- **PostgreSQL** - Primary database
- **Redis** - Caching and sessions
- **Docker** - Containerization
- **Nginx** - Reverse proxy
- **Let's Encrypt** - SSL certificates

---

## Resources

### Official Documentation

- [n8n Documentation](https://docs.n8n.io)
- [WhatsApp Business API Docs](https://developers.facebook.com/docs/whatsapp)
- [OpenAI API Docs](https://platform.openai.com/docs)

### Community & Support

- [n8n Community Forum](https://community.n8n.io)
- [WhatsApp Business API Support](https://developers.facebook.com/support/whatsapp)
- [OpenAI Community](https://community.openai.com)

### Tutorials & Guides

- [Building Your First WhatsApp Chatbot](https://n8n.io/workflows/2465-building-your-first-whatsapp-chatbot/)
- [AI-Powered WhatsApp Chatbot](https://n8n.io/workflows/3586-ai-powered-whatsapp-chatbot-for-text-voice-images-and-pdfs-with-memory/)
- [Building Custom WhatsApp AI Agents](https://www.bitcot.com/building-custom-whatsapp-ai-agents-using-n8n-and-openai/)

---

## License

This project is open source and available under the [MIT License](LICENSE).

---

## Acknowledgments

Built with:
- [n8n](https://n8n.io) - Fair-code workflow automation
- [OpenAI](https://openai.com) - AI models
- [Meta](https://developers.facebook.com) - WhatsApp Business API

Inspired by n8n community templates and best practices.

---

## Support

### Getting Help

1. Check the [Deployment Guide](DEPLOYMENT.md)
2. Review [Troubleshooting](#troubleshooting)
3. Search [n8n Community Forum](https://community.n8n.io)
4. Open an [issue on GitHub](https://github.com/yourusername/whatsapp-n8n-agent/issues)

### Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/whatsapp-n8n-agent/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/whatsapp-n8n-agent/discussions)
- **Email**: support@yourdomain.com

---

<div align="center">

**Made with ❤️ using n8n**

⭐ **Star this repo** if you find it helpful!

</div>
