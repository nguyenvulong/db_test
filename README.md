# PostgreSQL Replication Experiment

This project demonstrates and tests PostgreSQL logical replication between a master and replica database using Docker containers.

## Overview

The experiment sets up two PostgreSQL 15 instances:
- **Master Database**: The primary database where all write operations occur
- **Replica Database**: A secondary database that replicates data from the master

The setup uses PostgreSQL's logical replication feature to synchronize data between the master and replica databases. Various tests are performed to verify that changes made to the master database are properly replicated to the replica.

## Prerequisites

- Docker and Docker Compose
- Bash shell
- Git (for cloning the repository)

## Project Structure

```
.
├── docker-compose.yml      # Docker Compose configuration
├── .env                    # Environment variables
├── pg_hba.conf             # PostgreSQL host-based authentication configuration
├── setup-master.sql        # SQL setup script for master database
├── setup-replica.sql       # SQL setup script for replica database
├── run_test.sh             # Main script to run the experiment
└── test_script.sh          # Test script to verify replication
```

## Configuration

### Docker Compose Configuration

The `docker-compose.yml` file defines two PostgreSQL services:

1. **postgres-master**:
   - Runs on port 5432
   - Configured with logical replication parameters:
     - `wal_level=logical`
     - `max_replication_slots=10`
     - `max_wal_senders=10`
   - Uses `setup-master.sql` for initialization
   - Uses custom `pg_hba.conf` for authentication

2. **postgres-replica**:
   - Runs on port 5433
   - Uses `setup-replica.sql` for initialization
   - Depends on the master database being healthy

### Environment Variables

The `.env` file contains the following variables:

```
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin123
POSTGRES_DB=demo_db
POSTGRES_HOST=localhost
POSTGRES_MASTER_PORT=5432
POSTGRES_REPLICA_PORT=5433
```

## Replication Setup

The replication is set up through the initialization scripts:

1. `setup-master.sql`:
   - Sets system parameters for logical replication
   - Creates a `replicator` role with appropriate permissions
   - Creates a sample `users` table with initial data (Alice and Bob)
   - Creates a publication `my_publication` for all tables
   - Creates a `verify_replication()` function that uses dblink to check if data is synchronized

2. `setup-replica.sql`:
   - Creates the same `users` table structure
   - Creates a subscription `my_subscription` to the master's publication

### Host-Based Authentication Configuration

The `pg_hba.conf` file configures PostgreSQL's client authentication:

- Allows local connections with trust authentication
- Allows replication connections from the replicator user
- Allows all connections from the Docker network with MD5 password authentication

## Running the Experiment

1. Ensure all files are in place and have execution permissions:

   ```bash
   chmod +x run_test.sh test_script.sh
   ```

2. Run the experiment:

   ```bash
   ./run_test.sh
   ```

   This script will:
   - Start the Docker containers with `docker compose up -d`
   - Wait for 5 seconds for the databases to be ready and replication to be established
   - Run the test script
   - Clean up by removing containers and volumes with `docker compose down -v`

## Test Workflow

The `test_script.sh` script loads environment variables from `.env` and performs the following tests:

1. **Initial Replication Test**:
   - Verifies that the initial data (Alice and Bob) is replicated correctly
   - Uses the `verify_replication()` function to check synchronization

2. **Insert Test**:
   - Inserts a new record into the `users` table on the master:
     ```sql
     INSERT INTO users (name, email) VALUES ('Charlie', 'charlie@example.com');
     ```
   - Waits 1 second for replication to occur
   - Verifies that the record is replicated to the replica

3. **Update Test**:
   - Updates Alice's email in the `users` table on the master:
     ```sql
     UPDATE users SET email = 'alice_new@example.com' WHERE name = 'Alice';
     ```
   - Waits 1 second for replication to occur
   - Verifies that the update is replicated to the replica

4. **Delete Test**:
   - Deletes Bob's record from the `users` table on the master:
     ```sql
     DELETE FROM users WHERE name = 'Bob';
     ```
   - Waits 1 second for replication to occur
   - Verifies that the deletion is replicated to the replica

5. **Final Verification**:
   - Displays all records in the `users` table on the replica to confirm the final state

## Verification Function

The `verify_replication()` function in `setup-master.sql` is used throughout the tests to check if the data in the master and replica databases is synchronized. This function:

1. Uses the `dblink` extension to connect to the replica database
2. Counts the number of records in the `users` table on both the master and replica
3. Compares the counts and returns:
   - `master_count`: Number of records in the master database
   - `replica_count`: Number of records in the replica database
   - `is_synced`: Boolean indicating if the counts match

## Cleanup

After the tests are complete, the `run_test.sh` script automatically cleans up by removing all containers and volumes:

```bash
docker compose down -v
```

## Manual Testing

If you want to manually test the replication:

1. Start the containers:

   ```bash
   docker compose up -d
   ```

2. Connect to the master database:

   ```bash
   docker exec -it postgres-master psql -U admin -d demo_db
   ```

3. Connect to the replica database:

   ```bash
   docker exec -it postgres-replica psql -U admin -d demo_db
   ```

4. Make changes on the master and verify they appear on the replica:

   ```sql
   -- On master
   INSERT INTO users (name, email) VALUES ('David', 'david@example.com');
   
   -- On replica (after a few seconds)
   SELECT * FROM users WHERE name = 'David';
   ```

5. Clean up when done:

   ```bash
   docker compose down -v
   ```

## Troubleshooting

If replication is not working as expected:

1. Check the PostgreSQL logs:

   ```bash
   docker logs postgres-master
   docker logs postgres-replica
   ```

2. Verify the replication slot is created:

   ```bash
   docker exec postgres-master psql -U admin -d demo_db -c "SELECT * FROM pg_replication_slots;"
   ```

3. Verify the subscription is active:

   ```bash
   docker exec postgres-replica psql -U admin -d demo_db -c "SELECT * FROM pg_subscription;"
   ```

4. Check the replication status:

   ```bash
   docker exec postgres-master psql -U admin -d demo_db -c "SELECT * FROM verify_replication();"
   ```

5. Increase the wait time in `run_test.sh` if replication needs more time to establish.

## Technical Details

### Logical Replication vs. Physical Replication

This experiment uses PostgreSQL's logical replication, which:
- Replicates data changes at the row level
- Allows selective replication of specific tables
- Supports replication between different PostgreSQL versions
- Uses publications and subscriptions to define what gets replicated

### Key PostgreSQL Configuration Parameters

- `wal_level=logical`: Enables logical decoding of the WAL stream
- `max_replication_slots=10`: Maximum number of replication slots
- `max_wal_senders=10`: Maximum number of concurrent connections for WAL streaming