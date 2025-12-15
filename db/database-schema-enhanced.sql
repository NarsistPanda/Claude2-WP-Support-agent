-- Additional schema for enhanced features
-- Human Handoff, Proactive Messaging, Voice Responses, Video Support

-- ============================================================================
-- HUMAN HANDOFF FEATURE
-- ============================================================================

-- Handoff requests table - track when users need human assistance
CREATE TABLE IF NOT EXISTS handoff_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    reason VARCHAR(50), -- 'user_requested', 'sentiment_negative', 'unresolved_query', 'escalation'
    priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'assigned', 'in_progress', 'resolved', 'cancelled'
    assigned_to VARCHAR(255), -- agent email or ID
    conversation_context JSONB,
    sentiment_score DECIMAL(3,2),
    escalation_notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    assigned_at TIMESTAMP,
    resolved_at TIMESTAMP,
    resolution_time_minutes INTEGER,
    CONSTRAINT fk_handoff_user FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_handoff_status ON handoff_requests(status);
CREATE INDEX IF NOT EXISTS idx_handoff_priority ON handoff_requests(priority);
CREATE INDEX IF NOT EXISTS idx_handoff_created ON handoff_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_handoff_assigned ON handoff_requests(assigned_to);

-- Agent availability table
CREATE TABLE IF NOT EXISTS agent_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id VARCHAR(255) UNIQUE NOT NULL,
    agent_name VARCHAR(255),
    agent_email VARCHAR(255),
    status VARCHAR(20) DEFAULT 'offline', -- 'online', 'offline', 'busy', 'away'
    max_concurrent_chats INTEGER DEFAULT 5,
    current_chat_count INTEGER DEFAULT 0,
    skills TEXT[], -- ['billing', 'technical', 'sales']
    last_active_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_status ON agent_availability(status);
CREATE INDEX IF NOT EXISTS idx_agent_skills ON agent_availability USING GIN(skills);

-- Active handoff sessions
CREATE TABLE IF NOT EXISTS active_handoffs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    agent_id VARCHAR(255) NOT NULL,
    handoff_request_id UUID,
    channel VARCHAR(50) DEFAULT 'whatsapp', -- 'whatsapp', 'slack', 'email', 'custom'
    integration_data JSONB,
    started_at TIMESTAMP DEFAULT NOW(),
    last_message_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_active_handoff_user FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE,
    CONSTRAINT fk_active_handoff_agent FOREIGN KEY (agent_id) REFERENCES agent_availability(agent_id) ON DELETE CASCADE,
    CONSTRAINT fk_active_handoff_request FOREIGN KEY (handoff_request_id) REFERENCES handoff_requests(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_active_handoff_phone ON active_handoffs(phone_number);
CREATE INDEX IF NOT EXISTS idx_active_handoff_agent ON active_handoffs(agent_id);
CREATE INDEX IF NOT EXISTS idx_active_handoff_active ON active_handoffs(is_active);

-- ============================================================================
-- PROACTIVE MESSAGING FEATURE
-- ============================================================================

-- Scheduled messages table
CREATE TABLE IF NOT EXISTS scheduled_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20),
    phone_numbers TEXT[], -- for bulk messages
    message_type VARCHAR(50), -- 'notification', 'reminder', 'update', 'marketing', 'alert'
    template_name VARCHAR(255),
    message_content TEXT NOT NULL,
    media_url TEXT,
    media_type VARCHAR(20), -- 'image', 'video', 'audio', 'document'
    scheduled_for TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'scheduled', -- 'scheduled', 'sending', 'sent', 'failed', 'cancelled'
    priority INTEGER DEFAULT 0,
    metadata JSONB,
    sent_at TIMESTAMP,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_scheduled_messages_status ON scheduled_messages(status);
