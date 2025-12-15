# Enhanced Features Guide

This guide covers the four major enhancements to the WhatsApp AI Support Agent:

1. **Human Handoff** - Transfer conversations to live agents
2. **Proactive Messaging** - Send scheduled notifications and updates
3. **Voice Responses** - Generate and send audio replies
4. **Video Support** - Handle and process video messages

---

## 1. Human Handoff

Transfer conversations from AI to human agents when needed.

### When Handoff Occurs

The system automatically triggers handoff in these scenarios:

1. **User Requests** - Keywords like "talk to human", "speak to agent", "human help"
2. **Negative Sentiment** - Frustration or dissatisfaction detected
3. **Unresolved Queries** - AI can't answer after multiple attempts
4. **Manual Escalation** - Agent or admin manually escalates

### Setup

#### 1. Add Agents to Database

```sql
INSERT INTO agent_availability (agent_id, agent_name, agent_email, status, skills)
VALUES
    ('john_smith', 'John Smith', 'john@company.com', 'online', ARRAY['technical', 'billing']),
    ('sarah_j', 'Sarah Johnson', 'sarah@company.com', 'online', ARRAY['sales', 'general']);
```

#### 2. Configure Integration Channel

**Option A: Slack Integration**

1. Create a Slack app: https://api.slack.com/apps
2. Enable incoming webhooks
3. Copy webhook URL to `.env`:
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_HANDOFF_CHANNEL=#customer-support
```

**Option B: Email Integration**

```bash
HANDOFF_EMAIL_TO=support@company.com
HANDOFF_EMAIL_FROM=whatsapp-bot@company.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

**Option C: Custom Webhook**

```bash
HANDOFF_WEBHOOK_URL=https://your-crm.com/api/handoff
HANDOFF_WEBHOOK_AUTH=Bearer your-api-key
```

#### 3. Import Handoff Workflow

1. Import `workflows/human-handoff-workflow.json`
2. Configure credentials (Slack, Email, or HTTP)
3. Activate workflow

### How It Works

```
User Message → Handoff Detection → Create Handoff Request →
Find Available Agent → Notify Agent → Transfer Conversation →
Agent Responds (via Slack/Email/CRM) → Forward to WhatsApp
```

### Handoff Triggers

**Keyword-based handoff:**
```javascript
const handoffKeywords = [
  'human', 'agent', 'representative',
  'speak to someone', 'talk to person',
  'escalate', 'supervisor', 'manager'
];
```

**Sentiment-based handoff:**
```javascript
// Negative sentiment score < 0.3
if (sentimentScore < 0.3) {
  createHandoffRequest(user, 'sentiment_negative');
}
```

**Unresolved query:**
```javascript
// After 3 "I don't understand" responses
if (unresolvedCount >= 3) {
  createHandoffRequest(user, 'unresolved_query');
}
```

### Agent Dashboard

View active handoffs:

```sql
-- Current queue
SELECT * FROM handoff_requests WHERE status = 'pending' ORDER BY priority DESC, created_at ASC;

-- My active chats
SELECT * FROM active_handoffs WHERE agent_id = 'john_smith' AND is_active = true;

-- Performance stats
SELECT * FROM agent_performance WHERE agent_id = 'john_smith';
```

### Agent Response Flow

#### Via Slack

1. Agent receives notification in #customer-support
2. Message includes:
   - User name and phone
   - Conversation context (last 10 messages)
   - Reason for handoff
3. Agent replies in thread
4. Reply automatically sent to WhatsApp

#### Via Email

1. Agent receives email with conversation
2. Reply to email
3. System parses email and sends to WhatsApp

#### Via CRM/Custom System

1. Handoff POST to your webhook:
```json
{
  "handoff_id": "uuid",
  "phone_number": "1234567890",
  "user_name": "John Doe",
  "context": [...],
  "reason": "user_requested",
  "priority": "medium"
}
```

2. Your system handles conversation
3. Send responses via API endpoint

### Close Handoff

When conversation is complete:

```sql
-- Mark as resolved
UPDATE handoff_requests
SET status = 'resolved', resolved_at = NOW()
WHERE id = 'handoff-uuid';

-- End active session
UPDATE active_handoffs
SET is_active = false
WHERE handoff_request_id = 'handoff-uuid';

-- Decrease agent's chat count
UPDATE agent_availability
SET current_chat_count = current_chat_count - 1
WHERE agent_id = 'john_smith';
```

Or use the helper function:

```sql
SELECT resolve_handoff('handoff-uuid', 'john_smith');
```

### Analytics

