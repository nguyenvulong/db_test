#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Create directories, make sure to remove previous `results`
mkdir -p results

# Start only the MariaDB container first
echo "Starting MariaDB container..."
docker compose up -d mariadb

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until docker exec mariadb_container mariadb -u"${DB_USER}" -p"${DB_PASS}" -e "SELECT 1;" >/dev/null 2>&1; do
    echo "MariaDB is unavailable - sleeping"
    sleep 1
done

echo "MariaDB is up - initializing database"
docker exec -i mariadb_container mariadb -u"${DB_USER}" -p"${DB_PASS}" < setup.sql

# Verify the database was initialized correctly
echo "Verifying database initialization..."
docker exec mariadb_container mariadb -u"${DB_USER}" -p"${DB_PASS}" -e "SELECT COUNT(*) FROM tasks;" ${DB_NAME}

# Now start the other containers after DB is initialized and verified
echo "Database initialized and verified - starting other containers..."
docker compose up --build container1 container2

# Execute your tests by running a specific service or command
echo "Executing tests"

# After the test completes, run the analysis
echo "Running analysis script..."
python analyze_results.py

# Clean up
docker compose down
