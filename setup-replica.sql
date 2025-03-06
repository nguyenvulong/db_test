-- Replica initialization
-- Create dblink extension
CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;

-- Create sample table with the same structure as master
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create subscription to master's publication
-- This will automatically start replicating data from the master
CREATE SUBSCRIPTION my_subscription
CONNECTION 'host=postgres-master dbname=demo_db user=replicator password=replicator123'
PUBLICATION my_publication;