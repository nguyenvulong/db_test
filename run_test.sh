#!/bin/bash

# Start containers
docker compose up -d

# Wait for services to be ready
echo "Waiting for databases to be ready..."
echo "This may take a moment as replication is being established..."
sleep 5  # Increased wait time to ensure replication is established

# Run tests
echo "Running tests..."
./test_script.sh

# Clean up
echo "Cleaning up..."
docker compose down -v