CREATE INDEX IF NOT EXISTS idx_scheduled_messages_scheduled ON scheduled_messages(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_scheduled_messages_phone ON scheduled_messages(phone_number);

-- Message templates
CREATE TABLE IF NOT EXISTS message_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(255) UNIQUE NOT NULL,
    template_category VARCHAR(100), -- 'notification', 'reminder', 'welcome', 'followup'
    message_content TEXT NOT NULL,
    variables JSONB, -- {"name": "string", "date": "datetime"}
    media_url TEXT,
    media_type VARCHAR(20),
    language VARCHAR(10) DEFAULT 'en',
    is_active BOOLEAN DEFAULT TRUE,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_templates_category ON message_templates(template_category);
CREATE INDEX IF NOT EXISTS idx_templates_active ON message_templates(is_active);

-- Campaign tracking
CREATE TABLE IF NOT EXISTS message_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_name VARCHAR(255) NOT NULL,
    campaign_description TEXT,
    target_audience JSONB, -- filter criteria
    template_id UUID,
    status VARCHAR(20) DEFAULT 'draft', -- 'draft', 'scheduled', 'running', 'completed', 'paused'
    scheduled_start TIMESTAMP,
    scheduled_end TIMESTAMP,
    total_recipients INTEGER DEFAULT 0,
    messages_sent INTEGER DEFAULT 0,
    messages_delivered INTEGER DEFAULT 0,
    messages_failed INTEGER DEFAULT 0,
    messages_read INTEGER DEFAULT 0,
    responses_received INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    CONSTRAINT fk_campaign_template FOREIGN KEY (template_id) REFERENCES message_templates(id) ON DELETE SET NULL
);

-- Broadcast history
CREATE TABLE IF NOT EXISTS broadcast_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID,
    scheduled_message_id UUID,
    phone_number VARCHAR(20),
    message_id VARCHAR(255), -- WhatsApp message ID
    status VARCHAR(20), -- 'sent', 'delivered', 'read', 'failed'
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    error_message TEXT,
    CONSTRAINT fk_broadcast_campaign FOREIGN KEY (campaign_id) REFERENCES message_campaigns(id) ON DELETE CASCADE,
    CONSTRAINT fk_broadcast_scheduled FOREIGN KEY (scheduled_message_id) REFERENCES scheduled_messages(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_broadcast_campaign ON broadcast_history(campaign_id);
CREATE INDEX IF NOT EXISTS idx_broadcast_phone ON broadcast_history(phone_number);
CREATE INDEX IF NOT EXISTS idx_broadcast_status ON broadcast_history(status);

-- ============================================================================
-- VOICE RESPONSES FEATURE
-- ============================================================================

-- Voice settings per user
CREATE TABLE IF NOT EXISTS user_voice_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    voice_enabled BOOLEAN DEFAULT FALSE,
    voice_name VARCHAR(50) DEFAULT 'alloy', -- OpenAI TTS voices: alloy, echo, fable, onyx, nova, shimmer
    voice_speed DECIMAL(3,2) DEFAULT 1.0,
    language_code VARCHAR(10) DEFAULT 'en',
    prefer_voice_response BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_voice_pref_user FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
);

-- Voice response history
CREATE TABLE IF NOT EXISTS voice_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    message_id VARCHAR(255),
    text_content TEXT NOT NULL,
    voice_name VARCHAR(50),
    audio_url TEXT,
    audio_duration_seconds DECIMAL(5,2),
    file_size_bytes INTEGER,
    tts_provider VARCHAR(50) DEFAULT 'openai', -- 'openai', 'elevenlabs', 'google', 'aws'
    cost_usd DECIMAL(10,4),
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_voice_response_user FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_voice_responses_phone ON voice_responses(phone_number);
CREATE INDEX IF NOT EXISTS idx_voice_responses_created ON voice_responses(created_at DESC);

-- ============================================================================
-- VIDEO SUPPORT FEATURE
-- ============================================================================

-- Extend messages table to support video (already has media fields, but add video-specific)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS video_id VARCHAR(255);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS video_mime_type VARCHAR(100);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS video_caption TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS video_duration_seconds INTEGER;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS video_thumbnail_url TEXT;

-- Video processing history
CREATE TABLE IF NOT EXISTS video_processing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id VARCHAR(255),
    phone_number VARCHAR(20),
    video_url TEXT,
    video_size_bytes BIGINT,
    video_duration_seconds INTEGER,
    video_format VARCHAR(20),
    processing_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    frames_extracted INTEGER,
    analysis_results JSONB, -- AI analysis of video content
    thumbnail_url TEXT,
    error_message TEXT,
    processed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_video_message FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_video_processing_status ON video_processing(processing_status);
CREATE INDEX IF NOT EXISTS idx_video_processing_phone ON video_processing(phone_number);

-- ============================================================================
-- ENHANCED ANALYTICS VIEWS
-- ============================================================================

