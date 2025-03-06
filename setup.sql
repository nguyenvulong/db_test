-- Master-only initialization
DO $$
BEGIN
  -- Only execute on master
  IF EXISTS (SELECT 1 FROM pg_stat_activity WHERE pid = pg_backend_pid() AND client_addr IS NULL) THEN
    -- Set wal_level to logical
    ALTER SYSTEM SET wal_level = logical;

    -- Create dblink extension with proper permissions
    CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;
    
    -- Create replication role
    CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator123';
    GRANT USAGE ON SCHEMA public TO replicator;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO replicator;

    -- Create sample table if not exists
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Insert initial data if table is empty
    INSERT INTO users (name, email)
    SELECT 'Alice', 'alice@example.com'
    WHERE NOT EXISTS (SELECT 1 FROM users);

    INSERT INTO users (name, email)
    SELECT 'Bob', 'bob@example.com'
    WHERE NOT EXISTS (SELECT 1 FROM users);

    -- Verify initial data
    SELECT * FROM users;

    -- Create replication slot if not exists
    PERFORM * FROM pg_create_physical_replication_slot('replica_slot', true);

    -- Create publication
    CREATE PUBLICATION my_publication FOR ALL TABLES;

    -- Function to verify replication
    CREATE OR REPLACE FUNCTION verify_replication() 
    RETURNS TABLE (master_count BIGINT, replica_count BIGINT) 
    AS $$
    DECLARE
        conn TEXT := 'host=postgres-replica dbname=demo_db user=admin password=admin123';
    BEGIN
        -- Get count from master
        master_count := (SELECT COUNT(*) FROM users);
        
        -- Connect to replica and get count
        PERFORM dblink_connect('replica_conn', conn);
        RETURN QUERY
        SELECT master_count, COUNT(*)::BIGINT AS replica_count
        FROM dblink('replica_conn', 'SELECT * FROM users') AS t1(id INT, name TEXT, email TEXT, created_at TIMESTAMP);
        PERFORM dblink_disconnect('replica_conn');
    END;
    $$ LANGUAGE plpgsql;

    -- Verify replication status
    SELECT * FROM verify_replication();
  END IF;
END $$;
