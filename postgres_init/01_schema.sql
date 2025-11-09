-- Web Analytics Platform Database Schema
-- This schema supports tracking users, sessions, events, and computed analytics

-- Users table (optional, for user tracking)
CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(255) PRIMARY KEY,
    first_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_sessions INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    session_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    duration_seconds INT,
    page_views INT DEFAULT 0,
    clicks INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Raw events table (for archival/debugging)
CREATE TABLE IF NOT EXISTS events (
    event_id VARCHAR(255) PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    user_id VARCHAR(255),
    session_id VARCHAR(255),
    page_path VARCHAR(500),
    button_id VARCHAR(255),
    event_time TIMESTAMP NOT NULL,
    props JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Page engagement analytics (computed by PySpark)
CREATE TABLE IF NOT EXISTS page_engagement (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    page_path VARCHAR(500) NOT NULL,
    total_visits INT DEFAULT 0,
    total_time_seconds BIGINT DEFAULT 0,
    avg_time_seconds FLOAT DEFAULT 0,
    unique_users INT DEFAULT 0,
    unique_sessions INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date, page_path)
);

-- Session metrics (computed by PySpark)
CREATE TABLE IF NOT EXISTS session_metrics (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    total_sessions INT DEFAULT 0,
    avg_duration_seconds FLOAT DEFAULT 0,
    avg_page_views FLOAT DEFAULT 0,
    avg_clicks FLOAT DEFAULT 0,
    unique_users INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date)
);

-- Click-through rates (computed by PySpark)
CREATE TABLE IF NOT EXISTS click_through_rates (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    page_path VARCHAR(500),
    button_id VARCHAR(255),
    views INT DEFAULT 0,
    clicks INT DEFAULT 0,
    ctr FLOAT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date, page_path, button_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_events_event_time ON events(event_time);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_session_id ON events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_event_type ON events(event_type);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started_at ON sessions(started_at);

CREATE INDEX IF NOT EXISTS idx_page_engagement_date ON page_engagement(date);
CREATE INDEX IF NOT EXISTS idx_session_metrics_date ON session_metrics(date);
CREATE INDEX IF NOT EXISTS idx_ctr_date ON click_through_rates(date);

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE analytics TO analytics;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO analytics;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO analytics;