```sql
-- Daily handoff stats
SELECT * FROM handoff_analytics ORDER BY date DESC LIMIT 30;

-- Agent performance
SELECT
    agent_name,
    total_handoffs_handled,
    resolved_count,
    avg_resolution_minutes
FROM agent_performance
ORDER BY total_handoffs_handled DESC;

-- Average resolution time
SELECT AVG(resolution_time_minutes) as avg_resolution_time
FROM handoff_requests
WHERE status = 'resolved'
AND created_at > NOW() - INTERVAL '7 days';
```

---

## 2. Proactive Messaging

Send scheduled notifications, reminders, and updates to users.

### Use Cases

- Order updates and shipping notifications
- Appointment reminders
- Payment reminders
- Follow-up messages
- Marketing campaigns (with user consent)
- System alerts and maintenance notices

### Setup

1. **Import Workflow**
   - File: `workflows/proactive-messaging-workflow.json`
   - Runs every 5 minutes to check for pending messages

2. **Create Message Templates**

```sql
INSERT INTO message_templates (template_name, template_category, message_content, variables)
VALUES
    (
        'order_shipped',
        'notification',
        'Hi {{name}}! 📦 Your order #{{order_id}} has shipped! Expected delivery: {{delivery_date}}. Track here: {{tracking_url}}',
        '{"name": "string", "order_id": "string", "delivery_date": "string", "tracking_url": "string"}'::jsonb
    ),
    (
        'payment_reminder',
        'reminder',
        'Hello {{name}}, your payment of ${{amount}} is due on {{due_date}}. Pay now: {{payment_link}}',
        '{"name": "string", "amount": "number", "due_date": "string", "payment_link": "string"}'::jsonb
    );
```

### Schedule Individual Messages

#### Via Database

```sql
-- Schedule a single message
SELECT schedule_message(
    '1234567890',  -- phone number
    'Hi John! Your appointment is confirmed for tomorrow at 2 PM.',
    '2025-12-15 09:00:00'::timestamp,  -- when to send
    'reminder',  -- message type
    'appointment_reminder'  -- template name (optional)
);
```

#### Via API

Create an API endpoint in n8n:

```javascript
// POST /api/schedule-message
{
  "phone_number": "1234567890",
  "message": "Your order has shipped!",
  "scheduled_for": "2025-12-15T09:00:00Z",
  "template": "order_shipped",
  "variables": {
    "name": "John",
    "order_id": "12345",
    "delivery_date": "Dec 18",
    "tracking_url": "https://track.example.com/12345"
  }
}
```

### Broadcast Messages (Bulk)

Send to multiple recipients:

```sql
INSERT INTO scheduled_messages (
    phone_numbers,
    message_content,
    message_type,
    scheduled_for
) VALUES (
    ARRAY['1234567890', '0987654321', '1112223333'],
    'Special offer! 20% off all products this weekend. Shop now: https://shop.example.com',
    'marketing',
    NOW() + INTERVAL '1 hour'
);
```

### Campaigns

Create organized campaigns:

```sql
-- Create campaign
INSERT INTO message_campaigns (
    campaign_name,
    campaign_description,
    template_id,
    status,
    scheduled_start
) VALUES (
    'Black Friday 2025',
    'Black Friday promotional campaign',
    (SELECT id FROM message_templates WHERE template_name = 'special_offer'),
    'scheduled',
    '2025-11-29 00:00:00'
);

-- Add recipients
INSERT INTO scheduled_messages (
    phone_numbers,
    message_type,
    template_name,
    message_content,
    scheduled_for
) SELECT
    ARRAY_AGG(phone_number),
    'marketing',
    'special_offer',
    'Black Friday Sale! 50% off everything. Today only!',
    '2025-11-29 08:00:00'
FROM users
WHERE language_code = 'en'
AND is_blocked = false;
```

### Track Campaign Performance

```sql
-- Campaign metrics
SELECT * FROM campaign_performance WHERE campaign_name = 'Black Friday 2025';

-- See delivery, read, and response rates
SELECT
    campaign_name,
    messages_sent,
    messages_delivered,
    messages_read,
    delivery_rate_percent,
    read_rate_percent,
    response_rate_percent
FROM campaign_performance
ORDER BY created_at DESC;
```

### Scheduled Message Status

```sql
-- View pending messages
SELECT * FROM scheduled_messages
WHERE status = 'scheduled'
ORDER BY scheduled_for ASC;

-- View sent messages
SELECT * FROM scheduled_messages
WHERE status = 'sent'
AND sent_at > NOW() - INTERVAL '24 hours'
ORDER BY sent_at DESC;

-- View failed messages
SELECT * FROM scheduled_messages
WHERE status = 'failed'
ORDER BY created_at DESC;
```

