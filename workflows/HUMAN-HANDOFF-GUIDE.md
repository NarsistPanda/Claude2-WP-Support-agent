# Human Handoff Workflow Guide

Complete guide for the WhatsApp AI Support Agent Human Handoff System.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Workflow Components](#workflow-components)
4. [Setup Instructions](#setup-instructions)
5. [Configuration](#configuration)
6. [Agent Management](#agent-management)
7. [Handoff Triggers](#handoff-triggers)
8. [Notification Channels](#notification-channels)
9. [Message Routing](#message-routing)
10. [Analytics & Monitoring](#analytics--monitoring)
11. [Troubleshooting](#troubleshooting)

---

## Overview

The Human Handoff workflow (`human-handoff-workflow.json`) is an **event-driven automation** that seamlessly transfers conversations from AI to human agents when needed. It runs every minute, monitoring for pending handoff requests and assigning them to available agents based on skills, capacity, and priority.

### Key Features

- ✅ **Intelligent Agent Matching** - Skills-based routing with capacity management
- ✅ **Multi-Channel Notifications** - Slack, Email, and Custom Webhooks
- ✅ **Priority Queue** - Urgent/High/Medium/Low priority handling
- ✅ **Context Preservation** - Full conversation history provided to agents
- ✅ **Real-Time Analytics** - Track handoff metrics and agent performance
- ✅ **Automatic Load Balancing** - Distributes workload across available agents
- ✅ **Fallback Mechanisms** - Handles no-agent-available scenarios gracefully

### How It Works

```
1. User triggers handoff (keyword, sentiment, manual)
   ↓
2. Handoff request created in database (by main workflow)
   ↓
3. Human Handoff workflow polls database every minute
   ↓
4. Finds available agent matching skills & capacity
   ↓
5. Assigns agent and creates active handoff session
   ↓
6. Sends notifications (Slack + Email + Webhook)
   ↓
7. Agent receives context and can respond via Slack
   ↓
8. Messages routed between agent and user via WhatsApp
```

---

## Architecture

### Workflow Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      TRIGGER (Every 1 minute)                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│              Get Pending Handoffs (PostgreSQL)                   │
│  SELECT * FROM handoff_requests WHERE status = 'pending'        │
│  ORDER BY priority, created_at                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Handoffs     │
                    │ Exist?       │
                    └──┬────────┬──┘
                   YES │        │ NO → End
                       │        │
                       ▼        │
┌─────────────────────────────────────────────────────────────────┐
│         Analyze Handoff Requirements (Code Node)                 │
│  • Extract required skills based on reason                       │
│  • Determine urgency level                                       │
│  • Add sentiment-based requirements                              │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│           Find Available Agent (PostgreSQL)                      │
│  SELECT * FROM agent_availability                               │
│  WHERE status = 'online'                                        │
│    AND current_chat_count < max_concurrent_chats                │
│    AND skills && $required_skills                               │
│  ORDER BY capacity DESC, current_chat_count ASC                 │
│  LIMIT 1                                                        │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Agent        │
                    │ Found?       │
                    └──┬────────┬──┘
                   YES │        │ NO
                       │        │
                       ▼        ▼
         ┌──────────────────┐  ┌──────────────────────┐
         │  Assign Agent    │  │ Mark: No Agent       │
         │  & Create        │  │ Available            │
         │  Active Handoff  │  │ (Retry Later)        │
         └────────┬─────────┘  └──────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Update Database                               │
│  1. handoff_requests: status → 'assigned'                       │
│  2. active_handoffs: CREATE new session                         │
│  3. agent_availability: current_chat_count + 1                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│              Send Notifications (Parallel)                       │
│  ├── Slack: Rich message with buttons                           │
│  ├── Email: HTML formatted notification                         │
│  └── Webhook: JSON payload to external system                   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│              Log Analytics (PostgreSQL)                          │
│  INSERT INTO analytics (event_type: 'handoff_assigned')         │
└─────────────────────────────────────────────────────────────────┘
```

### Database Integration

The workflow interacts with 4 main tables:

1. **`handoff_requests`** - Pending and historical handoff requests
2. **`agent_availability`** - Agent status, skills, and capacity
3. **`active_handoffs`** - Currently active agent-user sessions
4. **`analytics`** - Handoff events for reporting

---

## Workflow Components

### Node Breakdown (18 Total Nodes)

| # | Node Name | Type | Purpose |
|---|-----------|------|---------|
| 1 | Check Every Minute | Schedule Trigger | Polls every 60 seconds |
| 2 | Get Pending Handoffs | PostgreSQL | Fetches pending requests |
| 3 | Check Handoffs Exist | IF | Validates data exists |
| 4 | Analyze Handoff Requirements | Code | Extracts skills needed |
| 5 | Find Available Agent | PostgreSQL | Matches agent to request |
| 6 | Check Agent Found | IF | Validates agent assignment |
| 7 | Merge Handoff & Agent Data | Code | Combines all context |
| 8 | Update Handoff: Assigned | PostgreSQL | Marks as assigned |
| 9 | Create Active Handoff | PostgreSQL | Creates session |
| 10 | Increment Agent Chat Count | PostgreSQL | Updates agent workload |
| 11 | Prepare Slack Notification | Code | Formats rich Slack message |
| 12 | Send Slack Notification | Slack | Sends to channel |
| 13 | Prepare Email Notification | Code | Formats HTML email |
| 14 | Send Email Notification | SMTP | Sends email |
| 15 | Send Webhook Notification | HTTP Request | Posts to external URL |
| 16 | Merge Notifications | Merge | Combines results |
| 17 | Log Handoff Analytics | PostgreSQL | Records metrics |
| 18 | Mark: No Agent Available | PostgreSQL | Handles no-agent case |

### Execution Mode

- **Type**: Event-driven (scheduled polling)
- **Frequency**: Every 1 minute
- **Timeout**: 60 seconds
- **Concurrency**: Sequential (processes one batch at a time)
- **Error Handling**: Continue on fail for non-critical nodes

---

## Setup Instructions

### Prerequisites

1. **Database Schema**: Enhanced schema must be deployed
   ```bash
   psql -U n8n_user -d whatsapp_support_agent -f db/database-schema-enhanced.sql
   ```

2. **Agent Records**: At least one agent must be configured
   ```sql
   INSERT INTO agent_availability (
     agent_id, agent_name, email, slack_user_id,
     status, max_concurrent_chats, skills, languages
   ) VALUES (
     'agent001', 'John Doe', 'john@company.com', 'U01ABC123',
     'online', 5, ARRAY['general', 'billing'], ARRAY['en', 'es']
   );
   ```

3. **n8n Credentials**:
   - PostgreSQL connection
   - Slack API token (optional)
   - SMTP credentials (optional)

### Installation Steps

#### Step 1: Import Workflow to n8n

```bash
# Method 1: Via n8n UI
1. Open n8n (http://localhost:5678)
2. Click "+" → "Import from File"
3. Select workflows/human-handoff-workflow.json
4. Click "Import"

# Method 2: Via n8n CLI
n8n import:workflow --input=workflows/human-handoff-workflow.json
```

#### Step 2: Configure Credentials

**PostgreSQL Credential:**
```
Name: PostgreSQL
Host: WPSupport_postgres (or your host)
Port: 5432
Database: whatsapp_support_agent
User: n8n_user
Password: [your password]
SSL: false (true for production)
```

**Slack API Credential (Optional):**
```
Name: Slack API
Access Token: xoxb-your-bot-token
```

To get Slack token:
1. Go to https://api.slack.com/apps
2. Create new app → "From scratch"
3. OAuth & Permissions → Add scopes:
   - `chat:write`
   - `chat:write.public`
   - `channels:read`
4. Install app to workspace
5. Copy "Bot User OAuth Token"

**SMTP Credential (Optional):**
```
Name: SMTP
Host: smtp.gmail.com (or your SMTP server)
Port: 587
User: your-email@gmail.com
Password: [app password]
Secure: true
```

#### Step 3: Set Environment Variables

Add to your `.env` file:

```bash
# Slack Configuration (Optional)
SLACK_HANDOFF_CHANNEL=#customer-support
SLACK_WORKSPACE_URL=https://yourworkspace.slack.com

# Email Configuration (Optional)
SMTP_FROM_EMAIL=support@yourcompany.com
FALLBACK_AGENT_EMAIL=fallback@yourcompany.com

# Webhook Configuration (Optional)
HANDOFF_WEBHOOK_URL=https://your-crm.com/api/handoff
HANDOFF_WEBHOOK_TOKEN=your-webhook-secret-token

# n8n Configuration
N8N_URL=https://your-n8n-instance.com
```

#### Step 4: Activate Workflow

1. Open workflow in n8n
2. Click "Active" toggle in top-right
3. Workflow will start polling every minute

---

## Configuration

### Polling Interval

Default: **1 minute**

To change:
1. Open "Check Every Minute" node
2. Modify `minutesInterval` value
3. Save workflow

Recommended intervals:
- High volume: 30 seconds
- Medium volume: 1 minute (default)
- Low volume: 2-5 minutes

### Agent Matching Algorithm

The workflow uses this logic to find agents:

```sql
1. Filter: status = 'online'
2. Filter: current_chat_count < max_concurrent_chats
3. Filter: skills match required skills (if specified)
4. Filter: last_seen_at within 10 minutes
5. Order by: capacity DESC (most available first)
6. Order by: current_chat_count ASC (least busy first)
7. Limit: 1 (best match)
```

### Skill-Based Routing

Skills are automatically inferred from handoff reason:

| Reason Contains | Required Skills |
|----------------|-----------------|
| "billing", "payment" | `billing` |
| "technical", "bug" | `technical` |
| "sales", "upgrade" | `sales` |
| Other | `general` |
| Sentiment < 0.3 | `conflict_resolution` |

To customize, edit the `Analyze Handoff Requirements` node.

### Priority Handling

Handoffs are processed in priority order:

1. **Urgent** - Critical issues, escalations
2. **High** - Negative sentiment, repeated failures
3. **Medium** - User requested (default)
4. **Low** - Optional transfers

---

## Agent Management

### Adding Agents

```sql
INSERT INTO agent_availability (
  agent_id,
  agent_name,
  email,
  slack_user_id,
  status,
  max_concurrent_chats,
  skills,
  languages,
  created_at,
  updated_at
) VALUES (
  'agent_jane_smith',
  'Jane Smith',
  'jane.smith@company.com',
  'U02XYZ789',  -- Slack User ID
  'online',
  3,  -- Can handle 3 concurrent chats
  ARRAY['technical', 'billing', 'general'],
  ARRAY['en', 'es', 'fr'],
  NOW(),
  NOW()
);
```

### Finding Slack User ID

```bash
# Method 1: Via Slack UI
1. Click on user's profile in Slack
2. Click "..." → "Copy Member ID"

# Method 2: Via Slack API
curl -X GET "https://slack.com/api/users.list" \
  -H "Authorization: Bearer xoxb-your-token"
```

### Updating Agent Status

**Set Online:**
```sql
UPDATE agent_availability
SET status = 'online', updated_at = NOW()
WHERE agent_id = 'agent_jane_smith';
```

**Set Offline:**
```sql
UPDATE agent_availability
SET status = 'offline', updated_at = NOW()
WHERE agent_id = 'agent_jane_smith';
```

**Set Busy:**
```sql
UPDATE agent_availability
SET status = 'busy', updated_at = NOW()
WHERE agent_id = 'agent_jane_smith';
```

### Agent Status Values

- **`online`** - Available for handoffs
- **`offline`** - Not available (won't receive handoffs)
- **`busy`** - Temporary unavailable (won't receive new handoffs)
- **`away`** - Out of office (won't receive handoffs)

### Managing Agent Capacity

```sql
-- Increase max chats
UPDATE agent_availability
SET max_concurrent_chats = 5
WHERE agent_id = 'agent_jane_smith';

-- Reset current chat count (use carefully)
UPDATE agent_availability
SET current_chat_count = 0
WHERE agent_id = 'agent_jane_smith';
```

**Note:** `current_chat_count` is automatically managed by the workflow. Only reset manually if there's a discrepancy.

---

## Handoff Triggers

The main support workflow triggers handoffs in these scenarios:

### 1. User Keywords

User explicitly requests human agent:

```javascript
// In main workflow
const triggerKeywords = [
  'speak to human',
  'talk to agent',
  'human support',
  'real person',
  'representative',
  'escalate',
  'manager'
];

if (triggerKeywords.some(kw => userMessage.toLowerCase().includes(kw))) {
  // Create handoff request
  await createHandoffRequest({
    phone_number: user.phone,
    reason: 'user_requested',
    priority: 'medium'
  });
}
```

### 2. Negative Sentiment

AI detects user frustration:

```javascript
// After AI response
if (sentimentScore < 0.3) {
  await createHandoffRequest({
    phone_number: user.phone,
    reason: 'sentiment_negative',
    priority: 'high',
    sentiment_score: sentimentScore
  });
}
```

### 3. Unresolved Queries

AI cannot answer after multiple attempts:

```javascript
// Track AI confidence
if (aiConfidenceScore < 0.5 && attemptCount >= 3) {
  await createHandoffRequest({
    phone_number: user.phone,
    reason: 'unable_to_help',
    priority: 'medium'
  });
}
```

### 4. Manual Escalation

Admin manually creates handoff:

```sql
INSERT INTO handoff_requests (
  phone_number,
  reason,
  priority,
  conversation_context,
  created_at
) VALUES (
  '+1234567890',
  'complex_query',
  'urgent',
  (SELECT conversation_history FROM user_conversations WHERE phone_number = '+1234567890'),
  NOW()
);
```

### Creating Handoff Requests

**Via SQL:**
```sql
INSERT INTO handoff_requests (
  phone_number,
  reason,
  priority,
  conversation_context,
  sentiment_score
)
SELECT
  u.phone_number,
  'user_requested',
  'medium',
  uc.conversation_history,
  NULL
FROM users u
LEFT JOIN user_conversations uc ON u.phone_number = uc.phone_number
WHERE u.phone_number = '+1234567890';
```

**Via n8n Node:**
```javascript
// PostgreSQL node
INSERT INTO handoff_requests (
  phone_number, reason, priority, conversation_context
) VALUES (
  $1, $2, $3, $4
) RETURNING *;

// Parameters:
// $1: {{ $json.phoneNumber }}
// $2: 'user_requested'
// $3: 'medium'
// $4: {{ JSON.stringify($json.conversationHistory) }}
```

---

## Notification Channels

### Slack Notifications

**Features:**
- Rich formatted messages with user context
- Interactive buttons (Accept, View History, Reassign)
- Priority color coding
- Real-time delivery
- Thread-based replies route back to WhatsApp

**Message Format:**
```
🚨 New Handoff Request - HIGH Priority

Customer: John Doe
Phone: +1234567890
Assigned Agent: @jane.smith
Wait Time: 2m 34s
Reason: user_requested
Sentiment: 😊 75%

Recent Conversation:
```
👤 User: I need help with my billing
🤖 AI: I can help with that. What's your question?
👤 User: This is complicated, I need a human
```

[✅ Accept Handoff] [📞 View Full History] [🔄 Reassign]

Handoff ID: abc123 | Language: EN | Assigned: Today at 2:30 PM
```

**Channel Configuration:**

1. Create dedicated channel: `#customer-support` or `#handoffs`
2. Invite n8n Slack bot to channel
3. Set channel in `.env`: `SLACK_HANDOFF_CHANNEL=#customer-support`

**Button Actions (Optional - Requires Custom Slack App):**

To enable interactive buttons:
1. Create Slack app with Interactivity enabled
2. Set Request URL to n8n webhook
3. Create handler workflow for button clicks
4. Update `action_id` values in workflow

### Email Notifications

**Features:**
- HTML formatted with professional design
- Full conversation history
- Quick action links
- Fallback when Slack unavailable
- Supports attachments

**Template Preview:**

```html
Subject: 🔔 New HIGH Priority Handoff - John Doe

[Beautiful HTML email with:]
- Priority badge (color-coded)
- Customer information grid
- Recent conversation timeline
- Quick action buttons
- Handoff details in footer
```

**Email Configuration:**

**Gmail:**
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password  # Not regular password!
SMTP_FROM_EMAIL=support@yourcompany.com
```

**SendGrid:**
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_FROM_EMAIL=support@yourcompany.com
```

**AWS SES:**
```bash
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USER=your-ses-smtp-username
SMTP_PASSWORD=your-ses-smtp-password
SMTP_FROM_EMAIL=support@yourcompany.com
```

### Webhook Notifications

**Features:**
- Integrate with CRM systems (Zendesk, Salesforce, etc.)
- Custom notification systems
- Trigger external workflows
- Full JSON payload

**Payload Format:**
```json
{
  "handoffId": "abc123",
  "phoneNumber": "+1234567890",
  "reason": "user_requested",
  "priority": "high",
  "conversationContext": [...],
  "sentimentScore": 0.75,
  "contactName": "John Doe",
  "languagePreference": "en",
  "waitTimeSeconds": 154,
  "agentId": "agent_jane_smith",
  "agentName": "Jane Smith",
  "agentEmail": "jane@company.com",
  "assignedAt": "2025-12-15T14:30:00Z",
  "isUrgent": true
}
```

**Example Integrations:**

**Zendesk:**
```javascript
// Webhook URL
https://your-domain.zendesk.com/api/v2/tickets.json

// Headers
Authorization: Basic base64(email/token:password)
Content-Type: application/json

// Transform payload in n8n
{
  "ticket": {
    "subject": `Handoff: ${handoffData.contactName}`,
    "comment": {
      "body": `WhatsApp handoff from ${handoffData.phoneNumber}\n\nReason: ${handoffData.reason}\nPriority: ${handoffData.priority}`
    },
    "priority": handoffData.priority,
    "tags": ["whatsapp", "handoff", handoffData.reason]
  }
}
```

**Salesforce:**
```javascript
// Use Salesforce n8n node
// Create Case object with handoff details
```

---

## Message Routing

### Agent → User Messages

When agent replies in Slack thread:

1. **Detect Reply**: Slack event webhook captures thread reply
2. **Route to WhatsApp**: Separate workflow sends via WhatsApp API
3. **Update Session**: Log message in `active_handoffs.conversation_messages`

**Implementation (Separate Workflow Required):**

```javascript
// Slack Event Webhook Trigger
// Event: message.channels (thread replies)

if (slackMessage.thread_ts && isActiveHandoffThread(slackMessage.thread_ts)) {
  const handoff = getActiveHandoff(slackMessage.thread_ts);

  // Send to WhatsApp
  await sendWhatsAppMessage({
    to: handoff.phone_number,
    message: slackMessage.text
  });

  // Log message
  await logHandoffMessage({
    handoff_id: handoff.id,
    direction: 'agent_to_user',
    content: slackMessage.text
  });
}
```

### User → Agent Messages

When user sends WhatsApp message during handoff:

1. **Detect Active Handoff**: Main workflow checks `active_handoffs` table
2. **Route to Slack**: Post as reply in handoff thread
3. **Skip AI Processing**: Don't generate AI response

**Implementation (In Main Workflow):**

```javascript
// After parsing WhatsApp message

const activeHandoff = await checkActiveHandoff(phoneNumber);

if (activeHandoff && activeHandoff.status === 'active') {
  // Route to Slack thread
  await postToSlackThread({
    channel: activeHandoff.slack_channel_id,
    thread_ts: activeHandoff.slack_thread_ts,
    text: `👤 ${contactName}: ${userMessage}`
  });

  // Log message
  await logHandoffMessage({
    handoff_id: activeHandoff.id,
    direction: 'user_to_agent',
    content: userMessage
  });

  // Skip AI processing
  return;
}

// Continue with normal AI flow...
```

### Ending Handoffs

**Method 1: Agent Command (Recommended)**

Agent types `/close` or `/resolve` in Slack thread:

```sql
UPDATE handoff_requests
SET status = 'completed', completed_at = NOW()
WHERE id = $handoff_id;

UPDATE active_handoffs
SET status = 'resolved', ended_at = NOW()
WHERE id = $active_handoff_id;

UPDATE agent_availability
SET current_chat_count = current_chat_count - 1
WHERE agent_id = $agent_id;
```

**Method 2: Timeout (Automatic)**

After 30 minutes of inactivity:

```sql
UPDATE active_handoffs
SET status = 'timeout', ended_at = NOW()
WHERE last_message_at < NOW() - INTERVAL '30 minutes'
  AND status = 'active';
```

**Method 3: User Returns to AI**

User types "back to AI" or similar:

```sql
UPDATE handoff_requests
SET status = 'returned_to_ai', completed_at = NOW()
WHERE id = $handoff_id;
```

---

## Analytics & Monitoring

### Key Metrics

**Handoff Volume:**
```sql
SELECT
  DATE(created_at) as date,
  COUNT(*) as total_handoffs,
  COUNT(CASE WHEN status = 'assigned' THEN 1 END) as assigned,
  COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed
FROM handoff_requests
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

**Average Wait Time:**
```sql
SELECT
  AVG(wait_time_seconds) / 60 as avg_wait_minutes,
  MAX(wait_time_seconds) / 60 as max_wait_minutes,
  priority
FROM handoff_requests
WHERE status IN ('assigned', 'completed')
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY priority
ORDER BY priority;
```

**Agent Performance:**
```sql
SELECT
  hr.assigned_to as agent_id,
  aa.agent_name,
  COUNT(*) as total_handoffs,
  AVG(EXTRACT(EPOCH FROM (hr.completed_at - hr.assigned_at)) / 60) as avg_handle_time_minutes,
  COUNT(CASE WHEN hr.status = 'completed' THEN 1 END)::FLOAT / COUNT(*)::FLOAT * 100 as resolution_rate
FROM handoff_requests hr
LEFT JOIN agent_availability aa ON hr.assigned_to = aa.agent_id
WHERE hr.assigned_at > NOW() - INTERVAL '7 days'
GROUP BY hr.assigned_to, aa.agent_name
ORDER BY total_handoffs DESC;
```

**Handoff Reasons:**
```sql
SELECT
  reason,
  COUNT(*) as count,
  ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) as percentage
FROM handoff_requests
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY reason
ORDER BY count DESC;
```

### Dashboards

**Grafana Dashboard (Example):**

```yaml
panels:
  - title: "Handoffs by Priority (24h)"
    query: >
      SELECT priority, COUNT(*) FROM handoff_requests
      WHERE created_at > NOW() - INTERVAL '24 hours'
      GROUP BY priority

  - title: "Average Wait Time by Hour"
    query: >
      SELECT
        DATE_TRUNC('hour', created_at) as hour,
        AVG(wait_time_seconds) / 60 as avg_wait_minutes
      FROM handoff_requests
      WHERE created_at > NOW() - INTERVAL '7 days'
      GROUP BY hour

  - title: "Agent Availability"
    query: >
      SELECT agent_name, status, current_chat_count, max_concurrent_chats
      FROM agent_availability
      ORDER BY status, current_chat_count DESC
```

### Alerts

**Critical Alerts:**

1. **No Agents Available** (>5 minutes)
   ```sql
   SELECT COUNT(*) FROM handoff_requests
   WHERE status = 'pending'
     AND created_at < NOW() - INTERVAL '5 minutes';
   ```

2. **High Wait Time** (>10 minutes for urgent)
   ```sql
   SELECT COUNT(*) FROM handoff_requests
   WHERE status = 'pending'
     AND priority = 'urgent'
     AND created_at < NOW() - INTERVAL '10 minutes';
   ```

3. **Agent Overload** (>90% capacity)
   ```sql
   SELECT COUNT(*) FROM agent_availability
   WHERE status = 'online'
     AND current_chat_count::FLOAT / max_concurrent_chats::FLOAT > 0.9;
   ```

**Alert Configuration (Example with Slack):**

```javascript
// In n8n workflow
if (urgentPendingCount > 5) {
  await slack.postMessage({
    channel: '#alerts',
    text: `🚨 CRITICAL: ${urgentPendingCount} urgent handoffs waiting >5 minutes!`
  });
}
```

---

## Troubleshooting

### Issue: Handoffs Not Being Assigned

**Symptoms:**
- Handoff requests stuck in "pending" status
- No notifications sent

**Possible Causes:**

1. **Workflow Not Active**
   ```
   Solution: Check workflow is toggled "Active" in n8n
   ```

2. **No Agents Online**
   ```sql
   -- Check agent status
   SELECT * FROM agent_availability WHERE status = 'online';

   -- Solution: Set at least one agent online
   UPDATE agent_availability
   SET status = 'online'
   WHERE agent_id = 'your_agent_id';
   ```

3. **All Agents at Capacity**
   ```sql
   -- Check agent capacity
   SELECT agent_id, current_chat_count, max_concurrent_chats
   FROM agent_availability
   WHERE status = 'online';

   -- Solution: Increase max_concurrent_chats or add more agents
   UPDATE agent_availability
   SET max_concurrent_chats = max_concurrent_chats + 2
   WHERE agent_id = 'your_agent_id';
   ```

4. **Skill Mismatch**
   ```sql
   -- Check handoff required skills vs agent skills
   SELECT hr.id, hr.reason, aa.agent_id, aa.skills
   FROM handoff_requests hr
   CROSS JOIN agent_availability aa
   WHERE hr.status = 'pending'
     AND aa.status = 'online';

   -- Solution: Add 'general' skill to all agents as fallback
   UPDATE agent_availability
   SET skills = array_append(skills, 'general')
   WHERE NOT 'general' = ANY(skills);
   ```

### Issue: Slack Notifications Not Sending

**Symptoms:**
- Handoffs assigned but no Slack message
- Node shows error

**Solutions:**

1. **Invalid Slack Token**
   ```
   Error: "invalid_auth"
   Solution: Regenerate bot token and update credential
   ```

2. **Bot Not in Channel**
   ```
   Error: "channel_not_found"
   Solution: Invite bot to #customer-support channel
   ```

3. **Invalid Channel Name**
   ```
   Error: "channel_not_found"
   Solution: Verify SLACK_HANDOFF_CHANNEL value (must start with #)
   ```

4. **Missing Scopes**
   ```
   Error: "missing_scope"
   Solution: Add these scopes to Slack app:
   - chat:write
   - chat:write.public
   - channels:read
   ```

### Issue: Email Notifications Not Sending

**Symptoms:**
- No emails received
- SMTP errors in logs

**Solutions:**

1. **Gmail: "Less Secure Apps"**
   ```
   Error: "Username and Password not accepted"
   Solution: Use App Password instead of regular password
   - Go to Google Account → Security → App Passwords
   - Generate password for "Mail"
   - Use generated password in SMTP_PASSWORD
   ```

2. **Wrong SMTP Port**
   ```
   Error: "Connection timeout"
   Solution: Use correct port:
   - Port 587: TLS (recommended)
   - Port 465: SSL
   - Port 25: Unencrypted (not recommended)
   ```

3. **Firewall Blocking**
   ```
   Error: "Connection refused"
   Solution: Check firewall allows outbound on port 587/465
   ```

### Issue: Agent Chat Count Not Updating

**Symptoms:**
- current_chat_count stuck at max
- Agents not receiving new handoffs

**Solution:**

```sql
-- Reset all agent chat counts
UPDATE agent_availability
SET current_chat_count = (
  SELECT COUNT(*)
  FROM active_handoffs
  WHERE active_handoffs.agent_id = agent_availability.agent_id
    AND active_handoffs.status = 'active'
);

-- Or reset specific agent
UPDATE agent_availability
SET current_chat_count = 0
WHERE agent_id = 'agent_jane_smith';
```

### Issue: Duplicate Handoffs

**Symptoms:**
- Same user gets multiple handoff requests
- Multiple agents assigned to same conversation

**Solution:**

```sql
-- Add unique constraint to prevent duplicates
CREATE UNIQUE INDEX idx_active_handoff_per_user
ON active_handoffs (phone_number)
WHERE status = 'active';

-- Clean up existing duplicates
DELETE FROM active_handoffs a
USING active_handoffs b
WHERE a.id < b.id
  AND a.phone_number = b.phone_number
  AND a.status = 'active'
  AND b.status = 'active';
```

### Debugging Tips

1. **Check Workflow Execution Logs**
   - n8n → Executions tab
   - Look for red (error) or orange (warning) executions
   - Click execution to see node-by-node results

2. **Test Individual Nodes**
   - Use "Test Workflow" button
   - Manually trigger with sample data
   - Check each node's output

3. **Enable Debug Logging**
   ```bash
   # In .env
   N8N_LOG_LEVEL=debug

   # Restart n8n
   docker-compose restart WPSupport_n8n
   ```

4. **Check Database Directly**
   ```sql
   -- Recent handoffs
   SELECT * FROM handoff_requests
   ORDER BY created_at DESC LIMIT 10;

   -- Active sessions
   SELECT * FROM active_handoffs
   WHERE status = 'active';

   -- Agent status
   SELECT * FROM agent_availability;
   ```

---

## Advanced Configuration

### Custom Skill Routing

Edit the `Analyze Handoff Requirements` node:

```javascript
// Add custom skill mappings
const skillMappings = {
  'billing': ['billing', 'payments', 'invoice', 'refund'],
  'technical': ['bug', 'error', 'not working', 'broken'],
  'sales': ['upgrade', 'pricing', 'plan', 'purchase'],
  'onboarding': ['setup', 'getting started', 'how to'],
  'cancellation': ['cancel', 'close account', 'delete']
};

let requiredSkills = ['general']; // Default

for (const [skill, keywords] of Object.entries(skillMappings)) {
  if (keywords.some(kw => reason.toLowerCase().includes(kw))) {
    requiredSkills = [skill];
    break;
  }
}
```

### Multi-Language Support

Filter agents by language:

```sql
-- Modify Find Available Agent query
SELECT *
FROM agent_availability
WHERE status = 'online'
  AND current_chat_count < max_concurrent_chats
  AND skills && $1::text[]
  AND languages && ARRAY[$2]  -- Add language filter
ORDER BY capacity DESC
LIMIT 1;

-- Parameter $2: {{ $json.languagePreference || 'en' }}
```

### Time-Based Routing

Route to different agents based on time:

```javascript
// In Analyze Handoff Requirements
const hour = new Date().getHours();
const dayOfWeek = new Date().getDay();

let shiftRequirement = [];

if (hour >= 9 && hour < 17 && dayOfWeek >= 1 && dayOfWeek <= 5) {
  shiftRequirement.push('day_shift');
} else if (hour >= 17 && hour < 23) {
  shiftRequirement.push('evening_shift');
} else {
  shiftRequirement.push('night_shift');
}

requiredSkills.push(...shiftRequirement);
```

### Escalation Paths

Auto-escalate if not resolved in 30 minutes:

```sql
-- Create escalation trigger (run every 5 minutes)
UPDATE handoff_requests
SET priority = 'urgent'
WHERE status = 'assigned'
  AND priority != 'urgent'
  AND assigned_at < NOW() - INTERVAL '30 minutes'
  AND completed_at IS NULL;
```

---

## Best Practices

1. **Always have backup agents**: Configure at least 3 agents with `general` skill
2. **Monitor wait times**: Set up alerts for >5 minute wait times
3. **Regular capacity reviews**: Adjust `max_concurrent_chats` based on agent performance
4. **Skill taxonomy**: Keep skills simple and consistent (5-10 total)
5. **Test notifications**: Send test handoffs to verify Slack/Email working
6. **Document agent schedules**: Use `status` field to reflect availability
7. **Archive old handoffs**: Move completed handoffs older than 90 days to archive table
8. **Review handoff reasons**: Identify patterns to improve AI responses

---

## Additional Resources

- **n8n Documentation**: https://docs.n8n.io/
- **Slack API Docs**: https://api.slack.com/messaging
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **WhatsApp Business API**: https://developers.facebook.com/docs/whatsapp

---

**For issues or questions, check:**
- [ARCHITECTURE-V2.md](../docs/ARCHITECTURE-V2.md) - Complete system architecture
- [FEATURES.md](../docs/FEATURES.md) - Enhanced features guide
- [Database Documentation](../db/README.md) - Database schema details

---

**Workflow Version:** 1.0
**Last Updated:** 2025-12-15
**Maintained by:** WhatsApp AI Support Agent Team