-- Handoff analytics view
CREATE OR REPLACE VIEW handoff_analytics AS
SELECT
    DATE(created_at) as date,
    COUNT(*) as total_handoffs,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_handoffs,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_handoffs,
    AVG(CASE WHEN resolution_time_minutes IS NOT NULL THEN resolution_time_minutes END) as avg_resolution_minutes,
    COUNT(CASE WHEN priority = 'urgent' THEN 1 END) as urgent_handoffs,
    COUNT(CASE WHEN reason = 'sentiment_negative' THEN 1 END) as sentiment_based_handoffs
FROM handoff_requests
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Campaign performance view
CREATE OR REPLACE VIEW campaign_performance AS
SELECT
    c.campaign_name,
    c.status,
    c.total_recipients,
    c.messages_sent,
    c.messages_delivered,
    c.messages_read,
    c.responses_received,
    CASE
        WHEN c.messages_sent > 0
        THEN ROUND((c.messages_delivered::DECIMAL / c.messages_sent) * 100, 2)
        ELSE 0
    END as delivery_rate_percent,
    CASE
        WHEN c.messages_delivered > 0
        THEN ROUND((c.messages_read::DECIMAL / c.messages_delivered) * 100, 2)
        ELSE 0
    END as read_rate_percent,
    CASE
        WHEN c.messages_sent > 0
        THEN ROUND((c.responses_received::DECIMAL / c.messages_sent) * 100, 2)
        ELSE 0
    END as response_rate_percent,
    c.created_at,
    c.completed_at
FROM message_campaigns c
ORDER BY c.created_at DESC;

-- Agent performance view
CREATE OR REPLACE VIEW agent_performance AS
SELECT
    a.agent_id,
    a.agent_name,
    a.status,
    a.current_chat_count,
    a.max_concurrent_chats,
    COUNT(h.id) as total_handoffs_handled,
    COUNT(CASE WHEN h.status = 'resolved' THEN 1 END) as resolved_count,
    AVG(CASE WHEN h.resolution_time_minutes IS NOT NULL THEN h.resolution_time_minutes END) as avg_resolution_minutes,
    a.last_active_at
FROM agent_availability a
LEFT JOIN handoff_requests h ON h.assigned_to = a.agent_id
GROUP BY a.agent_id, a.agent_name, a.status, a.current_chat_count, a.max_concurrent_chats, a.last_active_at;

-- Voice usage statistics
CREATE OR REPLACE VIEW voice_usage_stats AS
SELECT
    DATE(created_at) as date,
    COUNT(*) as total_voice_responses,
    SUM(audio_duration_seconds) as total_duration_seconds,
    SUM(file_size_bytes) as total_size_bytes,
    SUM(cost_usd) as total_cost_usd,
    AVG(audio_duration_seconds) as avg_duration_seconds,
    COUNT(DISTINCT phone_number) as unique_users
