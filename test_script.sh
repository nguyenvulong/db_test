#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Function to execute SQL on master
execute_master() {
    docker exec postgres-master psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "$1"
}

# Function to execute SQL on replica
execute_replica() {
    docker exec postgres-replica psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "$1"
}
# Test 0: Verify master data
echo "=== Initial Master and Replica Data ==="
execute_master "SELECT * FROM users ORDER BY id;"
execute_replica "SELECT * FROM users ORDER BY id;"

# Test 1: Verify initial replication
echo "=== Initial Replication Test ==="
execute_master "SELECT * FROM verify_replication();"

# Test 2: Insert new record
echo "=== Insert Test ==="
execute_master "INSERT INTO users (name, email) VALUES ('Charlie', 'charlie@example.com');"
sleep 1 # Allow more time for replication
execute_master "SELECT * FROM verify_replication();"

# Test 3: Update record
echo "=== Update Test ==="
execute_master "UPDATE users SET email = 'alice_new@example.com' WHERE name = 'Alice';"
sleep 1 # Allow more time for replication
execute_master "SELECT * FROM verify_replication();"

# Test 4: Delete record
echo "=== Delete Test ==="
execute_master "DELETE FROM users WHERE name = 'Bob';"
sleep 1 # Allow more time for replication
execute_master "SELECT * FROM verify_replication();"

# Test 5: Verify replica data
echo "=== Final Replica Data ==="
execute_replica "SELECT * FROM users ORDER BY id;"

echo "=== Tests Completed ==="
