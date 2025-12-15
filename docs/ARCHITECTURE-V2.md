# WhatsApp AI Support Agent - Architecture v2.0

**Complete system architecture with all enhanced features**

---

## Table of Contents

1. [Overview](#overview)
2. [High-Level Architecture](#high-level-architecture)
3. [System Components](#system-components)
4. [Data Flow](#data-flow)
5. [Enhanced Features Architecture](#enhanced-features-architecture)
6. [Database Architecture](#database-architecture)
7. [Workflow Architecture](#workflow-architecture)
8. [Integration Architecture](#integration-architecture)
9. [Security Architecture](#security-architecture)
10. [Scalability & Performance](#scalability--performance)
11. [Deployment Architectures](#deployment-architectures)
12. [Cost Architecture](#cost-architecture)
13. [Monitoring & Observability](#monitoring--observability)

---

## Overview

The WhatsApp AI Support Agent v2.0 is a comprehensive, production-ready customer engagement platform built on n8n workflow automation. It provides intelligent, multimodal conversational AI with human escalation, proactive messaging, voice responses, and video support capabilities.

### Core Capabilities

- ✅ **Multimodal AI Conversations** - Text, voice, images, videos, PDFs
- ✅ **Human Handoff System** - Seamless agent escalation
- ✅ **Proactive Messaging** - Scheduled notifications and campaigns
- ✅ **Voice Responses** - Text-to-speech replies
- ✅ **Video Processing** - AI-powered video analysis
- ✅ **Conversation Memory** - Context-aware interactions
- ✅ **RAG Integration** - Knowledge base retrieval
- ✅ **Analytics & Monitoring** - Comprehensive insights

---

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         USER INTERACTION LAYER                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │  WhatsApp   │    │   Slack     │    │    Email    │             │
│  │   Users     │    │   Agents    │    │Notifications│             │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘             │
│         │                   │                   │                    │
└─────────┼───────────────────┼───────────────────┼────────────────────┘
          │                   │                   │
          ▼                   ▼                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      INTEGRATION & API LAYER                          │
├──────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ WhatsApp Business   │  │  Slack API  │  │  SMTP/Email │          │
│  │    Cloud API        │  │             │  │             │          │
│  └──────────┬──────────┘  └──────┬──────┘  └──────┬──────┘          │
│             │                     │                │                 │
│  ┌──────────┴─────────────────────┴────────────────┴──────┐          │
│  │                  Nginx Reverse Proxy                    │          │
│  │                    (SSL Termination)                    │          │
│  └──────────────────────────┬──────────────────────────────┘          │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                     N8N WORKFLOW ENGINE LAYER                         │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                 WORKFLOW 1: Main Support Agent                 │  │
│  ├────────────────────────────────────────────────────────────────┤  │
│  │                                                                │  │
│  │  [Webhook] → [Parser] → [Router] → [Processors] → [Memory]   │  │
│  │      ↓           ↓          ↓           ↓            ↓        │  │
│  │  Verification  Extract   Text/      Transcribe/   Load       │  │
│  │               Message   Audio/     Analyze/     History      │  │
│  │                Data    Image/     Extract                     │  │
│  │                        Video/                                 │  │
│  │                         Doc                                   │  │
│  │                          ↓                                    │  │
│  │                   [Handoff Check] ─→ [Create Handoff] ──┐    │  │
│  │                          │                               │    │  │
│  │                          ↓                               │    │  │
│  │                    [AI Agent RAG] ←─────────────────────┘    │  │
│  │                          │                                    │  │
│  │                          ↓                                    │  │
│  │              [Voice Response Check] → [TTS]                  │  │
│  │                          │              ↓                     │  │
│  │                          ↓              │                     │  │
│  │                  [Save Conversation] ←──┘                    │  │
│  │                          │                                    │  │
│  │                          ↓                                    │  │
│  │                 [Send WhatsApp Reply]                        │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │              WORKFLOW 2: Proactive Messaging                   │  │
│  ├────────────────────────────────────────────────────────────────┤  │
│  │                                                                │  │
│  │  [Schedule Trigger] → [Get Pending Messages] → [Process]     │  │
│  │      (Every 5min)           ↓                      ↓          │  │
│  │                      From Database          Template          │  │
│  │                                             Variables         │  │
│  │                                                  ↓             │  │
│  │                               [Media Check] → [Send]          │  │
│  │                                      ↓            ↓            │  │
│  │                                  With Media   Text Only       │  │
│  │                                      ↓            ↓            │  │
│  │                               [Update Status in DB]           │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │               WORKFLOW 3: Human Handoff (Optional)             │  │
│  ├────────────────────────────────────────────────────────────────┤  │
│  │                                                                │  │
│  │  [Handoff Trigger] → [Find Agent] → [Notify Agent]           │  │
│  │         ↓                 ↓              ↓                     │  │
│  │    From DB          Available      Slack/Email/             │  │
│  │                     Agent           Webhook                   │  │
│  │                       ↓                                       │  │
│  │              [Create Session] → [Route Messages]             │  │
│  │                                      ↓                        │  │
│  │                           Agent ←→ User (via WhatsApp)       │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
└──────────────────────┬───────────────────┬────────────────────────────┘
                       │                   │
                       ▼                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      DATA & STORAGE LAYER                             │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────────┐       │
│  │   PostgreSQL     │  │    Redis     │  │  Qdrant Vector   │       │
│  │                  │  │              │  │     Database     │       │
│  ├──────────────────┤  ├──────────────┤  ├──────────────────┤       │
│  │ • Users          │  │ • Sessions   │  │ • Embeddings     │       │
│  │ • Conversations  │  │ • Cache      │  │ • Knowledge Base │       │
│  │ • Messages       │  │ • Queue      │  │ • Semantic       │       │
│  │ • Handoffs       │  │              │  │   Search         │       │
│  │ • Campaigns      │  │              │  │                  │       │
│  │ • Voice/Video    │  │              │  │                  │       │
│  │ • Analytics      │  │              │  │                  │       │
│  └──────────────────┘  └──────────────┘  └──────────────────┘       │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
           │                        │                       │
           ▼                        ▼                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SERVICES LAYER                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────┐  ┌─────────┐  ┌──────────┐  ┌──────────────────┐    │
│  │  OpenAI    │  │  AWS S3 │  │  Slack   │  │  Email (SMTP)    │    │
│  │            │  │   GCS   │  │          │  │                  │    │
│  ├────────────┤  ├─────────┤  ├──────────┤  ├──────────────────┤    │
│  │ • GPT-4    │  │ Videos  │  │ Handoff  │  │ Notifications    │    │
│  │ • Whisper  │  │ Images  │  │ Alerts   │  │ Alerts           │    │
│  │ • TTS      │  │ Docs    │  │          │  │                  │    │
│  │ • Vision   │  │         │  │          │  │                  │    │
│  └────────────┘  └─────────┘  └──────────┘  └──────────────────┘    │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

---

## System Components

### 1. Message Reception & Validation

**Components:**
- Webhook Receiver (n8n Webhook node)
- Token Verifier
- Message Parser

**Responsibilities:**
- Receive POST requests from WhatsApp Business API
- Validate webhook verification (GET requests)
- Parse incoming message payloads
- Extract message metadata

**Technology:**
- n8n Webhook Trigger node
- Custom JavaScript parsing

### 2. Message Router & Orchestrator

**Components:**
- Type Detector
- Route Dispatcher
- Priority Queue

**Message Types Handled:**
```
├── Text Messages → Direct to AI Agent
├── Audio Messages → Transcription Pipeline
├── Image Messages → Vision Analysis Pipeline
├── Video Messages → Video Processing Pipeline
├── Document Messages → Document Extraction Pipeline
└── Special Types → Location, Contact handlers
```

**Technology:**
- n8n Switch node
- Custom routing logic

### 3. Media Processing Pipeline

#### 3.1 Audio Transcription
**Flow:**
```
Audio Message → Download → OpenAI Whisper API → Transcribed Text
```

**Features:**
- Automatic language detection
- Multi-language support
- Timestamp extraction
- Cost tracking

#### 3.2 Image Analysis
**Flow:**
```
Image Message → Download → GPT-4 Vision → Image Description
```

**Features:**
- Object detection
- Text extraction (OCR)
- Scene understanding
- Caption integration

#### 3.3 Video Processing
**Flow:**
```
Video Message → Download → Store (S3/GCS) → Extract Frames →
GPT-4 Vision Analysis → Summary Generation
```

**Features:**
- Frame extraction (configurable interval)
- Multi-frame analysis
- Thumbnail generation
- Metadata extraction

#### 3.4 Document Processing
**Flow:**
```
PDF/Document → Download → Text Extraction → Structured Content
```

**Features:**
- PDF parsing
- OCR for scanned documents
- Table extraction
- Format preservation

### 4. Memory Management System

**Components:**
- Conversation Loader
- Context Builder
- Memory Saver

**Database Schema:**
```sql
user_conversations
├── conversation_history (JSONB)
├── last_message (TEXT)
├── context_window (last N messages)
└── session_metadata
```

**Features:**
- Per-user conversation tracking
- Sliding context window (configurable)
- Session management
- Conversation summarization
- Long-term memory

### 5. AI Agent & RAG System

**Architecture:**
```
User Query
    ↓
Embedding Generation (OpenAI Ada-002)
    ↓
Vector Search (Qdrant) → Top K Results
    ↓
Context Construction
    ↓
    ├── Conversation History
    ├── Retrieved Knowledge
    ├── System Prompt
    └── User Query
    ↓
LLM Generation (GPT-4)
    ↓
Response
```

**Components:**
- Query Embedder
- Vector Search Engine
- Context Builder
- LLM Interface
- Response Formatter

**Knowledge Base:**
- n8n documentation
- Product information
- FAQs
- Support articles
- Custom business knowledge

### 6. Human Handoff System

**Architecture:**
```
Handoff Trigger Detection
    ↓
    ├── User Keywords ("speak to human")
    ├── Negative Sentiment (score < 0.3)
    ├── Unresolved Queries (3+ attempts)
    └── Manual Escalation
    ↓
Find Available Agent
    ↓
    ├── Check Agent Status
    ├── Match Skills
    ├── Check Capacity
    └── Load Balancing
    ↓
Create Handoff Session
    ↓
Notify Agent (Slack/Email/Webhook)
    ↓
Route Conversation to Agent
```

**Database Schema:**
```sql
handoff_requests
├── phone_number
├── reason (user_requested, sentiment_negative, etc.)
├── priority (low, medium, high, urgent)
├── status (pending, assigned, in_progress, resolved)
├── assigned_to (agent_id)
├── conversation_context (JSONB)
└── timestamps

agent_availability
├── agent_id
├── status (online, offline, busy, away)
├── current_chat_count
├── max_concurrent_chats
└── skills (ARRAY)

active_handoffs
├── phone_number
├── agent_id
├── channel (whatsapp, slack, email)
└── is_active
```

**Integration Options:**
- **Slack**: Webhook + Bot Token for two-way messaging
- **Email**: SMTP for notifications
- **Custom Webhook**: CRM/Helpdesk integration

### 7. Proactive Messaging Engine

**Architecture:**
```
Schedule Trigger (Every 5 min)
    ↓
Query Pending Messages
    ↓
    SELECT * FROM scheduled_messages
    WHERE status = 'scheduled'
    AND scheduled_for <= NOW()
    ↓
Process Templates
    ↓
    Replace {{variables}} with values
    ↓
Check Message Type
    ↓
    ├── Text Only → Send Text
    └── With Media → Download → Send Media
    ↓
Update Status → 'sent'
    ↓
Track Delivery (broadcast_history)
```

**Database Schema:**
```sql
scheduled_messages
├── phone_number / phone_numbers[]
├── message_content
├── template_name
├── scheduled_for
├── status (scheduled, sending, sent, failed)
└── metadata (JSONB variables)

message_templates
├── template_name
├── message_content
├── variables (JSONB schema)
└── category

message_campaigns
├── campaign_name
├── target_audience
├── total_recipients
├── messages_sent/delivered/read
└── response_rate
```

**Features:**
- Individual message scheduling
- Bulk broadcasts
- Template management
- Variable substitution
- Campaign tracking
- Delivery analytics

### 8. Voice Response System

**Architecture:**
```
AI Response Generated
    ↓
Check User Preference
    ↓
voice_enabled = true?
    ↓
    YES → Generate Audio
        ↓
        OpenAI TTS API
        ↓
        ├── Voice: alloy/echo/fable/onyx/nova/shimmer
        ├── Speed: 0.25-4.0x
        └── Format: MP3/OGG
        ↓
        Upload to WhatsApp
        ↓
        Send Audio Message
    ↓
    NO → Send Text Message
```

**Database Schema:**
```sql
user_voice_preferences
├── phone_number
├── voice_enabled
├── voice_name
├── voice_speed
└── prefer_voice_response

voice_responses
├── phone_number
├── text_content
├── audio_url
├── audio_duration_seconds
├── cost_usd
└── tts_provider
```

**Cost Optimization:**
- Voice caching for common responses
- Length limits (max 500 chars)
- User opt-in requirement
- Cost tracking per response

### 9. Video Processing System

**Architecture:**
```
Video Message Received
    ↓
Download Video
    ↓
Upload to Cloud Storage (S3/GCS/Azure)
    ↓
Extract Metadata (duration, size, format)
    ↓
Extract Frames (every N seconds)
    ↓
Analyze Each Frame (GPT-4 Vision)
    ↓
Generate Summary
    ↓
Store Analysis Results
    ↓
Generate Response
```

**Database Schema:**
```sql
video_processing
├── phone_number
├── video_url (cloud storage)
├── video_duration_seconds
├── video_size_bytes
├── processing_status
├── frames_extracted
├── analysis_results (JSONB)
└── thumbnail_url
```

**Cloud Storage:**
- AWS S3 (recommended)
- Google Cloud Storage
- Azure Blob Storage

---

## Data Flow

### Complete Message Flow

```
1. User sends WhatsApp message
    ↓
2. WhatsApp Business API → n8n Webhook
    ↓
3. Webhook validates and parses message
    ↓
4. Message Router determines type
    ↓
5. Media Processor (if needed)
    ├── Audio → Transcribe
    ├── Image → Analyze
    ├── Video → Process & Analyze
    └── Document → Extract text
    ↓
6. Load conversation history from PostgreSQL
    ↓
7. Check handoff conditions
    ├── Handoff needed? → Create handoff request
    └── Continue with AI
    ↓
8. AI Agent generates response
    ├── Generate embeddings
    ├── Search knowledge base (RAG)
    ├── Build context
    ├── Generate with LLM
    └── Format response
    ↓
9. Check voice preference
    ├── Voice enabled? → Generate TTS audio
    └── Send text
    ↓
10. Save conversation to database
    ↓
11. Send WhatsApp reply
    ↓
12. Return 200 OK to webhook
```

### Proactive Message Flow

```
1. Schedule trigger fires (every 5 min)
    ↓
2. Query database for pending messages
    ↓
3. For each pending message:
    ├── Process template variables
    ├── Check if media included
    └── Prepare message
    ↓
4. Send via WhatsApp API
    ↓
5. Update status in database
    ↓
6. Track in broadcast_history
```

### Handoff Flow

```
1. Trigger detected
    ↓
2. Create handoff_request in database
    ↓
3. Find available agent
    ├── Check status = 'online'
    ├── Check capacity
    └── Match skills
    ↓
4. Assign to agent
    ↓
5. Send notification (Slack/Email/Webhook)
    ↓
6. Create active_handoff session
    ↓
7. Route messages
    ├── User → Agent
    └── Agent → User
    ↓
8. On resolution:
    ├── Update handoff_request status
    ├── End active_handoff
    └── Return to AI
```

---

## Database Architecture

### Complete Schema Overview

**18 Tables Total:**

#### Core Tables (8)
1. `users` - User profiles
2. `user_conversations` - Conversation history
3. `messages` - Message log
4. `ai_interactions` - AI performance tracking
5. `knowledge_base` - RAG content
6. `analytics` - Usage metrics
7. `feedback` - User ratings
8. `error_logs` - Error tracking

#### Enhanced Feature Tables (10)
9. `handoff_requests` - Handoff tracking
10. `agent_availability` - Agent management
11. `active_handoffs` - Current sessions
12. `scheduled_messages` - Pending messages
13. `message_templates` - Templates
14. `message_campaigns` - Campaign tracking
15. `broadcast_history` - Delivery tracking
16. `user_voice_preferences` - Voice settings
17. `voice_responses` - Voice usage
18. `video_processing` - Video tracking

### Database Relationships

```
users (1) ←→ (M) user_conversations
users (1) ←→ (M) messages
users (1) ←→ (M) ai_interactions
users (1) ←→ (M) handoff_requests
users (1) ←→ (M) scheduled_messages
users (1) ←→ (1) user_voice_preferences
users (1) ←→ (M) voice_responses
users (1) ←→ (M) video_processing

handoff_requests (1) ←→ (M) active_handoffs
agent_availability (1) ←→ (M) active_handoffs
agent_availability (1) ←→ (M) handoff_requests

message_campaigns (1) ←→ (M) broadcast_history
message_templates (1) ←→ (M) message_campaigns
scheduled_messages (1) ←→ (M) broadcast_history
```

### Analytics Views (5)

1. **`active_users_stats`** - DAU, WAU, MAU metrics
2. **`message_stats`** - Daily message volumes
3. **`ai_performance_stats`** - Response times, costs
4. **`handoff_analytics`** - Handoff metrics
5. **`campaign_performance`** - Campaign KPIs

---

## Workflow Architecture

### Workflow 1: Main Support Agent

**Nodes:** 20+ nodes
**Execution Mode:** Synchronous
**Timeout:** 30 seconds

**Node Types:**
- 2x Webhook (GET verification, POST messages)
- 2x Respond to Webhook
- 1x IF (verification check)
- 1x Code (parse message)
- 1x Switch (message router)
- 4x WhatsApp (download media)
- 3x OpenAI (transcribe, vision, chat)
- 3x Code (process content, merge context, prepare response)
- 3x PostgreSQL (load history, save conversation, handoff check)
- 1x Merge (combine processed messages)

**Triggers:**
- Webhook (always active)

### Workflow 2: Proactive Messaging

**Nodes:** 10 nodes
**Execution Mode:** Scheduled
**Frequency:** Every 5 minutes

**Node Types:**
- 1x Schedule Trigger
- 1x PostgreSQL (get pending messages)
- 1x IF (check messages exist)
- 1x Code (process templates)
- 1x IF (check has media)
- 2x WhatsApp (send text, send media)
- 1x Merge
- 1x PostgreSQL (update status sent)
- 1x PostgreSQL (update status failed)

**Triggers:**
- Cron schedule

### Workflow 3: Human Handoff (Optional)

**Nodes:** 8-12 nodes (depends on integration)
**Execution Mode:** Event-driven
**Triggers:** Database webhook or polling

---

## Integration Architecture

### WhatsApp Business API Integration

**Protocol:** HTTPS REST API
**Authentication:** Bearer Token
**Rate Limits:** 80 messages/second

**Endpoints Used:**
- `POST /{phone-number-id}/messages` - Send messages
- `GET /{media-id}` - Download media
- Webhook callback for receiving messages

**Message Types Supported:**
- Text
- Image (JPEG, PNG)
- Audio (AAC, MP4, AMR, OGG)
- Video (MP4, 3GPP)
- Document (PDF, DOC, XLS, etc.)
- Location
- Contacts

### OpenAI API Integration

**Services Used:**
1. **GPT-4o-mini** - Text generation
2. **Whisper** - Audio transcription
3. **TTS** - Text-to-speech
4. **GPT-4 Vision** - Image/video analysis
5. **Ada-002** - Embeddings (for RAG)

**Cost Structure:**
- GPT-4o-mini: $0.15/$0.60 per 1M tokens
- Whisper: $0.006 per minute
- TTS: $15 per 1M characters
- Vision: ~$0.01 per image

### Slack Integration

**Methods:**
1. **Incoming Webhooks** - Send notifications
2. **Bot Token** - Two-way messaging (optional)

**Use Cases:**
- Handoff notifications
- Agent alerts
- System alerts

### Email Integration

**Protocol:** SMTP
**Providers:** Gmail, SendGrid, AWS SES, etc.

**Use Cases:**
- Handoff notifications
- Daily reports
- Error alerts

### Cloud Storage Integration

**Providers:**
- AWS S3
- Google Cloud Storage
- Azure Blob Storage

**Use Cases:**
- Video storage
- Image archival
- Document storage

---

## Security Architecture

### Authentication & Authorization

**Levels:**
1. **WhatsApp Webhook** - Verify token validation
2. **n8n Access** - Basic auth + encryption key
3. **Database** - User/password + SSL
4. **API Keys** - Environment variables, encrypted storage

### Data Protection

**At Rest:**
- Database encryption (optional)
- Encrypted credentials storage
- Secure environment variables

**In Transit:**
- HTTPS/TLS for all API calls
- WhatsApp end-to-end encryption (native)
- SSL for database connections

### Privacy & Compliance

**Data Handling:**
- PII identification and protection
- Configurable data retention
- Right to be forgotten (user deletion)
- GDPR compliance ready

**Audit Trail:**
- All messages logged
- User actions tracked
- System events recorded

---

## Scalability & Performance

### Horizontal Scaling

**n8n Queue Mode:**
```yaml
EXECUTIONS_MODE: queue
QUEUE_BULL_REDIS_HOST: redis
```

**Benefits:**
- Distribute load across workers
- Handle high message volume
- Fault tolerance

### Database Optimization

**Indexes:**
```sql
-- Message lookups
CREATE INDEX idx_messages_phone ON messages(phone_number);
CREATE INDEX idx_messages_created ON messages(created_at DESC);

-- Conversation queries
CREATE INDEX idx_conversations_phone ON user_conversations(phone_number);

-- Handoff queries
CREATE INDEX idx_handoff_status ON handoff_requests(status);
```

**Connection Pooling:**
- PgBouncer for connection management
- Redis for caching frequent queries

### Caching Strategy

**Redis Caching:**
- Session data (5 min TTL)
- Frequent queries (10 min TTL)
- Voice responses (24 hour TTL)

### Rate Limiting

**WhatsApp:**
- 80 messages/second (hard limit)
- Implement queue for bursts

**OpenAI:**
- 3,500 RPM for GPT-4 (tier 1)
- 50 RPM for Whisper

### Performance Targets

**Response Times:**
- Text messages: < 2 seconds
- Voice transcription: < 5 seconds
- Image analysis: < 3 seconds
- Video processing: < 30 seconds

**Availability:**
- Target: 99.9% uptime
- Max downtime: 43 minutes/month

---

## Deployment Architectures

### Development Environment

```
Local Machine
├── Docker Compose
│   ├── n8n (localhost:5678)
│   ├── PostgreSQL
│   └── Redis
├── ngrok (webhook tunnel)
└── Meta test number
```

**Characteristics:**
- Local development
- Quick iteration
- No SSL required
- Limited to 5 test users

### Production - Single Server

```
VPS/Server (4GB RAM, 2 CPU)
├── Docker Compose
│   ├── n8n
│   ├── PostgreSQL
│   ├── Redis
│   ├── Qdrant (optional)
│   └── Nginx (SSL)
├── Let's Encrypt SSL
├── Domain name
└── Automated backups
```

**Characteristics:**
- Cost-effective
- Handles 1000-5000 users
- Single point of failure
- Easy to manage

### Production - High Availability

```
Load Balancer
├── n8n Worker 1 ─┐
├── n8n Worker 2 ─┼─→ Redis Queue
└── n8n Worker 3 ─┘
        │
        ↓
Managed PostgreSQL (Primary + Replica)
Managed Redis (Cluster)
Managed Vector DB (Qdrant Cloud)
AWS S3 (Videos/Media)
```

**Characteristics:**
- High availability
- Horizontal scaling
- Handles 10,000+ users
- Higher cost
- Auto-scaling

### Hybrid - Cloud + Self-Hosted

```
n8n Cloud → WhatsApp API
         → OpenAI API
         ↓
Self-Hosted PostgreSQL
Self-Hosted Qdrant
```

**Characteristics:**
- Managed n8n
- Data stays local
- Balanced cost
- Easy scaling

---

## Cost Architecture

### Monthly Cost Breakdown (1000 conversations)

**Infrastructure:**
- VPS (4GB, 2 CPU): $10-20
- Domain + SSL: $1-2
- Backups storage: $2-5

**n8n:**
- Self-hosted: $0
- n8n Cloud: $20

**WhatsApp:**
- First 1000 free
- $0.005-0.03 per conversation after

**OpenAI:**
- Text (GPT-4o-mini): $5-15
- Voice (Whisper): $2-5
- TTS: $5-10
- Vision: $3-8

**Storage:**
- S3 videos: $1-5
- PostgreSQL: Included in VPS

**Total Range:** $50-150/month (moderate usage)

### Cost Optimization Strategies

1. **Use gpt-4o-mini** instead of gpt-4 (10x cheaper)
2. **Cache voice responses** for common questions
3. **Limit conversation history** to 5-10 messages
4. **Implement rate limiting** per user
5. **Use self-hosted** Qdrant vs Pinecone ($70 saved)
6. **Batch processing** for non-urgent tasks
7. **Compress media** before storage

---

## Monitoring & Observability

### Metrics Collection

**Application Metrics:**
```sql
-- Message volume
SELECT DATE(created_at), COUNT(*) FROM messages
GROUP BY DATE(created_at);

-- Response times
SELECT AVG(response_time_ms) FROM ai_interactions;

-- Error rates
SELECT COUNT(*) FROM error_logs
WHERE created_at > NOW() - INTERVAL '24 hours';
```

**System Metrics:**
```bash
# Container stats
docker stats

# Database performance
SELECT * FROM pg_stat_activity;

# Disk usage
df -h
```

### Alerting

**Critical Alerts:**
- Webhook down
- Database connection lost
- High error rate (>5%)
- Disk space low (<10%)

**Warning Alerts:**
- High response time (>5s avg)
- High cost rate
- Queue backup
- Low agent availability

### Logging

**Log Levels:**
- ERROR: System failures
- WARN: Performance issues
- INFO: Normal operations
- DEBUG: Detailed tracing

**Log Destinations:**
- n8n execution logs
- PostgreSQL error_logs table
- System logs (/var/log)
- External (Sentry, optional)

---

## Technology Stack

### Core Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Workflow Engine** | n8n | Orchestration |
| **Database** | PostgreSQL 15 | Primary data store |
| **Cache** | Redis 7 | Session & queue |
| **Vector DB** | Qdrant | RAG / embeddings |
| **Reverse Proxy** | Nginx | SSL & routing |
| **Containers** | Docker + Compose | Deployment |

### External Services

| Service | Provider | Purpose |
|---------|----------|---------|
| **Messaging** | WhatsApp Business Cloud | User communication |
| **LLM** | OpenAI GPT-4 | AI responses |
| **Transcription** | OpenAI Whisper | Voice-to-text |
| **TTS** | OpenAI TTS | Text-to-speech |
| **Vision** | GPT-4 Vision | Image/video analysis |
| **Storage** | AWS S3 / GCS | Media storage |
| **Notifications** | Slack / Email | Agent alerts |

### Development Stack

| Tool | Purpose |
|------|---------|
| **Git** | Version control |
| **VS Code** | Development |
| **PostgreSQL Client** | Database admin |
| **Postman** | API testing |
| **ngrok** | Local webhook testing |

---

## Summary

The WhatsApp AI Support Agent v2.0 architecture is designed for:

✅ **Scalability** - Handle growth from 10 to 10,000+ users
✅ **Reliability** - 99.9% uptime with proper deployment
✅ **Flexibility** - Modular design, easy to extend
✅ **Cost-Effective** - Optimize costs at every layer
✅ **Production-Ready** - Security, monitoring, backups included
✅ **Feature-Rich** - All modern conversational AI capabilities

The architecture supports multiple deployment models from single-server to high-availability clusters, making it suitable for startups to enterprises.

For detailed deployment instructions, see DEPLOYMENT-V2.md(DEPLOYMENT-V2.md).
For component-specific guides, see FEATURES.md(FEATURES.md).
