# Quick Reference Guide

Essential commands and queries for managing your WhatsApp AI Support Agent.

## Table of Contents

- [Database Queries](#database-queries)
- [Workflow Management](#workflow-management)
- [Feature Usage](#feature-usage)
- [API Endpoints](#api-endpoints)
- [Troubleshooting Commands](#troubleshooting-commands)

---

## Database Queries

### User Management

```sql
-- Get active users
SELECT * FROM users WHERE last_message_at > NOW() - INTERVAL '24 hours';

-- Block a user
UPDATE users SET is_blocked = true WHERE phone_number = '1234567890';

-- User statistics
SELECT * FROM active_users_stats;
```

### Conversation History

```sql
-- Get user's conversation
SELECT conversation_history
FROM user_conversations
WHERE phone_number = '1234567890';

-- Recent conversations
SELECT phone_number, last_message, updated_at
FROM user_conversations
ORDER BY updated_at DESC
LIMIT 20;

-- Delete old conversations
DELETE FROM user_conversations
WHERE updated_at < NOW() - INTERVAL '90 days';
```

### Message Analytics

```sql
-- Messages today
SELECT COUNT(*) FROM messages WHERE DATE(created_at) = CURRENT_DATE;

-- Messages by type
SELECT message_type, COUNT(*)
FROM messages
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY message_type;

-- Daily stats
SELECT * FROM message_stats ORDER BY date DESC LIMIT 7;
```

---

## Human Handoff

### Agent Management

```sql
-- Add agent
INSERT INTO agent_availability (agent_id, agent_name, agent_email, status, skills)
VALUES ('john_doe', 'John Doe', 'john@company.com', 'online', ARRAY['technical', 'billing']);

-- Set agent online/offline
UPDATE agent_availability SET status = 'online' WHERE agent_id = 'john_doe';

-- View agent performance
SELECT * FROM agent_performance;
```

### Handoff Management

```sql
-- Pending handoffs
SELECT * FROM handoff_requests WHERE status = 'pending' ORDER BY priority DESC;

-- Create handoff
SELECT create_handoff_request('1234567890', 'user_requested', 'high');

-- Resolve handoff
UPDATE handoff_requests SET status = 'resolved', resolved_at = NOW() WHERE id = 'uuid';

-- Handoff analytics
SELECT * FROM handoff_analytics ORDER BY date DESC LIMIT 7;
```

---

## Proactive Messaging

### Schedule Messages

```sql
-- Schedule single message
SELECT schedule_message(
    '1234567890',  -- phone
    'Your appointment is tomorrow at 2 PM',
    '2025-12-15 09:00:00'::timestamp,
    'reminder'
);

-- Schedule with template
INSERT INTO scheduled_messages (phone_number, template_name, message_content, scheduled_for, metadata)
VALUES (
    '1234567890',
    'order_shipped',
    'Hi {{name}}! Order #{{order_id}} shipped!',
    '2025-12-15 10:00:00',
    '{"name": "John", "order_id": "12345"}'::jsonb
);

-- Bulk message
INSERT INTO scheduled_messages (phone_numbers, message_content, scheduled_for)
VALUES (
    ARRAY['1111111111', '2222222222'],
    'Special offer today only!',
    NOW() + INTERVAL '1 hour'
);
```

### Manage Scheduled Messages

```sql
-- View pending
SELECT * FROM scheduled_messages WHERE status = 'scheduled' ORDER BY scheduled_for;

-- Cancel message
UPDATE scheduled_messages SET status = 'cancelled' WHERE id = 'uuid';

-- View failures
SELECT * FROM scheduled_messages WHERE status = 'failed' ORDER BY created_at DESC;
```

### Campaign Management

```sql
-- Create campaign
INSERT INTO message_campaigns (campaign_name, status, scheduled_start, total_recipients)
VALUES ('Black Friday 2025', 'scheduled', '2025-11-29 00:00:00', 1000);

-- Campaign performance
SELECT * FROM campaign_performance ORDER BY created_at DESC;
```

### Message Templates

```sql
-- Create template
INSERT INTO message_templates (template_name, template_category, message_content, variables)
VALUES (
    'welcome_new_user',
    'welcome',
    'Hi {{name}}! Welcome to {{company}}. How can we help?',
    '{"name": "string", "company": "string"}'::jsonb
);

-- List templates
SELECT template_name, template_category FROM message_templates WHERE is_active = true;

-- Use template
SELECT message_content FROM message_templates WHERE template_name = 'order_shipped';
```

---

## Voice Responses

### User Preferences

```sql
-- Enable voice for user
INSERT INTO user_voice_preferences (phone_number, voice_enabled, voice_name)
VALUES ('1234567890', true, 'alloy')
ON CONFLICT (phone_number) DO UPDATE SET voice_enabled = true;

-- Change voice
UPDATE user_voice_preferences SET voice_name = 'fable' WHERE phone_number = '1234567890';

-- Adjust speed
UPDATE user_voice_preferences SET voice_speed = 1.2 WHERE phone_number = '1234567890';
```

### Voice Analytics

```sql
-- Voice usage stats
SELECT * FROM voice_usage_stats ORDER BY date DESC LIMIT 30;

-- Monthly cost
SELECT
    DATE_TRUNC('month', created_at) as month,
    SUM(cost_usd) as total_cost,
    COUNT(*) as messages,
    SUM(audio_duration_seconds) as total_seconds
FROM voice_responses
GROUP BY month
ORDER BY month DESC;

-- Most active voice users
SELECT phone_number, COUNT(*) as voice_messages
FROM voice_responses
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY phone_number
ORDER BY voice_messages DESC
LIMIT 10;
```

---

## Video Support

### Video Processing

```sql
-- Recent videos
SELECT * FROM video_processing ORDER BY created_at DESC LIMIT 20;

-- Processing status
SELECT
    processing_status,
    COUNT(*) as count,
    AVG(video_duration_seconds) as avg_duration
FROM video_processing
GROUP BY processing_status;

-- Failed videos
SELECT * FROM video_processing WHERE processing_status = 'failed' ORDER BY created_at DESC;

-- Videos by user
SELECT phone_number, COUNT(*) as videos, AVG(video_duration_seconds) as avg_duration
FROM video_processing
GROUP BY phone_number
ORDER BY videos DESC;
```

---

## AI Analytics

### Performance

```sql
-- AI performance stats
SELECT * FROM ai_performance_stats ORDER BY date DESC LIMIT 7;

-- Response times
SELECT
    DATE(created_at) as date,
    AVG(response_time_ms) as avg_response_ms,
    MAX(response_time_ms) as max_response_ms,
    COUNT(*) as interactions
FROM ai_interactions
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY date
ORDER BY date DESC;

-- Token usage
SELECT
    DATE(created_at) as date,
    SUM(tokens_used) as total_tokens,
    SUM(tokens_used) * 0.00000015 as cost_usd
FROM ai_interactions
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY date
ORDER BY date DESC;
```

### Cost Monitoring

```sql
-- Daily costs
SELECT
    DATE(created_at) as date,
    SUM(tokens_used) * 0.00000015 as ai_cost_usd,
    (SELECT SUM(cost_usd) FROM voice_responses WHERE DATE(created_at) = DATE(ai.created_at)) as voice_cost_usd
FROM ai_interactions ai
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY date
ORDER BY date DESC;

-- Monthly total
SELECT
    SUM(tokens_used) * 0.00000015 +
    (SELECT COALESCE(SUM(cost_usd), 0) FROM voice_responses WHERE created_at > NOW() - INTERVAL '30 days')
    as monthly_total_usd
FROM ai_interactions
WHERE created_at > NOW() - INTERVAL '30 days';
```

---

## Knowledge Base

### Manage Content

```sql
-- Add knowledge
INSERT INTO knowledge_base (title, content, category, tags)
VALUES (
    'How to reset password',
    'Step-by-step password reset instructions...',
    'account',
    ARRAY['password', 'reset', 'help']
);

-- Search knowledge
SELECT title, content FROM knowledge_base
WHERE category = 'account' AND is_active = true;

-- Update knowledge
UPDATE knowledge_base SET content = 'Updated content...' WHERE title = 'How to reset password';

-- Deactivate knowledge
UPDATE knowledge_base SET is_active = false WHERE id = 'uuid';

-- Most used knowledge
SELECT title, usage_count FROM knowledge_base ORDER BY usage_count DESC LIMIT 10;
```

---

## System Maintenance

### Database Cleanup

```sql
-- Clean old messages (90+ days)
SELECT cleanup_old_conversations(90);

-- Clean error logs (30+ days)
DELETE FROM error_logs WHERE created_at < NOW() - INTERVAL '30 days';

-- Vacuum database
VACUUM ANALYZE;

-- Database size
SELECT pg_size_pretty(pg_database_size('whatsapp_support_agent'));
```

### Backups

```bash
# Backup database
docker exec postgres pg_dump -U n8n_user whatsapp_support_agent > backup_$(date +%Y%m%d).sql

# Backup with compression
docker exec postgres pg_dump -U n8n_user whatsapp_support_agent | gzip > backup_$(date +%Y%m%d).sql.gz

# Restore backup
docker exec -i postgres psql -U n8n_user whatsapp_support_agent < backup_20251214.sql
```

---

## Docker Commands

### Service Management

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart n8n
docker-compose restart n8n

# View logs
docker-compose logs -f n8n

# Check status
docker-compose ps
```

### Database Access

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent

# Run SQL file
docker-compose exec -T postgres psql -U n8n_user -d whatsapp_support_agent < script.sql

# Export data
docker-compose exec postgres pg_dump -U n8n_user -t messages whatsapp_support_agent > messages.sql
```

---

## n8n CLI

### Workflow Management

```bash
# List workflows
n8n list:workflow

# Export workflow
n8n export:workflow --id=<workflow-id> --output=workflow.json

# Import workflow
n8n import:workflow --input=workflow.json

# Execute workflow
n8n execute --id=<workflow-id>
```

---

## API Endpoints

### Schedule Message API

```bash
# POST /api/schedule-message
curl -X POST https://your-domain.com/api/schedule-message \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "1234567890",
    "message": "Your order has shipped!",
    "scheduled_for": "2025-12-15T10:00:00Z",
    "template": "order_shipped",
    "variables": {
      "name": "John",
      "order_id": "12345"
    }
  }'
```

### Create Handoff API

```bash
# POST /api/create-handoff
curl -X POST https://your-domain.com/api/create-handoff \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "1234567890",
    "reason": "user_requested",
    "priority": "high",
    "context": "User needs technical support"
  }'
```

---

## Troubleshooting Commands

### Check Webhook

```bash
# Test webhook
curl -X POST https://your-domain.com/webhook/whatsapp-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "from": "1234567890",
            "id": "test_id",
            "timestamp": "1234567890",
            "text": {"body": "Hello"},
            "type": "text"
          }],
          "contacts": [{"profile": {"name": "Test User"}}],
          "metadata": {"phone_number_id": "your_phone_id"}
        }
      }],
      "id": "your_business_id"
    }]
  }'
```

### Check Services

```bash
# n8n health
curl https://your-domain.com/healthz

# Database connection
docker-compose exec postgres pg_isready -U n8n_user

# Redis connection
docker-compose exec redis redis-cli ping
```

### View Logs

```bash
# n8n logs (last 100 lines)
docker-compose logs --tail=100 n8n

# Database logs
docker-compose logs --tail=100 postgres

# All errors
docker-compose logs | grep -i error

# Follow logs in real-time
docker-compose logs -f
```

### Common Fixes

```bash
# Restart webhook workflow
# In n8n UI: Deactivate → Activate workflow

# Clear Redis cache
docker-compose exec redis redis-cli FLUSHDB

# Rebuild containers
docker-compose down && docker-compose up -d --build

# Reset n8n encryption
# WARNING: This will reset all credentials
docker-compose exec n8n n8n reset
```

---

## Environment Variables

### Quick Access

```bash
# View all variables
cat .env

# Edit variables
nano .env

# Reload after changes
docker-compose down && docker-compose up -d

# Check specific variable
docker-compose exec n8n printenv | grep OPENAI
```

---

## Performance Monitoring

### System Resources

```bash
# Docker stats
docker stats

# Disk usage
df -h

# Check n8n memory
docker stats n8n --no-stream

# Database size
docker-compose exec postgres psql -U n8n_user -c \
  "SELECT pg_size_pretty(pg_database_size('whatsapp_support_agent'));"
```

### Query Performance

```sql
-- Slow queries
SELECT * FROM pg_stat_activity WHERE state = 'active' AND query_start < NOW() - INTERVAL '5 seconds';

-- Table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Index usage
SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0;
```

---

## Keyboard Shortcuts (n8n UI)

- `Ctrl/Cmd + A` - Select all nodes
- `Ctrl/Cmd + C` - Copy nodes
- `Ctrl/Cmd + V` - Paste nodes
- `Ctrl/Cmd + Z` - Undo
- `Ctrl/Cmd + S` - Save workflow
- `Ctrl/Cmd + E` - Execute workflow
- `Delete` - Delete selected nodes
- `Tab` - Open node creator

---

## Support Contacts

- **n8n Community**: https://community.n8n.io
- **WhatsApp Business Support**: https://developers.facebook.com/support/whatsapp
- **OpenAI Support**: https://help.openai.com

---

**Quick Links**

- [Full Documentation](README.md)
- [Enhanced Features Guide](FEATURES.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Quick Start](QUICKSTART.md)
- [Architecture](ARCHITECTURE.md)
