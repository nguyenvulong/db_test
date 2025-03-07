#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Function to execute SQL on master
execute_master() {
    echo "Executing on master: $1"
    docker exec postgres-master psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "$1"
}

# Function to execute SQL on replica
execute_replica() {
    echo "Executing on replica: $1"
    docker exec postgres-replica psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "$1"
}

# Test 0: Verify master data
echo "=== Initial Data ==="
echo "Checking initial data on master and replica..."
execute_master "SELECT * FROM users ORDER BY id;"
execute_replica "SELECT * FROM users ORDER BY id;"

# Test 1: Verify initial replication
echo "=== Initial Replication Test ==="
echo "Verifying initial replication status..."
execute_master "SELECT * FROM verify_replication();"

# Test 2: Insert new record
echo "=== Insert Test ==="

echo "Inserting new record: Charlie..."
execute_master "INSERT INTO users (name, email) VALUES ('Charlie', 'charlie@example.com');"

sleep 1 # Allow more time for replication

echo "Verifying replication after insert..."
execute_master "SELECT * FROM verify_replication();"

# Test 3: Update record
echo "=== Update Test ==="

echo "Updating Alice's email address..."
execute_master "UPDATE users SET email = 'alice_new@example.com' WHERE name = 'Alice';"

sleep 1 # Allow more time for replication

echo "Verifying replication after update..."
execute_master "SELECT * FROM verify_replication();"

# Test 4: Delete record
echo "=== Delete Test ==="

echo "Deleting Bob's record..."
execute_master "DELETE FROM users WHERE name = 'Bob';"

sleep 1 # Allow more time for replication

echo "Verifying replication after delete..."
execute_master "SELECT * FROM verify_replication();"

# Test 5: Verify replica data
echo "=== Final Replica Data ==="

echo "Checking final data on master..."
execute_master "SELECT * FROM users ORDER BY id;"

echo "Checking final data on replica..."
execute_replica "SELECT * FROM users ORDER BY id;"

echo "=== Tests Completed ==="