### Cancel Scheduled Message

```sql
UPDATE scheduled_messages
SET status = 'cancelled'
WHERE id = 'message-uuid';
```

### Best Practices

1. **Timing**: Respect time zones and quiet hours (no messages 10 PM - 8 AM)
2. **Frequency**: Limit messages to prevent spam (max 1-2 per day per user)
3. **Opt-out**: Provide unsubscribe option for marketing messages
4. **Personalization**: Use templates with variables for better engagement
5. **Testing**: Test on small group before mass broadcast
6. **Compliance**: Follow WhatsApp Business Policy and local regulations (GDPR, TCPA)

---

## 3. Voice Responses

Generate and send audio responses using text-to-speech.

### Setup

1. **Enable in Environment**

```bash
# .env
ENABLE_VOICE_RESPONSES=true
OPENAI_TTS_VOICE=alloy  # Options: alloy, echo, fable, onyx, nova, shimmer
OPENAI_TTS_SPEED=1.0    # 0.25 to 4.0
```

2. **Available Voices**

| Voice | Description | Best For |
|-------|-------------|----------|
| **alloy** | Neutral, balanced | General purpose |
| **echo** | Clear, professional | Business communication |
| **fable** | Warm, friendly | Customer support |
| **onyx** | Deep, authoritative | Formal announcements |
| **nova** | Energetic, upbeat | Marketing, promotions |
| **shimmer** | Soft, soothing | Calm, empathetic responses |

### How It Works

1. AI generates text response
2. System checks user preference for voice
3. Text-to-speech converts response to audio
4. Audio file sent via WhatsApp
5. Cost and usage logged

### User Preferences

Users can enable voice responses:

```sql
-- Enable voice for a user
INSERT INTO user_voice_preferences (phone_number, voice_enabled, voice_name, voice_speed)
VALUES ('1234567890', true, 'fable', 1.0)
ON CONFLICT (phone_number)
DO UPDATE SET voice_enabled = true;
```

**User commands:**
- "Use voice responses" → Enable voice
- "Text responses only" → Disable voice
- "Faster voice" → Increase speed
- "Slower voice" → Decrease speed
- "Change voice" → Select different voice

### Voice Response Logic

```javascript
// Check if user prefers voice
const voicePreference = await checkVoicePreference(phoneNumber);

if (voicePreference.voice_enabled) {
  // Generate audio
  const audio = await generateTTS(responseText, {
    voice: voicePreference.voice_name,
    speed: voicePreference.voice_speed
  });

  // Send audio message
  await sendWhatsAppAudio(phoneNumber, audio);
} else {
  // Send text message
  await sendWhatsAppText(phoneNumber, responseText);
}
```

### Hybrid Mode

Send both text AND voice for accessibility:

```javascript
// Send text first
await sendWhatsAppText(phoneNumber, responseText);

// Then send audio version
await sendWhatsAppAudio(phoneNumber, audioFile);
```

### Cost Tracking

OpenAI TTS pricing: ~$15 per 1M characters

```sql
-- Voice usage and cost
SELECT * FROM voice_usage_stats ORDER BY date DESC LIMIT 30;

-- Monthly cost estimate
SELECT
    DATE_TRUNC('month', created_at) as month,
    SUM(cost_usd) as total_cost,
    COUNT(*) as voice_messages
FROM voice_responses
GROUP BY month
ORDER BY month DESC;
```

### Cost Optimization

1. **Use voice selectively**: Only for complex explanations
2. **Cache common responses**: Store frequently used audio files
3. **Length limits**: Cap responses at 500 characters
4. **User opt-in**: Only send voice when user enables it

```javascript
// Only use voice for long responses
if (responseText.length > 200 && user.voice_enabled) {
  sendVoiceResponse(responseText);
} else {
  sendTextResponse(responseText);
}
```

---

## 4. Video Support

Process and respond to video messages from users.

### Capabilities

1. **Receive Videos**: Download video files from WhatsApp
2. **Extract Metadata**: Duration, size, format
3. **Frame Extraction**: Extract key frames for analysis
4. **Video Analysis**: Analyze content using AI vision
5. **Thumbnail Generation**: Create preview images

### Setup

1. **Enable in Environment**

```bash
# .env
ENABLE_VIDEO_SUPPORT=true
VIDEO_MAX_SIZE_MB=16  # WhatsApp limit
VIDEO_PROCESSING_TIMEOUT=60  # seconds
```

2. **Storage**

Configure cloud storage for video files:

