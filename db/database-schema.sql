-- PostgreSQL Database Schema for WhatsApp AI Support Agent
-- This schema stores conversation history, user data, and analytics

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table - stores WhatsApp user information
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    contact_name VARCHAR(255),
    profile_name VARCHAR(255),
    language_code VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50),
    first_message_at TIMESTAMP DEFAULT NOW(),
    last_message_at TIMESTAMP DEFAULT NOW(),
    total_messages INTEGER DEFAULT 0,
    is_blocked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Conversations table - stores conversation history
CREATE TABLE IF NOT EXISTS user_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    conversation_history JSONB DEFAULT '[]'::jsonb,
    last_message TEXT,
    message_count INTEGER DEFAULT 0,
    session_id UUID DEFAULT uuid_generate_v4(),
    session_started_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_user FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
);

-- Create unique index on phone_number for faster lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_phone ON user_conversations(phone_number);

-- Messages table - detailed message log
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20) NOT NULL,
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    message_type VARCHAR(20) NOT NULL,
    content TEXT,
    media_id VARCHAR(255),
    media_url TEXT,
    media_mime_type VARCHAR(100),
    status VARCHAR(20) DEFAULT 'sent',
    timestamp BIGINT,
    context_message_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_user_messages FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_messages_phone ON messages(phone_number);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);
CREATE INDEX IF NOT EXISTS idx_messages_direction ON messages(direction);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- AI Interactions table - track AI agent performance
CREATE TABLE IF NOT EXISTS ai_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    message_id VARCHAR(255),
    user_input TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    model_used VARCHAR(50),
    tokens_used INTEGER,
    response_time_ms INTEGER,
    confidence_score DECIMAL(3,2),
    context_retrieved JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_user_ai FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ai_interactions_phone ON ai_interactions(phone_number);
CREATE INDEX IF NOT EXISTS idx_ai_interactions_created ON ai_interactions(created_at DESC);

-- Knowledge base table - for RAG (Retrieval Augmented Generation)
CREATE TABLE IF NOT EXISTS knowledge_base (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500),
    content TEXT NOT NULL,
    category VARCHAR(100),
    tags TEXT[],
    source_url TEXT,
    embedding VECTOR(1536), -- For OpenAI embeddings
    metadata JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Note: To use vector similarity search, install pgvector extension
-- CREATE EXTENSION IF NOT EXISTS vector;

CREATE INDEX IF NOT EXISTS idx_knowledge_category ON knowledge_base(category);
CREATE INDEX IF NOT EXISTS idx_knowledge_active ON knowledge_base(is_active);
CREATE INDEX IF NOT EXISTS idx_knowledge_tags ON knowledge_base USING GIN(tags);

-- Analytics table - track usage metrics
CREATE TABLE IF NOT EXISTS analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,2),
    dimensions JSONB,
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analytics_metric ON analytics(metric_name);
CREATE INDEX IF NOT EXISTS idx_analytics_recorded ON analytics(recorded_at DESC);

