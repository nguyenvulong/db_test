-- Master initialization
-- Set wal_level to logical
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 10;
ALTER SYSTEM SET max_wal_senders = 10;

-- Create dblink extension with proper permissions
CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;

-- Create replication role
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator123';
GRANT USAGE ON SCHEMA public TO replicator;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicator;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO replicator;

-- Create sample table if not exists
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial data if table is empty
INSERT INTO users (name, email)
SELECT 'Alice', 'alice@example.com';
INSERT INTO users (name, email)
SELECT 'Bob', 'bob@example.com';
-- Verify initial data
SELECT * FROM users;

-- Create publication for logical replication
CREATE PUBLICATION my_publication FOR ALL TABLES;

-- Function to verify replication
CREATE OR REPLACE FUNCTION verify_replication() 
RETURNS TABLE (master_count BIGINT, replica_count BIGINT, is_synced BOOLEAN) 
AS $$
DECLARE
    conn TEXT := 'host=postgres-replica dbname=demo_db user=admin password=admin123';
BEGIN
    -- Get count from master
    master_count := (SELECT COUNT(*) FROM users);
    
    -- Connect to replica and get count
    PERFORM dblink_connect('replica_conn', conn);
    RETURN QUERY
    SELECT 
        master_count, 
        COUNT(*)::BIGINT AS replica_count,
        (master_count = COUNT(*)::BIGINT) AS is_synced
    FROM dblink('replica_conn', 'SELECT * FROM users') AS t1(id INT, name TEXT, email TEXT, created_at TIMESTAMP);
    PERFORM dblink_disconnect('replica_conn');
END;
$$ LANGUAGE plpgsql;

-- Update pg_hba.conf to allow replication connections
ALTER SYSTEM SET listen_addresses = '*';