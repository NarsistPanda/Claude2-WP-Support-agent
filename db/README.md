# Database Schema Documentation

Complete database schema documentation for the WhatsApp AI Support Agent v2.0.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Database Architecture](#database-architecture)
3. [Schema Files](#schema-files)
4. [Core Tables (Base Schema)](#core-tables-base-schema)
5. [Enhanced Tables (v2.0 Features)](#enhanced-tables-v20-features)
6. [Database Views](#database-views)
7. [Functions and Triggers](#functions-and-triggers)
8. [Entity Relationship Diagrams](#entity-relationship-diagrams)
9. [Deployment Instructions](#deployment-instructions)
10. [Data Migration](#data-migration)
11. [Performance Optimization](#performance-optimization)
12. [Backup and Restore](#backup-and-restore)
13. [Common Queries](#common-queries)
14. [Troubleshooting](#troubleshooting)

---

## Overview

The WhatsApp AI Support Agent uses a PostgreSQL database with the **pgvector** extension for AI-powered features. The database consists of **18 tables** organized into two schema files:

- **Base Schema** (8 tables): Core functionality for messaging, user management, and analytics
- **Enhanced Schema** (10 tables): v2.0 features including human handoff, proactive messaging, voice responses, and video support

**Total Tables:** 18
**Database Engine:** PostgreSQL 15+ with pgvector extension
**Vector Dimension:** 1536 (OpenAI embeddings)
**Estimated Size:** ~100MB-10GB (depends on message volume and media storage)

---

## Database Architecture

### Two-Schema Approach

The database uses a modular two-schema approach for flexibility:

1. **database-schema.sql** - Base functionality (required)
   - User management
   - Conversation history
   - AI interactions
   - Analytics and reporting

2. **database-schema-enhanced.sql** - Enhanced features (optional)
   - Human handoff system
   - Proactive messaging campaigns
   - Voice preferences and responses
   - Video processing

### Technology Stack

- **PostgreSQL 15+** - Primary database
- **pgvector extension** - Vector embeddings for RAG (Retrieval Augmented Generation)
- **JSONB** - Flexible data storage for conversation history and metadata
- **UUID** - Primary keys for distributed systems
- **Triggers** - Automatic timestamp updates

---

## Schema Files

### database-schema.sql

**Purpose:** Core functionality
**Tables:** 8
**Size:** ~500 lines
**Required:** Yes

Tables included:
- users
- user_conversations
- messages
- ai_interactions
- knowledge_base
- analytics
- feedback
- error_logs

### database-schema-enhanced.sql

**Purpose:** v2.0 enhanced features
**Tables:** 10
**Size:** ~600 lines
**Required:** No (optional features)

Tables included:
- handoff_requests
- agent_availability
- active_handoffs
- scheduled_messages
- message_templates
- message_campaigns
- broadcast_history
- user_voice_preferences
- voice_responses
- video_processing

---

## Core Tables (Base Schema)

### 1. users

**Purpose:** Store user profile information and metadata

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique user identifier |
| phone_number | VARCHAR(20) | UNIQUE NOT NULL | WhatsApp phone number (E.164 format) |
| contact_name | VARCHAR(255) | | User's display name |
| language_preference | VARCHAR(10) | DEFAULT 'en' | ISO 639-1 language code |
| timezone | VARCHAR(50) | DEFAULT 'UTC' | User's timezone |
| total_messages | INTEGER | DEFAULT 0 | Total message count |
| last_message_at | TIMESTAMP | DEFAULT NOW() | Last interaction timestamp |
| is_active | BOOLEAN | DEFAULT TRUE | Active/inactive status |
| metadata | JSONB | | Additional user data |
| created_at | TIMESTAMP | DEFAULT NOW() | Account creation time |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update time |

**Indexes:**
- Primary key on `id`
- Unique index on `phone_number`
- Index on `last_message_at` for recent users queries
- GIN index on `metadata` for JSONB queries

**Sample Data:**
```sql
INSERT INTO users (phone_number, contact_name, language_preference, timezone)
VALUES ('+1234567890', 'John Doe', 'en', 'America/New_York');
```

---

### 2. user_conversations

**Purpose:** Store complete conversation history with context

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Conversation identifier |
| phone_number | VARCHAR(20) | NOT NULL | Reference to user |
| conversation_history | JSONB | DEFAULT '[]'::jsonb | Array of messages |
| context | JSONB | | Conversation context/state |
| status | VARCHAR(20) | DEFAULT 'active' | active/archived/transferred |
| sentiment_score | DECIMAL(3,2) | | Overall sentiment (-1 to 1) |
| created_at | TIMESTAMP | DEFAULT NOW() | Conversation start |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last message |

**Foreign Keys:**
- `phone_number` → `users(phone_number)` ON DELETE CASCADE

**JSONB Structure - conversation_history:**
```json
[
  {
    "role": "user",
    "content": "Hello, I need help",
    "timestamp": "2025-12-15T10:30:00Z",
    "message_id": "wamid.xxx"
  },
  {
    "role": "assistant",
    "content": "Hello! How can I help you today?",
    "timestamp": "2025-12-15T10:30:05Z"
  }
]
```

**Indexes:**
- GIN index on `conversation_history` for fast JSONB queries
- Index on `phone_number` for user lookup
- Index on `updated_at` for recent conversations

---

### 3. messages

**Purpose:** Individual message records with metadata

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Message identifier |
| phone_number | VARCHAR(20) | NOT NULL | User reference |
| message_id | VARCHAR(255) | UNIQUE | WhatsApp message ID |
| direction | VARCHAR(10) | NOT NULL | inbound/outbound |
| message_type | VARCHAR(20) | DEFAULT 'text' | text/image/video/audio/document |
| content | TEXT | | Message text content |
| media_url | TEXT | | Media file URL |
| media_mime_type | VARCHAR(100) | | MIME type of media |
| status | VARCHAR(20) | DEFAULT 'sent' | sent/delivered/read/failed |
| error_message | TEXT | | Error details if failed |
| metadata | JSONB | | Additional message data |
| timestamp | TIMESTAMP | DEFAULT NOW() | Message timestamp |

**Foreign Keys:**
- `phone_number` → `users(phone_number)` ON DELETE CASCADE

**Indexes:**
- Unique index on `message_id`
- Index on `phone_number, timestamp` for user message history
- Index on `direction, status` for analytics
- Index on `message_type` for media queries

**Message Types:**
- `text` - Plain text messages
- `image` - Images (JPEG, PNG, WebP)
- `video` - Video files (MP4, 3GP)
- `audio` - Voice messages (OGG, AAC, AMR)
- `document` - Documents (PDF, DOCX, etc.)
- `location` - Location sharing
- `contacts` - Contact cards
- `interactive` - Buttons/lists

---

### 4. ai_interactions

**Purpose:** Track AI model usage and performance

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Interaction identifier |
| phone_number | VARCHAR(20) | NOT NULL | User reference |
| message_id | VARCHAR(255) | | Related WhatsApp message |
| model_used | VARCHAR(50) | DEFAULT 'gpt-4o-mini' | AI model identifier |
| prompt_tokens | INTEGER | | Input tokens used |
| completion_tokens | INTEGER | | Output tokens used |
| total_tokens | INTEGER | | Total tokens (prompt + completion) |
| response_time_ms | INTEGER | | Response time in milliseconds |
| success | BOOLEAN | DEFAULT TRUE | Success/failure status |
| error_message | TEXT | | Error details |
| cost_usd | DECIMAL(10,6) | | Estimated cost in USD |
| timestamp | TIMESTAMP | DEFAULT NOW() | Interaction timestamp |

**Foreign Keys:**
- `phone_number` → `users(phone_number)` ON DELETE CASCADE

**Indexes:**
- Index on `phone_number` for user AI usage
- Index on `timestamp` for time-based analytics
- Index on `model_used` for model comparison
- Index on `success` for error tracking

**Cost Calculation:**
```sql
-- Example: gpt-4o-mini pricing
UPDATE ai_interactions
SET cost_usd = (prompt_tokens * 0.00000015) + (completion_tokens * 0.0000006)
WHERE model_used = 'gpt-4o-mini';
```

---

### 5. knowledge_base

**Purpose:** Store knowledge articles with vector embeddings for RAG

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Article identifier |
| title | VARCHAR(500) | | Article title |
| content | TEXT | NOT NULL | Article content |
| embedding | VECTOR(1536) | | OpenAI embedding vector |
| category | VARCHAR(100) | | Article category |
| tags | TEXT[] | | Searchable tags |
| source | VARCHAR(255) | | Content source |
| url | TEXT | | Reference URL |
| metadata | JSONB | | Additional metadata |
| is_active | BOOLEAN | DEFAULT TRUE | Active/archived status |
| view_count | INTEGER | DEFAULT 0 | Usage counter |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |

**Indexes:**
- Index on `category` for filtering
- GIN index on `tags` for array search
- Vector index on `embedding` for similarity search:
  ```sql
  CREATE INDEX idx_knowledge_base_embedding ON knowledge_base
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
  ```

**Vector Search Example:**
```sql
-- Find top 5 most similar articles
SELECT id, title, content,
       1 - (embedding <=> '[0.1, 0.2, ...]'::vector) AS similarity
FROM knowledge_base
WHERE is_active = TRUE
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector
LIMIT 5;
```

---

### 6. analytics

**Purpose:** Store analytics events for reporting

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Event identifier |
| phone_number | VARCHAR(20) | | User reference (nullable) |
| event_type | VARCHAR(50) | NOT NULL | Event category |
| event_data | JSONB | | Event details |
| timestamp | TIMESTAMP | DEFAULT NOW() | Event timestamp |

**Foreign Keys:**
- `phone_number` → `users(phone_number)` ON DELETE SET NULL

**Indexes:**
- Index on `event_type, timestamp` for analytics queries
- GIN index on `event_data` for JSONB queries
- Index on `phone_number` for user analytics

**Event Types:**
- `message_sent` - Outbound message
- `message_received` - Inbound message
- `conversation_started` - New conversation
- `conversation_ended` - Conversation closed
- `handoff_requested` - Transfer to human
- `voice_message_sent` - Voice response sent
- `video_processed` - Video analysis completed
- `knowledge_base_query` - RAG search performed

**Sample Analytics Query:**
```sql
-- Daily active users
SELECT DATE(timestamp) as date, COUNT(DISTINCT phone_number) as dau
FROM analytics
WHERE event_type = 'message_received'
  AND timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

---

### 7. feedback

**Purpose:** Collect user feedback and ratings

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Feedback identifier |
| phone_number | VARCHAR(20) | NOT NULL | User reference |
| message_id | VARCHAR(255) | | Related message |
| rating | INTEGER | CHECK (1-5) | Star rating (1-5) |
| feedback_text | TEXT | | Optional feedback text |
| feedback_type | VARCHAR(50) | | bug/suggestion/compliment |
| sentiment | VARCHAR(20) | | positive/negative/neutral |
| is_resolved | BOOLEAN | DEFAULT FALSE | Resolution status |
| created_at | TIMESTAMP | DEFAULT NOW() | Feedback timestamp |

**Foreign Keys:**
- `phone_number` → `users(phone_number)` ON DELETE CASCADE

**Indexes:**
- Index on `rating` for satisfaction metrics
- Index on `sentiment` for sentiment analysis
- Index on `created_at` for time-based reports
- Index on `is_resolved` for support tracking

**CSAT Calculation:**
```sql
-- Customer Satisfaction Score (% of 4-5 star ratings)
SELECT
  COUNT(CASE WHEN rating >= 4 THEN 1 END)::FLOAT / COUNT(*)::FLOAT * 100 AS csat_score
FROM feedback
WHERE created_at > NOW() - INTERVAL '30 days';
```

---

### 8. error_logs

**Purpose:** Centralized error logging and debugging

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Error identifier |
| phone_number | VARCHAR(20) | | Related user (nullable) |
| error_type | VARCHAR(100) | NOT NULL | Error category |
| error_message | TEXT | NOT NULL | Error description |
| stack_trace | TEXT | | Full stack trace |
| severity | VARCHAR(20) | DEFAULT 'error' | info/warning/error/critical |
| context | JSONB | | Additional context |
| is_resolved | BOOLEAN | DEFAULT FALSE | Resolution status |
| resolved_at | TIMESTAMP | | Resolution timestamp |
| timestamp | TIMESTAMP | DEFAULT NOW() | Error timestamp |

**Indexes:**
- Index on `error_type, timestamp` for error tracking
- Index on `severity` for critical error monitoring
- Index on `is_resolved` for unresolved errors
- GIN index on `context` for JSONB queries

**Error Types:**
- `whatsapp_api_error` - WhatsApp API failures
- `openai_api_error` - OpenAI API failures
- `database_error` - Database operation errors
- `validation_error` - Input validation failures
- `media_processing_error` - Media upload/download errors
- `network_error` - Network connectivity issues

---

## Enhanced Tables (v2.0 Features)

### 9. handoff_requests

**Purpose:** Manage AI-to-human agent handoffs

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Request identifier |
| phone_number | VARCHAR(20) | NOT NULL | User reference |
| reason | VARCHAR(50) | | Handoff reason code |
| priority | VARCHAR(20) | DEFAULT 'medium' | low/medium/high/urgent |
| status | VARCHAR(20) | DEFAULT 'pending' | pending/assigned/completed/cancelled |
| assigned_to | VARCHAR(255) | | Agent identifier |
| conversation_context | JSONB | | Full conversation history |
| sentiment_score | DECIMAL(3,2) | | User sentiment (-1 to 1) |
| wait_time_seconds | INTEGER | | Time waiting for agent |
| resolution_notes | TEXT | | Agent resolution notes |
| created_at | TIMESTAMP | DEFAULT NOW() | Request timestamp |
| assigned_at | TIMESTAMP | | Assignment timestamp |
| completed_at | TIMESTAMP | | Completion timestamp |

**Foreign Keys:**
- `phone_number` → `users(phone_number)` ON DELETE CASCADE

**Indexes:**
- Index on `status, priority` for assignment queue
- Index on `assigned_to` for agent workload
- Index on `created_at` for SLA monitoring

**Handoff Reasons:**
- `user_requested` - User explicitly asked for human
- `sentiment_negative` - Negative sentiment detected
- `unable_to_help` - AI couldn't resolve issue
- `complex_query` - Query too complex for AI
- `escalation` - Issue requires escalation

**SLA Monitoring:**
```sql
-- Average wait time by priority
SELECT priority,
       AVG(wait_time_seconds) as avg_wait_seconds,
       MAX(wait_time_seconds) as max_wait_seconds
FROM handoff_requests
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY priority;
```

---

### 10. agent_availability

**Purpose:** Track human agent availability and capacity

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| agent_id | VARCHAR(255) | UNIQUE NOT NULL | Agent identifier |
| agent_name | VARCHAR(255) | NOT NULL | Agent display name |
| email | VARCHAR(255) | | Agent email |
| slack_user_id | VARCHAR(100) | | Slack integration ID |
| status | VARCHAR(20) | DEFAULT 'offline' | online/busy/offline/away |
| max_concurrent_chats | INTEGER | DEFAULT 5 | Maximum simultaneous chats |
| current_chat_count | INTEGER | DEFAULT 0 | Current active chats |
| skills | TEXT[] | | Agent skill tags |
| languages | TEXT[] | | Supported languages |
| last_seen_at | TIMESTAMP | DEFAULT NOW() | Last activity timestamp |
| created_at | TIMESTAMP | DEFAULT NOW() | Agent creation |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |

**Indexes:**
- Unique index on `agent_id`
- Index on `status` for available agents
- GIN index on `skills` for skill matching
- GIN index on `languages` for language routing

**Agent Assignment Logic:**
```sql
-- Find available agent with matching skills
SELECT agent_id, agent_name, current_chat_count
FROM agent_availability
WHERE status = 'online'
  AND current_chat_count < max_concurrent_chats
  AND 'billing' = ANY(skills)
ORDER BY current_chat_count ASC
LIMIT 1;
```

---

### 11. active_handoffs

**Purpose:** Track currently active human-agent conversations

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Handoff identifier |
| handoff_request_id | UUID | NOT NULL | Original request |
| phone_number | VARCHAR(20) | NOT NULL | User reference |
| agent_id | VARCHAR(255) | NOT NULL | Assigned agent |
| channel | VARCHAR(50) | DEFAULT 'whatsapp' | Communication channel |
| slack_channel_id | VARCHAR(100) | | Slack channel ID |
| slack_thread_ts | VARCHAR(50) | | Slack thread timestamp |
| conversation_messages | JSONB | DEFAULT '[]'::jsonb | Chat messages |
| status | VARCHAR(20) | DEFAULT 'active' | active/resolved/transferred |
| started_at | TIMESTAMP | DEFAULT NOW() | Handoff start time |
| last_message_at | TIMESTAMP | DEFAULT NOW() | Last message time |

**Foreign Keys:**
- `handoff_request_id` → `handoff_requests(id)` ON DELETE CASCADE
- `phone_number` → `users(phone_number)` ON DELETE CASCADE
- `agent_id` → `agent_availability(agent_id)` ON DELETE CASCADE

**Indexes:**
- Index on `agent_id` for agent's active chats
- Index on `status` for active handoffs
- Index on `phone_number` for user lookup

---

### 12. scheduled_messages

**Purpose:** Schedule future messages and campaigns

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Schedule identifier |
| phone_numbers | TEXT[] | | Target recipients |
| message_type | VARCHAR(50) | NOT NULL | reminder/notification/campaign |
| template_name | VARCHAR(255) | | Template reference |
| message_content | TEXT | | Message text |
| media_url | TEXT | | Optional media |
| scheduled_for | TIMESTAMP | NOT NULL | Scheduled send time |
| timezone | VARCHAR(50) | DEFAULT 'UTC' | Recipient timezone |
| status | VARCHAR(20) | DEFAULT 'scheduled' | scheduled/sent/failed/cancelled |
| send_between_hours | VARCHAR(20) | | e.g., "09:00-18:00" |
| respect_quiet_hours | BOOLEAN | DEFAULT TRUE | Honor quiet hours |
| retry_count | INTEGER | DEFAULT 0 | Retry attempts |
| sent_at | TIMESTAMP | | Actual send time |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |

**Indexes:**
- Index on `scheduled_for, status` for job processing
- Index on `status` for monitoring
- GIN index on `phone_numbers` for recipient lookup

**Quiet Hours Logic:**
```sql
-- Check if current time is within send window
SELECT *
FROM scheduled_messages
WHERE scheduled_for <= NOW()
  AND status = 'scheduled'
  AND (
    respect_quiet_hours = FALSE
    OR EXTRACT(HOUR FROM NOW() AT TIME ZONE timezone)::INTEGER
       BETWEEN 9 AND 18
  );
```

---

### 13. message_templates

**Purpose:** Reusable message templates with variables

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Template identifier |
| template_name | VARCHAR(255) | UNIQUE NOT NULL | Template name |
| template_category | VARCHAR(100) | | Category/group |
| message_content | TEXT | NOT NULL | Template text with {{vars}} |
| variables | JSONB | | Variable definitions |
| language | VARCHAR(10) | DEFAULT 'en' | Template language |
| is_active | BOOLEAN | DEFAULT TRUE | Active status |
| usage_count | INTEGER | DEFAULT 0 | Usage counter |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |

**Indexes:**
- Unique index on `template_name`
- Index on `template_category` for filtering
- Index on `language` for multi-language support

**Template Example:**
```json
{
  "template_name": "appointment_reminder",
  "message_content": "Hi {{name}}, this is a reminder for your appointment on {{date}} at {{time}}.",
  "variables": {
    "name": "string",
    "date": "date",
    "time": "time"
  }
}
```

---

### 14. message_campaigns

**Purpose:** Manage broadcast campaigns

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Campaign identifier |
| campaign_name | VARCHAR(255) | NOT NULL | Campaign name |
| description | TEXT | | Campaign description |
| target_audience | JSONB | | Targeting criteria |
| template_name | VARCHAR(255) | | Template reference |
| schedule_type | VARCHAR(20) | DEFAULT 'immediate' | immediate/scheduled/recurring |
| scheduled_for | TIMESTAMP | | Start time |
| status | VARCHAR(20) | DEFAULT 'draft' | draft/active/completed/cancelled |
| total_recipients | INTEGER | DEFAULT 0 | Total target count |
| messages_sent | INTEGER | DEFAULT 0 | Successfully sent |
| messages_failed | INTEGER | DEFAULT 0 | Failed sends |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |
| started_at | TIMESTAMP | | Campaign start |
| completed_at | TIMESTAMP | | Campaign completion |

**Indexes:**
- Index on `status` for campaign monitoring
- Index on `scheduled_for` for scheduling
- GIN index on `target_audience` for JSONB queries

**Target Audience Example:**
```json
{
  "filters": {
    "language": ["en", "es"],
    "last_message_within_days": 30,
    "total_messages_greater_than": 5,
    "tags": ["premium", "active"]
  },
  "exclude": {
    "opted_out": true
  }
}
```

---

### 15. broadcast_history

**Purpose:** Track individual broadcast message sends

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Broadcast identifier |
| campaign_id | UUID | | Related campaign |
| phone_number | VARCHAR(20) | NOT NULL | Recipient |
| message_id | VARCHAR(255) | | WhatsApp message ID |
| template_name | VARCHAR(255) | | Template used |
| message_content | TEXT | | Actual message sent |
| status | VARCHAR(20) | DEFAULT 'pending' | pending/sent/delivered/read/failed |
| error_message | TEXT | | Error details |
| sent_at | TIMESTAMP | | Send timestamp |
| delivered_at | TIMESTAMP | | Delivery timestamp |
| read_at | TIMESTAMP | | Read timestamp |

**Foreign Keys:**
- `campaign_id` → `message_campaigns(id)` ON DELETE SET NULL
- `phone_number` → `users(phone_number)` ON DELETE CASCADE

**Indexes:**
- Index on `campaign_id` for campaign metrics
- Index on `phone_number` for user history
- Index on `status` for delivery tracking

---

### 16. user_voice_preferences

**Purpose:** Store user preferences for voice responses

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| phone_number | VARCHAR(20) | UNIQUE NOT NULL | User reference |
| voice_enabled | BOOLEAN | DEFAULT FALSE | Voice feature enabled |
| voice_name | VARCHAR(50) | DEFAULT 'alloy' | TTS voice selection |
| voice_speed | DECIMAL(3,2) | DEFAULT 1.0 | Playback speed (0.5-2.0) |
| language | VARCHAR(10) | DEFAULT 'en' | Voice language |
| created_at | TIMESTAMP | DEFAULT NOW() | Preference creation |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |

**Foreign Keys:**
- `phone_number` → `users(phone_number)` ON DELETE CASCADE

**Indexes:**
- Unique index on `phone_number`
- Index on `voice_enabled` for feature usage

**Available Voices:**
- `alloy` - Neutral, balanced
- `echo` - Male, clear
- `fable` - British, expressive
- `onyx` - Deep, authoritative
- `nova` - Friendly, warm
- `shimmer` - Soft, gentle

---

### 17. voice_responses

**Purpose:** Track voice message generation and delivery

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Response identifier |
| phone_number | VARCHAR(20) | NOT NULL | User reference |
| text_content | TEXT | NOT NULL | Original text |
| audio_url | TEXT | | Generated audio URL |
| audio_duration_seconds | INTEGER | | Audio length |
| voice_name | VARCHAR(50) | DEFAULT 'alloy' | Voice used |
| tts_provider | VARCHAR(50) | DEFAULT 'openai' | TTS service |
| status | VARCHAR(20) | DEFAULT 'pending' | pending/generated/sent/failed |
| cost_usd | DECIMAL(10,4) | | Generation cost |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |

**Foreign Keys:**
- `phone_number` → `users(phone_number)` ON DELETE CASCADE

**Indexes:**
- Index on `phone_number` for user history
- Index on `status` for processing queue
- Index on `created_at` for cost tracking

**Cost Calculation:**
```sql
-- OpenAI TTS pricing: $0.015 per 1K characters
UPDATE voice_responses
SET cost_usd = LENGTH(text_content) * 0.000015
WHERE tts_provider = 'openai' AND cost_usd IS NULL;
```

---

### 18. video_processing

**Purpose:** Track video uploads and AI analysis

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Processing identifier |
| phone_number | VARCHAR(20) | NOT NULL | User reference |
| message_id | VARCHAR(255) | | WhatsApp message ID |
| video_url | TEXT | | Original video URL |
| storage_url | TEXT | | Cloud storage URL |
| thumbnail_url | TEXT | | Generated thumbnail |
| video_duration_seconds | INTEGER | | Video length |
| file_size_bytes | BIGINT | | File size |
| processing_status | VARCHAR(20) | DEFAULT 'pending' | pending/processing/completed/failed |
| analysis_results | JSONB | | AI analysis data |
| transcription | TEXT | | Video transcription |
| cost_usd | DECIMAL(10,4) | | Processing cost |
| created_at | TIMESTAMP | DEFAULT NOW() | Upload time |
| processed_at | TIMESTAMP | | Processing completion |

**Foreign Keys:**
- `phone_number` → `users(phone_number)` ON DELETE CASCADE

**Indexes:**
- Index on `phone_number` for user videos
- Index on `processing_status` for job queue
- GIN index on `analysis_results` for JSONB queries

**Analysis Results Example:**
```json
{
  "labels": ["product", "demonstration", "unboxing"],
  "objects_detected": ["smartphone", "box", "hands"],
  "text_detected": ["iPhone 15 Pro", "Apple"],
  "sentiment": "positive",
  "key_moments": [
    {"timestamp": 5, "description": "Product reveal"},
    {"timestamp": 15, "description": "Feature demonstration"}
  ]
}
```

---

## Database Views

### active_users_stats

**Purpose:** Real-time user activity statistics

```sql
CREATE OR REPLACE VIEW active_users_stats AS
SELECT
    COUNT(DISTINCT phone_number) as total_users,
    COUNT(DISTINCT CASE
        WHEN last_message_at > NOW() - INTERVAL '24 hours'
        THEN phone_number
    END) as daily_active_users,
    COUNT(DISTINCT CASE
        WHEN last_message_at > NOW() - INTERVAL '7 days'
        THEN phone_number
    END) as weekly_active_users,
    COUNT(DISTINCT CASE
        WHEN last_message_at > NOW() - INTERVAL '30 days'
        THEN phone_number
    END) as monthly_active_users
FROM users
WHERE is_active = TRUE;
```

---

### message_stats

**Purpose:** Message volume and type analytics

```sql
CREATE OR REPLACE VIEW message_stats AS
SELECT
    DATE(timestamp) as date,
    direction,
    message_type,
    status,
    COUNT(*) as message_count,
    COUNT(DISTINCT phone_number) as unique_users
FROM messages
WHERE timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp), direction, message_type, status
ORDER BY date DESC, message_count DESC;
```

---

### ai_performance_stats

**Purpose:** AI model performance metrics

```sql
CREATE OR REPLACE VIEW ai_performance_stats AS
SELECT
    model_used,
    DATE(timestamp) as date,
    COUNT(*) as total_interactions,
    AVG(response_time_ms) as avg_response_time_ms,
    AVG(total_tokens) as avg_tokens,
    SUM(cost_usd) as total_cost_usd,
    SUM(CASE WHEN success = TRUE THEN 1 ELSE 0 END)::FLOAT / COUNT(*)::FLOAT * 100 as success_rate
FROM ai_interactions
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY model_used, DATE(timestamp)
ORDER BY date DESC, total_interactions DESC;
```

---

## Functions and Triggers

### update_updated_at_column()

**Purpose:** Automatically update `updated_at` timestamps

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at column
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

---

### cleanup_old_conversations()

**Purpose:** Archive old inactive conversations

```sql
CREATE OR REPLACE FUNCTION cleanup_old_conversations(days_old INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    rows_archived INTEGER;
BEGIN
    UPDATE user_conversations
    SET status = 'archived'
    WHERE updated_at < NOW() - (days_old || ' days')::INTERVAL
      AND status = 'active';

    GET DIAGNOSTICS rows_archived = ROW_COUNT;
    RETURN rows_archived;
END;
$$ LANGUAGE plpgsql;

-- Usage: SELECT cleanup_old_conversations(90);
```

---

### get_conversation_context()

**Purpose:** Retrieve formatted conversation history for AI

```sql
CREATE OR REPLACE FUNCTION get_conversation_context(
    user_phone VARCHAR(20),
    message_limit INTEGER DEFAULT 10
)
RETURNS JSONB AS $$
BEGIN
    RETURN (
        SELECT conversation_history
        FROM user_conversations
        WHERE phone_number = user_phone
        ORDER BY updated_at DESC
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql;
```

---

## Entity Relationship Diagrams

### Core Schema ER Diagram

```
┌─────────────────┐
│     users       │
│─────────────────│
│ • id (PK)       │
│ • phone_number  │◄───┐
│ • contact_name  │    │
│ • total_msgs    │    │
│ • last_msg_at   │    │
└─────────────────┘    │
         ▲             │
         │             │
         │             │
         │  ┌──────────┴──────────┐
         │  │                     │
┌────────┴──────────┐   ┌─────────┴───────────┐
│ user_conversations│   │      messages       │
│───────────────────│   │─────────────────────│
│ • id (PK)         │   │ • id (PK)           │
│ • phone_number(FK)│   │ • phone_number (FK) │
│ • history (JSONB) │   │ • message_id        │
│ • sentiment       │   │ • direction         │
│ • status          │   │ • content           │
└───────────────────┘   │ • media_url         │
                        └─────────┬───────────┘
                                  │
                                  │
                        ┌─────────┴───────────┐
                        │  ai_interactions    │
                        │─────────────────────│
                        │ • id (PK)           │
                        │ • phone_number (FK) │
                        │ • message_id        │
                        │ • model_used        │
                        │ • tokens            │
                        │ • cost_usd          │
                        └─────────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ knowledge_base  │     │    analytics    │     │    feedback     │
│─────────────────│     │─────────────────│     │─────────────────│
│ • id (PK)       │     │ • id (PK)       │     │ • id (PK)       │
│ • title         │     │ • phone_number  │     │ • phone_number  │
│ • content       │     │ • event_type    │     │ • rating        │
│ • embedding     │     │ • event_data    │     │ • feedback_text │
│ • tags[]        │     │ • timestamp     │     │ • sentiment     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Enhanced Schema ER Diagram (v2.0 Features)

```
HUMAN HANDOFF SYSTEM
────────────────────
┌─────────────────────┐
│  handoff_requests   │
│─────────────────────│
│ • id (PK)           │
│ • phone_number (FK) │───┐
│ • reason            │   │
│ • priority          │   │
│ • status            │   │
│ • assigned_to (FK)  │───┼────┐
└─────────────────────┘   │    │
         │                │    │
         │                │    │
         ▼                │    ▼
┌─────────────────────┐   │  ┌──────────────────┐
│  active_handoffs    │   │  │agent_availability│
│─────────────────────│   │  │──────────────────│
│ • id (PK)           │   │  │ • agent_id (PK)  │
│ • handoff_req_id(FK)│   │  │ • status         │
│ • phone_number (FK) │◄──┘  │ • max_chats      │
│ • agent_id (FK)     │──────►│ • current_chats  │
│ • slack_channel_id  │      │ • skills[]       │
│ • messages (JSONB)  │      └──────────────────┘
└─────────────────────┘

PROACTIVE MESSAGING
───────────────────
┌──────────────────────┐       ┌──────────────────┐
│ message_templates    │       │scheduled_messages│
│──────────────────────│       │──────────────────│
│ • id (PK)            │◄──────│ • id (PK)        │
│ • template_name      │       │ • phone_numbers[]│
│ • message_content    │       │ • template_name  │
│ • variables (JSONB)  │       │ • scheduled_for  │
│ • usage_count        │       │ • status         │
└──────────────────────┘       └──────────────────┘
         ▲                              │
         │                              │
         │                              ▼
┌────────┴──────────┐       ┌──────────────────┐
│message_campaigns  │       │broadcast_history │
│───────────────────│       │──────────────────│
│ • id (PK)         │       │ • id (PK)        │
│ • campaign_name   │◄──────│ • campaign_id(FK)│
│ • target_audience │       │ • phone_number   │
│ • template_name   │       │ • message_id     │
│ • status          │       │ • status         │
└───────────────────┘       └──────────────────┘

VOICE & VIDEO FEATURES
──────────────────────
┌───────────────────────┐     ┌──────────────────┐
│user_voice_preferences │     │ voice_responses  │
│───────────────────────│     │──────────────────│
│ • phone_number (PK,FK)│◄────│ • id (PK)        │
│ • voice_enabled       │     │ • phone_number   │
│ • voice_name          │     │ • text_content   │
│ • voice_speed         │     │ • audio_url      │
│ • language            │     │ • cost_usd       │
└───────────────────────┘     └──────────────────┘

┌──────────────────┐
│video_processing  │
│──────────────────│
│ • id (PK)        │
│ • phone_number   │
│ • video_url      │
│ • storage_url    │
│ • analysis(JSONB)│
│ • transcription  │
└──────────────────┘
```

---

## Deployment Instructions

### Option 1: Docker Compose (Recommended)

The database schemas are automatically initialized when using Docker Compose.

**1. Ensure SQL files are in the `db/` folder:**
```bash
ls -la db/
# Should show:
# - database-schema.sql
# - database-schema-enhanced.sql
```

**2. Docker Compose will mount and execute:**
```yaml
# docker-compose.yml (already configured)
volumes:
  - ./db/database-schema.sql:/docker-entrypoint-initdb.d/01-base-schema.sql:ro
  - ./db/database-schema-enhanced.sql:/docker-entrypoint-initdb.d/02-enhanced-schema.sql:ro
```

**3. Start the database:**
```bash
docker-compose up -d WPSupport_postgres
```

**4. Verify initialization:**
```bash
docker-compose exec WPSupport_postgres psql -U n8n_user -d whatsapp_support_agent -c "\dt"
```

You should see all 18 tables listed.

---

### Option 2: Azure PostgreSQL Flexible Server

**1. Create Azure PostgreSQL server:**
```bash
az postgres flexible-server create \
  --name whatsapp-support-db \
  --resource-group whatsapp-support-rg \
  --location eastus \
  --admin-user n8nadmin \
  --admin-password 'YourSecurePassword123!' \
  --sku-name Standard_D2ds_v4 \
  --tier GeneralPurpose \
  --storage-size 128 \
  --version 15
```

**2. Enable pgvector extension:**
```bash
az postgres flexible-server parameter set \
  --resource-group whatsapp-support-rg \
  --server-name whatsapp-support-db \
  --name azure.extensions \
  --value vector
```

**3. Create database:**
```bash
az postgres flexible-server db create \
  --resource-group whatsapp-support-rg \
  --server-name whatsapp-support-db \
  --database-name whatsapp_support_agent
```

**4. Get connection string:**
```bash
az postgres flexible-server show-connection-string \
  --server-name whatsapp-support-db \
  --database-name whatsapp_support_agent \
  --admin-user n8nadmin \
  --admin-password 'YourSecurePassword123!'
```

**5. Deploy schemas:**
```bash
# Connect and deploy
psql "postgresql://n8nadmin:YourSecurePassword123!@whatsapp-support-db.postgres.database.azure.com:5432/whatsapp_support_agent?sslmode=require" \
  -f db/database-schema.sql \
  -f db/database-schema-enhanced.sql
```

**6. Verify deployment:**
```bash
psql "postgresql://..." -c "
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;"
```

---

### Option 3: Manual PostgreSQL Installation

**1. Install PostgreSQL 15+ and pgvector:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y postgresql-15 postgresql-contrib-15

# Install pgvector
sudo apt-get install -y postgresql-15-pgvector
```

**2. Create database and user:**
```bash
sudo -u postgres psql

CREATE DATABASE whatsapp_support_agent;
CREATE USER n8n_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE whatsapp_support_agent TO n8n_user;
\c whatsapp_support_agent
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
GRANT ALL ON SCHEMA public TO n8n_user;
\q
```

**3. Deploy schemas:**
```bash
psql -U n8n_user -d whatsapp_support_agent -f db/database-schema.sql
psql -U n8n_user -d whatsapp_support_agent -f db/database-schema-enhanced.sql
```

**4. Verify:**
```bash
psql -U n8n_user -d whatsapp_support_agent -c "\dt"
psql -U n8n_user -d whatsapp_support_agent -c "SELECT COUNT(*) FROM users;"
```

---

## Data Migration

### Migrating from v1.0 to v2.0

If you have an existing deployment with only the base schema, follow these steps:

**1. Backup existing database:**
```bash
pg_dump -U n8n_user whatsapp_support_agent > backup_v1_$(date +%Y%m%d).sql
```

**2. Apply enhanced schema:**
```bash
psql -U n8n_user -d whatsapp_support_agent -f db/database-schema-enhanced.sql
```

**3. Verify new tables:**
```bash
psql -U n8n_user -d whatsapp_support_agent -c "
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN (
  'handoff_requests', 'agent_availability', 'active_handoffs',
  'scheduled_messages', 'message_templates', 'message_campaigns', 'broadcast_history',
  'user_voice_preferences', 'voice_responses', 'video_processing'
);"
```

Should return 10 tables.

---

### Exporting Data

**Export all data to CSV:**
```bash
# Export users
psql -U n8n_user -d whatsapp_support_agent -c "
COPY users TO '/tmp/users.csv' CSV HEADER;"

# Export messages
psql -U n8n_user -d whatsapp_support_agent -c "
COPY messages TO '/tmp/messages.csv' CSV HEADER;"

# Export all tables
./scripts/export-database.sh
```

**Export to JSON:**
```bash
psql -U n8n_user -d whatsapp_support_agent -c "
SELECT json_agg(row_to_json(users)) FROM users;" > users.json
```

---

## Performance Optimization

### Indexing Strategy

**1. Monitor index usage:**
```sql
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY tablename;
```

**2. Create custom indexes for frequent queries:**
```sql
-- Composite index for message queries
CREATE INDEX idx_messages_user_timestamp
ON messages(phone_number, timestamp DESC);

-- Partial index for active conversations
CREATE INDEX idx_active_conversations
ON user_conversations(phone_number)
WHERE status = 'active';

-- Partial index for pending handoffs
CREATE INDEX idx_pending_handoffs
ON handoff_requests(created_at, priority)
WHERE status = 'pending';
```

---

### Query Optimization

**1. Use EXPLAIN ANALYZE:**
```sql
EXPLAIN ANALYZE
SELECT * FROM messages
WHERE phone_number = '+1234567890'
ORDER BY timestamp DESC
LIMIT 50;
```

**2. Optimize JSONB queries:**
```sql
-- Bad: Full scan
SELECT * FROM user_conversations
WHERE conversation_history::text LIKE '%urgent%';

-- Good: GIN index usage
SELECT * FROM user_conversations
WHERE conversation_history @> '[{"content": "urgent"}]';
```

---

### Vacuum and Maintenance

**1. Regular vacuum:**
```sql
-- Manual vacuum
VACUUM ANALYZE users;
VACUUM ANALYZE messages;

-- Full vacuum (requires lock)
VACUUM FULL messages;
```

**2. Auto-vacuum settings:**
```sql
ALTER TABLE messages SET (
  autovacuum_vacuum_scale_factor = 0.1,
  autovacuum_analyze_scale_factor = 0.05
);
```

**3. Scheduled maintenance:**
```bash
# Add to crontab
0 2 * * * psql -U n8n_user -d whatsapp_support_agent -c "VACUUM ANALYZE;"
```

---

### Connection Pooling

**Using PgBouncer (recommended):**

```ini
# pgbouncer.ini
[databases]
whatsapp_support_agent = host=WPSupport_postgres port=5432 dbname=whatsapp_support_agent

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 5
```

---

## Backup and Restore

### Automated Backups (Docker Compose)

The `WPSupport_postgres_backup` container automatically backs up the database every 6 hours.

**Backup location:**
```
./backups/postgres/
├── whatsapp_support_agent_20251215_020000.sql
├── whatsapp_support_agent_20251215_080000.sql
└── whatsapp_support_agent_20251215_140000.sql
```

**Manual backup:**
```bash
docker-compose exec WPSupport_postgres_backup /backup.sh
```

---

### Manual Backup

**Full database backup:**
```bash
pg_dump -U n8n_user \
  -h localhost \
  -p 5432 \
  -d whatsapp_support_agent \
  -F c \
  -f whatsapp_support_backup_$(date +%Y%m%d_%H%M%S).dump
```

**Schema-only backup:**
```bash
pg_dump -U n8n_user \
  -h localhost \
  -d whatsapp_support_agent \
  --schema-only \
  -f schema_backup.sql
```

**Data-only backup:**
```bash
pg_dump -U n8n_user \
  -h localhost \
  -d whatsapp_support_agent \
  --data-only \
  -f data_backup.sql
```

**Specific tables:**
```bash
pg_dump -U n8n_user \
  -h localhost \
  -d whatsapp_support_agent \
  -t users -t messages -t ai_interactions \
  -f core_tables_backup.sql
```

---

### Restore Procedures

**Restore from custom format (.dump):**
```bash
pg_restore -U n8n_user \
  -h localhost \
  -d whatsapp_support_agent \
  -c \
  -F c \
  whatsapp_support_backup_20251215_140000.dump
```

**Restore from SQL file:**
```bash
psql -U n8n_user \
  -h localhost \
  -d whatsapp_support_agent \
  -f whatsapp_support_backup.sql
```

**Restore specific tables:**
```bash
pg_restore -U n8n_user \
  -h localhost \
  -d whatsapp_support_agent \
  -t users -t messages \
  backup.dump
```

---

### Point-in-Time Recovery (PITR)

**1. Enable WAL archiving:**
```sql
-- postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backups/wal_archive/%f'
```

**2. Perform base backup:**
```bash
pg_basebackup -U n8n_user \
  -D /backups/base_backup \
  -Ft -z -P
```

**3. Restore to specific point:**
```bash
# recovery.conf
restore_command = 'cp /backups/wal_archive/%f %p'
recovery_target_time = '2025-12-15 14:30:00'
```

---

## Common Queries

### User Analytics

**Active users by period:**
```sql
SELECT * FROM active_users_stats;
```

**Top users by message count:**
```sql
SELECT phone_number, contact_name, total_messages, last_message_at
FROM users
ORDER BY total_messages DESC
LIMIT 20;
```

**User engagement cohorts:**
```sql
SELECT
    DATE_TRUNC('week', created_at) as cohort_week,
    COUNT(*) as new_users,
    COUNT(CASE WHEN total_messages > 5 THEN 1 END) as engaged_users
FROM users
WHERE created_at > NOW() - INTERVAL '12 weeks'
GROUP BY cohort_week
ORDER BY cohort_week DESC;
```

---

### Message Analytics

**Daily message volume:**
```sql
SELECT
    DATE(timestamp) as date,
    direction,
    COUNT(*) as message_count,
    COUNT(DISTINCT phone_number) as unique_users
FROM messages
WHERE timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp), direction
ORDER BY date DESC;
```

**Media type distribution:**
```sql
SELECT
    message_type,
    COUNT(*) as count,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) as percentage
FROM messages
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY message_type
ORDER BY count DESC;
```

**Message delivery funnel:**
```sql
SELECT
    status,
    COUNT(*) as count,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) as percentage
FROM messages
WHERE direction = 'outbound'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY status;
```

---

### AI Performance

**Model cost analysis:**
```sql
SELECT
    model_used,
    COUNT(*) as total_requests,
    AVG(total_tokens) as avg_tokens,
    SUM(cost_usd) as total_cost_usd,
    AVG(cost_usd) as avg_cost_per_request
FROM ai_interactions
WHERE timestamp > NOW() - INTERVAL '30 days'
GROUP BY model_used
ORDER BY total_cost_usd DESC;
```

**Response time percentiles:**
```sql
SELECT
    model_used,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_time_ms) as p50_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms) as p95_ms,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time_ms) as p99_ms
FROM ai_interactions
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY model_used;
```

---

### Human Handoff Metrics

**Handoff queue status:**
```sql
SELECT
    priority,
    COUNT(*) as pending_count,
    AVG(EXTRACT(EPOCH FROM (NOW() - created_at))) as avg_wait_seconds,
    MAX(EXTRACT(EPOCH FROM (NOW() - created_at))) as max_wait_seconds
FROM handoff_requests
WHERE status = 'pending'
GROUP BY priority
ORDER BY priority;
```

**Agent performance:**
```sql
SELECT
    hr.assigned_to,
    COUNT(*) as total_handoffs,
    AVG(EXTRACT(EPOCH FROM (hr.completed_at - hr.assigned_at))) as avg_handle_time,
    AVG(hr.wait_time_seconds) as avg_wait_time
FROM handoff_requests hr
WHERE hr.status = 'completed'
  AND hr.created_at > NOW() - INTERVAL '7 days'
GROUP BY hr.assigned_to
ORDER BY total_handoffs DESC;
```

---

### Campaign Performance

**Campaign delivery metrics:**
```sql
SELECT
    mc.campaign_name,
    mc.total_recipients,
    mc.messages_sent,
    COUNT(bh.id) as total_broadcasts,
    COUNT(CASE WHEN bh.status = 'delivered' THEN 1 END) as delivered,
    COUNT(CASE WHEN bh.status = 'read' THEN 1 END) as read,
    ROUND(
        COUNT(CASE WHEN bh.status = 'read' THEN 1 END)::NUMERIC /
        COUNT(CASE WHEN bh.status = 'delivered' THEN 1 END)::NUMERIC * 100,
        2
    ) as read_rate_percent
FROM message_campaigns mc
LEFT JOIN broadcast_history bh ON bh.campaign_id = mc.id
WHERE mc.created_at > NOW() - INTERVAL '30 days'
GROUP BY mc.id, mc.campaign_name, mc.total_recipients, mc.messages_sent
ORDER BY mc.created_at DESC;
```

---

## Troubleshooting

### Connection Issues

**1. Check if database is running:**
```bash
# Docker
docker-compose ps WPSupport_postgres

# Native PostgreSQL
sudo systemctl status postgresql
```

**2. Test connection:**
```bash
psql -U n8n_user -h localhost -d whatsapp_support_agent -c "SELECT version();"
```

**3. Check connection limits:**
```sql
SELECT * FROM pg_stat_activity;
SELECT COUNT(*) FROM pg_stat_activity;

-- Show max connections
SHOW max_connections;
```

**4. Kill idle connections:**
```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
  AND state_change < NOW() - INTERVAL '1 hour';
```

---

### Performance Issues

**1. Identify slow queries:**
```sql
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

**2. Check table bloat:**
```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    n_dead_tup,
    n_live_tup,
    ROUND(n_dead_tup::NUMERIC / NULLIF(n_live_tup, 0) * 100, 2) as dead_tuple_percent
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

**3. Rebuild indexes:**
```sql
REINDEX TABLE messages;
REINDEX TABLE user_conversations;
```

---

### Data Integrity

**1. Check for orphaned records:**
```sql
-- Messages without users
SELECT COUNT(*)
FROM messages m
LEFT JOIN users u ON m.phone_number = u.phone_number
WHERE u.phone_number IS NULL;

-- Handoffs without requests
SELECT COUNT(*)
FROM active_handoffs ah
LEFT JOIN handoff_requests hr ON ah.handoff_request_id = hr.id
WHERE hr.id IS NULL;
```

**2. Fix referential integrity:**
```sql
-- Remove orphaned messages
DELETE FROM messages
WHERE phone_number NOT IN (SELECT phone_number FROM users);
```

**3. Validate JSONB structure:**
```sql
-- Check for invalid conversation history
SELECT id, phone_number
FROM user_conversations
WHERE NOT jsonb_typeof(conversation_history) = 'array';
```

---

### Disk Space

**1. Check database size:**
```sql
SELECT
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;
```

**2. Check table sizes:**
```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

**3. Archive old data:**
```sql
-- Archive messages older than 1 year
CREATE TABLE messages_archive AS
SELECT * FROM messages
WHERE timestamp < NOW() - INTERVAL '1 year';

DELETE FROM messages
WHERE timestamp < NOW() - INTERVAL '1 year';

VACUUM FULL messages;
```

---

## Database Monitoring

### Key Metrics to Monitor

1. **Connection Count**
   - Alert if > 80% of max_connections

2. **Query Performance**
   - Alert if p95 response time > 100ms

3. **Disk Usage**
   - Alert if > 85% full

4. **Replication Lag** (if using replication)
   - Alert if > 10 seconds

5. **Lock Contention**
   - Alert if lock wait time > 5 seconds

### Monitoring Queries

```sql
-- Connection count
SELECT COUNT(*) as current_connections,
       (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections
FROM pg_stat_activity;

-- Cache hit ratio (should be > 99%)
SELECT
    SUM(blks_hit)::float / (SUM(blks_hit) + SUM(blks_read)) * 100 as cache_hit_ratio
FROM pg_stat_database;

-- Long-running queries
SELECT pid, now() - query_start as duration, query
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - query_start > interval '5 minutes';
```

---

## Security Best Practices

1. **Use strong passwords** (minimum 20 characters)
2. **Enable SSL/TLS** for all connections
3. **Restrict network access** using firewall rules
4. **Use connection pooling** (PgBouncer)
5. **Enable audit logging** (pgaudit extension)
6. **Regular security updates**
7. **Encrypt backups**
8. **Use Azure Key Vault** for credentials in production
9. **Enable row-level security** for multi-tenant scenarios
10. **Regular security audits**

---

## Additional Resources

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/15/)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [Azure PostgreSQL Best Practices](https://learn.microsoft.com/en-us/azure/postgresql/)
- [n8n Database Best Practices](https://docs.n8n.io/hosting/configuration/database/)

---

**For deployment guides, see:**
- [Complete Deployment v2.0](../docs/DEPLOYMENT-V2.md)
- [Docker Compose Deployment](../docs/DOCKER-DEPLOYMENT.md)
- [Azure Deployment Guide](../docs/AZURE-DEPLOYMENT.md)

---

**Database Schema Version:** 2.0
**Last Updated:** 2025-12-15
**Maintained by:** WhatsApp AI Support Agent Team