-- Feedback table - user satisfaction tracking
CREATE TABLE IF NOT EXISTS feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    message_id VARCHAR(255),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_user_feedback FOREIGN KEY (phone_number) REFERENCES users(phone_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_feedback_phone ON feedback(phone_number);
CREATE INDEX IF NOT EXISTS idx_feedback_rating ON feedback(rating);

-- Error logs table - track and debug errors
CREATE TABLE IF NOT EXISTS error_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    error_type VARCHAR(100),
    error_message TEXT,
    stack_trace TEXT,
    phone_number VARCHAR(20),
    context JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_errors_type ON error_logs(error_type);
CREATE INDEX IF NOT EXISTS idx_errors_created ON error_logs(created_at DESC);

-- Functions and Triggers

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON user_conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_updated_at BEFORE UPDATE ON knowledge_base
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to clean old conversations (data retention)
CREATE OR REPLACE FUNCTION cleanup_old_conversations(retention_days INTEGER)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM messages
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get conversation context
CREATE OR REPLACE FUNCTION get_conversation_context(
    user_phone VARCHAR(20),
    message_limit INTEGER DEFAULT 10
)
RETURNS JSONB AS $$
DECLARE
    context JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'role', CASE WHEN direction = 'inbound' THEN 'user' ELSE 'assistant' END,
            'content', content,
            'timestamp', created_at
        ) ORDER BY created_at DESC
    )
    INTO context
    FROM (
        SELECT direction, content, created_at
        FROM messages
        WHERE phone_number = user_phone
        AND content IS NOT NULL
        ORDER BY created_at DESC
        LIMIT message_limit
    ) subquery;

    RETURN COALESCE(context, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- View for active users analytics
CREATE OR REPLACE VIEW active_users_stats AS
SELECT
    COUNT(DISTINCT phone_number) as total_users,
    COUNT(DISTINCT CASE WHEN last_message_at > NOW() - INTERVAL '24 hours' THEN phone_number END) as daily_active_users,
    COUNT(DISTINCT CASE WHEN last_message_at > NOW() - INTERVAL '7 days' THEN phone_number END) as weekly_active_users,
    COUNT(DISTINCT CASE WHEN last_message_at > NOW() - INTERVAL '30 days' THEN phone_number END) as monthly_active_users
FROM users;

-- View for message analytics
CREATE OR REPLACE VIEW message_stats AS
SELECT
    DATE(created_at) as date,
    COUNT(*) as total_messages,
    COUNT(CASE WHEN direction = 'inbound' THEN 1 END) as inbound_messages,
    COUNT(CASE WHEN direction = 'outbound' THEN 1 END) as outbound_messages,
    COUNT(DISTINCT phone_number) as unique_users
FROM messages
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- View for AI performance metrics
CREATE OR REPLACE VIEW ai_performance_stats AS
SELECT
    DATE(created_at) as date,
    model_used,
    COUNT(*) as total_interactions,
    AVG(response_time_ms) as avg_response_time_ms,
    AVG(tokens_used) as avg_tokens_used,
    AVG(confidence_score) as avg_confidence_score
FROM ai_interactions
GROUP BY DATE(created_at), model_used
ORDER BY date DESC, model_used;

-- Insert some sample knowledge base entries
INSERT INTO knowledge_base (title, content, category, tags) VALUES
    (
        'What is n8n?',
        'n8n is a fair-code licensed workflow automation tool. It allows you to connect various services and create powerful automation workflows. n8n can be self-hosted or used via n8n Cloud.',
        'general',
        ARRAY['n8n', 'introduction', 'basics']
    ),
    (
        'How to create a workflow in n8n',
        'To create a workflow in n8n: 1) Click the + button in the top right, 2) Add nodes by clicking the + icon, 3) Connect nodes by dragging from one to another, 4) Configure each node with your credentials and settings, 5) Test your workflow, 6) Activate it when ready.',
        'tutorials',
        ARRAY['workflow', 'creation', 'tutorial']
    ),
    (
        'n8n pricing',
        'n8n offers several options: Free self-hosted version with full features, n8n Cloud starting at $20/month with 2,500 executions, and custom enterprise plans. Self-hosting is completely free with no limitations.',
        'pricing',
        ARRAY['pricing', 'plans', 'cost']
    ),
    (
        'WhatsApp node in n8n',
        'The WhatsApp Business Cloud node in n8n allows you to send and receive WhatsApp messages. You need a Meta Business Account and WhatsApp Business API access. The node supports text messages, media, templates, and interactive messages.',
        'integrations',
        ARRAY['whatsapp', 'integration', 'messaging']
    ),
    (
        'Webhook trigger in n8n',
        'The Webhook trigger node listens for HTTP requests. You can use GET or POST methods, configure response modes, and handle authentication. Webhooks are perfect for receiving data from external services like WhatsApp, GitHub, or custom applications.',
        'nodes',
        ARRAY['webhook', 'trigger', 'http']
    )
ON CONFLICT DO NOTHING;

-- Grant permissions (adjust user as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_db_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_db_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO your_db_user;

COMMENT ON TABLE users IS 'Stores WhatsApp user profiles and metadata';
COMMENT ON TABLE user_conversations IS 'Stores conversation history in JSONB format for context';
COMMENT ON TABLE messages IS 'Detailed message log for all inbound and outbound messages';
COMMENT ON TABLE ai_interactions IS 'Tracks AI agent interactions for performance monitoring';
COMMENT ON TABLE knowledge_base IS 'Stores knowledge base articles for RAG';
COMMENT ON TABLE analytics IS 'General purpose analytics and metrics';
COMMENT ON TABLE feedback IS 'User feedback and satisfaction ratings';
COMMENT ON TABLE error_logs IS 'Error tracking and debugging';
