-- Data Retention & Deletion Job - Database Schema Initialization
-- GDPR-compliant audit trail and policy management tables

CREATE TABLE IF NOT EXISTS deletion_audit_logs (
    id SERIAL PRIMARY KEY,
    policy_name VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    record_count INTEGER DEFAULT 0,
    filter_criteria TEXT NOT NULL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'pending',
    error_message TEXT,
    deleted_by VARCHAR(255) DEFAULT 'retention_job',
    dry_run BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS retention_policies (
    id SERIAL PRIMARY KEY,
    policy_name VARCHAR(255) UNIQUE NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    retention_days INTEGER NOT NULL,
    date_column VARCHAR(255) NOT NULL,
    filter_conditions TEXT,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for query performance
CREATE INDEX idx_deletion_audit_policy ON deletion_audit_logs(policy_name);
CREATE INDEX idx_deletion_audit_status ON deletion_audit_logs(status);
CREATE INDEX idx_deletion_audit_executed ON deletion_audit_logs(executed_at);
CREATE INDEX idx_retention_policy_enabled ON retention_policies(enabled);

-- Grant permissions (adjust as needed)
GRANT SELECT, INSERT, UPDATE, DELETE ON deletion_audit_logs TO retention_user;
GRANT SELECT ON retention_policies TO retention_user;