FROM voice_responses
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to find available agent
CREATE OR REPLACE FUNCTION find_available_agent(required_skills TEXT[] DEFAULT NULL)
RETURNS TABLE (
    agent_id VARCHAR(255),
    agent_name VARCHAR(255),
    current_load INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.agent_id,
        a.agent_name,
        a.current_chat_count
    FROM agent_availability a
    WHERE a.status = 'online'
    AND a.current_chat_count < a.max_concurrent_chats
    AND (required_skills IS NULL OR a.skills && required_skills)
    ORDER BY a.current_chat_count ASC, a.last_active_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to create handoff request
CREATE OR REPLACE FUNCTION create_handoff_request(
    user_phone VARCHAR(20),
    handoff_reason VARCHAR(50),
    handoff_priority VARCHAR(20) DEFAULT 'medium',
    context JSONB DEFAULT NULL,
    sentiment DECIMAL(3,2) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_handoff_id UUID;
    available_agent RECORD;
BEGIN
    -- Create handoff request
    INSERT INTO handoff_requests (
        phone_number,
        reason,
        priority,
        conversation_context,
        sentiment_score
    ) VALUES (
        user_phone,
        handoff_reason,
        handoff_priority,
        context,
        sentiment
    )
    RETURNING id INTO new_handoff_id;

    -- Try to auto-assign to available agent
    SELECT * INTO available_agent FROM find_available_agent();

    IF available_agent.agent_id IS NOT NULL THEN
        UPDATE handoff_requests
        SET
            status = 'assigned',
            assigned_to = available_agent.agent_id,
            assigned_at = NOW()
        WHERE id = new_handoff_id;

        -- Update agent chat count
        UPDATE agent_availability
        SET current_chat_count = current_chat_count + 1
        WHERE agent_id = available_agent.agent_id;

        -- Create active handoff session
        INSERT INTO active_handoffs (phone_number, agent_id, handoff_request_id)
        VALUES (user_phone, available_agent.agent_id, new_handoff_id);
    END IF;

    RETURN new_handoff_id;
END;
$$ LANGUAGE plpgsql;

-- Function to schedule a message
CREATE OR REPLACE FUNCTION schedule_message(
    recipient_phone VARCHAR(20),
    message_text TEXT,
    send_time TIMESTAMP,
    msg_type VARCHAR(50) DEFAULT 'notification',
    template VARCHAR(255) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_message_id UUID;
BEGIN
    INSERT INTO scheduled_messages (
        phone_number,
        message_type,
        template_name,
        message_content,
        scheduled_for
    ) VALUES (
        recipient_phone,
        msg_type,
        template,
        message_text,
        send_time
    )
    RETURNING id INTO new_message_id;

    RETURN new_message_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get pending scheduled messages
CREATE OR REPLACE FUNCTION get_pending_scheduled_messages()
RETURNS TABLE (
    id UUID,
    phone_number VARCHAR(20),
    phone_numbers TEXT[],
    message_content TEXT,
    media_url TEXT,
    media_type VARCHAR(20),
    scheduled_for TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        sm.id,
        sm.phone_number,
        sm.phone_numbers,
        sm.message_content,
        sm.media_url,
        sm.media_type,
        sm.scheduled_for
    FROM scheduled_messages sm
    WHERE sm.status = 'scheduled'
    AND sm.scheduled_for <= NOW()
    ORDER BY sm.priority DESC, sm.scheduled_for ASC
    LIMIT 100;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SAMPLE DATA
-- ============================================================================

-- Insert sample agents
INSERT INTO agent_availability (agent_id, agent_name, agent_email, status, skills) VALUES
    ('agent_001', 'John Smith', 'john.smith@company.com', 'online', ARRAY['technical', 'billing']),
    ('agent_002', 'Sarah Johnson', 'sarah.johnson@company.com', 'online', ARRAY['sales', 'general']),
    ('agent_003', 'Mike Chen', 'mike.chen@company.com', 'offline', ARRAY['technical', 'advanced'])
ON CONFLICT (agent_id) DO NOTHING;

-- Insert sample message templates
INSERT INTO message_templates (template_name, template_category, message_content, variables) VALUES
    (
        'welcome_message',
        'welcome',
        'Welcome {{name}}! 👋 Thank you for contacting us. How can we help you today?',
        '{"name": "string"}'::jsonb
    ),
    (
        'order_shipped',
        'notification',
        'Great news {{name}}! Your order #{{order_id}} has been shipped and will arrive by {{delivery_date}}. Track it here: {{tracking_url}}',
        '{"name": "string", "order_id": "string", "delivery_date": "string", "tracking_url": "string"}'::jsonb
    ),
    (
        'appointment_reminder',
        'reminder',
        'Hi {{name}}, this is a reminder about your appointment on {{date}} at {{time}}. Reply CONFIRM to confirm or RESCHEDULE if you need to change it.',
        '{"name": "string", "date": "string", "time": "string"}'::jsonb
    ),
    (
        'feedback_request',
        'followup',
        'Hi {{name}}, how was your experience with our service? We would love to hear your feedback. Rate us 1-5 or share your thoughts.',
        '{"name": "string"}'::jsonb
    )
ON CONFLICT (template_name) DO NOTHING;

-- Update triggers for updated_at
CREATE TRIGGER update_agent_availability_updated_at BEFORE UPDATE ON agent_availability
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_message_templates_updated_at BEFORE UPDATE ON message_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_voice_preferences_updated_at BEFORE UPDATE ON user_voice_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE handoff_requests IS 'Tracks requests for human agent assistance';
COMMENT ON TABLE agent_availability IS 'Manages live agent availability and skills';
COMMENT ON TABLE scheduled_messages IS 'Stores scheduled and proactive messages';
COMMENT ON TABLE message_templates IS 'Reusable message templates with variables';
COMMENT ON TABLE voice_responses IS 'History of voice/audio responses sent';
COMMENT ON TABLE video_processing IS 'Video message processing and analysis';