```bash
# AWS S3
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_S3_BUCKET=whatsapp-videos
AWS_REGION=us-east-1

# Or Google Cloud Storage
GCS_PROJECT_ID=your-project
GCS_BUCKET=whatsapp-videos
GCS_KEY_FILE=/path/to/service-account.json
```

### How It Works

```
User Sends Video → Download from WhatsApp → Store in Cloud →
Extract Frames → Analyze with AI Vision → Generate Response →
Send Reply
```

### Video Processing

**Extract Key Frames:**

```javascript
// Extract frame at 1 second, 5 seconds, and 10 seconds
const frames = await extractFrames(videoPath, [1, 5, 10]);

// Analyze each frame with GPT-4 Vision
const analyses = await Promise.all(
  frames.map(frame => analyzeImage(frame))
);

// Combine into video summary
const videoSummary = combineFrameAnalyses(analyses);
```

**AI Analysis:**

```javascript
const analysis = await openai.chat.completions.create({
  model: "gpt-4o",
  messages: [{
    role: "user",
    content: [
      {
        type: "image_url",
        image_url: {url: frameDataUrl}
      },
      {
        type: "text",
        text: "Describe what's happening in this video frame."
      }
    ]
  }]
});
```

### Response Types

#### 1. Content Summary

```
"I can see from your video that you're showing [description].
Based on this, here's how to [solution]..."
```

#### 2. Specific Issue Recognition

```
"I noticed in the video that the error occurs at [timestamp].
This is caused by [issue]. To fix it: [steps]"
```

#### 3. Tutorial Request

```
"Thanks for the video showing what you need help with.
Would you like me to send you a tutorial video on [topic]?"
```

### Video Database Tracking

```sql
-- Video processing history
SELECT
    phone_number,
    video_duration_seconds,
    processing_status,
    analysis_results,
    created_at
FROM video_processing
ORDER BY created_at DESC
LIMIT 20;

-- Failed video processing
SELECT * FROM video_processing
WHERE processing_status = 'failed'
ORDER BY created_at DESC;
```

### Performance Considerations

**Video file sizes:**
- WhatsApp max: 16 MB
- Processing time: ~5-30 seconds depending on length
- Frame extraction: ~1 second per frame
- AI analysis: ~2-5 seconds per frame

**Optimization:**

```javascript
// Only analyze if video is under 30 seconds
if (videoDuration <= 30) {
  await analyzeVideo(videoUrl);
} else {
  // Just acknowledge receipt for long videos
  await sendMessage("Thanks for the video. Due to its length, please describe what you need help with.");
}
```

### Limitations

1. **Size**: WhatsApp limits videos to 16 MB
2. **Duration**: Practical limit of 30-60 seconds for analysis
3. **Cost**: GPT-4 Vision analysis costs ~$0.01-0.03 per video
4. **Speed**: Processing takes 10-30 seconds
5. **Accuracy**: AI may not catch everything in fast-moving videos

### Use Cases

1. **Product Issues**: User shows defective product
2. **How-to Requests**: User shows what they're trying to do
3. **Error Screenshots**: Video of app/website error
4. **Physical Locations**: Video tour of location/property
5. **Installation Help**: Video of installation attempt

### Best Practices

1. **Set Expectations**: Tell users processing may take 10-30 seconds
2. **Provide Guidance**: Ask for clear, well-lit, steady videos
3. **Fallback**: If analysis fails, ask user to describe issue in text
4. **Privacy**: Ensure videos are securely stored and deleted per retention policy

---

## Combined Features Example

Here's how all features work together in a real scenario:

### Scenario: E-commerce Order Support

**Day 1: Order Placed**
```
→ Proactive Message (immediate):
"Hi Sarah! 🎉 Order #12345 confirmed. Total: $99.99. We'll notify you when it ships!"
```

**Day 2: Shipping**
```
→ Proactive Message (scheduled):
"Hi Sarah! 📦 Your order #12345 has shipped! Track: https://track.example/12345"
```

**Day 3: User Question**
```
User (video): [Shows package with damage]

→ Video Analysis:
"I can see the package has damage on the corner. I'm so sorry about this!"

→ Human Handoff (automatic):
System detects issue → Creates handoff → Notifies agent

Agent (via Slack):
"Hi Sarah, I see the damage. We're sending a replacement today at no charge.
You'll receive it by Friday. No need to return the damaged item."

→ Voice Response (optional):
[Sends audio version of response for clarity]
```

**Day 4: Replacement Shipped**
```
→ Proactive Message:
"Good news Sarah! Replacement order #12346 shipped. Arriving Friday!"
```

**Day 5: Delivery & Follow-up**
```
→ Proactive Message:
"Your replacement was delivered! How is everything? Rate us 1-5 ⭐"

User: "5 stars! Thank you!"

→ AI Response:
"Thank you so much Sarah! We appreciate your patience. Enjoy! 🎉"
```

---

## Feature Configuration Summary

### Environment Variables

```bash
# Human Handoff
ENABLE_HUMAN_HANDOFF=true
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
HANDOFF_EMAIL=support@company.com

# Proactive Messaging
ENABLE_PROACTIVE_MESSAGING=true
PROACTIVE_CHECK_INTERVAL=5  # minutes

# Voice Responses
ENABLE_VOICE_RESPONSES=true
OPENAI_TTS_VOICE=alloy
OPENAI_TTS_SPEED=1.0
VOICE_RESPONSE_AUTO=false  # only when user enables

# Video Support
ENABLE_VIDEO_SUPPORT=true
VIDEO_MAX_SIZE_MB=16
VIDEO_FRAME_INTERVAL=5  # seconds
AWS_S3_BUCKET=whatsapp-videos
```

### Database Setup

```bash
# Apply enhanced schema
psql -U n8n_user -d whatsapp_support_agent -f db/database-schema-enhanced.sql
```

### Workflow Setup

```bash
# Import all enhanced workflows
1. whatsapp-support-agent-workflow.json (main - already imported)
2. workflows/proactive-messaging-workflow.json (new)
3. workflows/human-handoff-workflow.json (new)
```

---

## Monitoring & Analytics

### Key Metrics

```sql
-- Human Handoff Performance
SELECT * FROM handoff_analytics ORDER BY date DESC LIMIT 7;

-- Proactive Message Success
SELECT * FROM campaign_performance ORDER BY created_at DESC;

-- Voice Usage
SELECT * FROM voice_usage_stats ORDER BY date DESC LIMIT 7;

-- Video Processing
SELECT
    COUNT(*) as total_videos,
    AVG(video_duration_seconds) as avg_duration,
    COUNT(CASE WHEN processing_status = 'completed' THEN 1 END) as successful
FROM video_processing
WHERE created_at > NOW() - INTERVAL '7 days';
```

### Costs

Monitor feature costs:

```sql
-- Voice response costs
SELECT SUM(cost_usd) as voice_cost
FROM voice_responses
WHERE created_at > NOW() - INTERVAL '30 days';

-- Total AI costs (including video analysis)
SELECT
    SUM(tokens_used) * 0.00000015 as input_cost,
    SUM(tokens_used) * 0.00000060 as output_cost
FROM ai_interactions
WHERE created_at > NOW() - INTERVAL '30 days';
```

---

## Troubleshooting

### Human Handoff Issues

**Problem**: Agents not receiving notifications

**Solutions**:
1. Check Slack webhook URL is correct
2. Verify agent status is 'online'
3. Check handoff workflow is active
4. Review execution logs

**Problem**: Messages not routing to agent

**Solutions**:
1. Verify active_handoffs table has entry
2. Check agent_availability table
3. Ensure agent has capacity (current_chat_count < max_concurrent_chats)

### Proactive Messaging Issues

**Problem**: Messages not sending

**Solutions**:
1. Check scheduled_messages table status
2. Verify proactive workflow is active
3. Ensure scheduled_for time has passed
4. Check WhatsApp credentials

**Problem**: Template variables not replacing

**Solutions**:
1. Verify metadata JSON format is correct
2. Check template variable names match exactly (case-sensitive)
3. Use double curly braces: `{{variable}}`

### Voice Response Issues

**Problem**: No audio sent

**Solutions**:
1. Check ENABLE_VOICE_RESPONSES=true
2. Verify OpenAI API key has TTS access
3. Check user_voice_preferences table
4. Review voice response logs

**Problem**: Poor audio quality

**Solutions**:
1. Adjust OPENAI_TTS_SPEED (try 0.9 or 1.1)
2. Try different voice (echo for clarity)
3. Reduce response length

### Video Support Issues

**Problem**: Video not processing

**Solutions**:
1. Check video size < 16 MB
2. Verify cloud storage credentials
3. Increase VIDEO_PROCESSING_TIMEOUT
4. Check video_processing table for errors

**Problem**: Analysis incorrect

**Solutions**:
1. Extract more frames (increase VIDEO_FRAME_INTERVAL)
2. Use GPT-4o instead of GPT-4o-mini
3. Add specific instructions to vision prompt

---

## Next Steps

1. **Test Each Feature**: Start with one feature at a time
2. **Monitor Costs**: Track API usage daily for first week
3. **Gather Feedback**: Ask users about voice and video experience
4. **Optimize**: Adjust settings based on usage patterns
5. **Scale**: Gradually enable for more users
