# Test Runner Project

This project provides an automated test environment using Docker containers with MariaDB as the database backend.

## Prerequisites

### Required Software
- Docker and Docker Compose
- `uv` package manager

### Installing Prerequisites

1. Install Python dependencies using `uv`:
   ```bash
   # Install uv if you haven't already
   curl -LsSf https://astral.sh/uv/install.sh | sh

   # Create and activate virtual environment
   uv venv
   source .venv/bin/activate

   # Install dependencies
   uv pip install -r requirements.txt
   uv sync
   ```

## Setup

1. Create a `.env` file in the project root with the following variables:
   ```env
   # MariaDB settings
    MARIADB_ROOT_PASSWORD=rootpassword
    MARIADB_USER=test
    MARIADB_PASSWORD=testpassword

    # Database settings
    DB_HOST=mariadb_container
    DB_PORT=3306
    DB_NAME=testdb
    DB_USER=root
    DB_PASS=rootpassword
    NUM_QUERIES=101 
   ```

2. Make sure the `run_test.sh` script is executable:
   ```bash
   chmod +x run_test.sh
   ```

## Running Tests

The test suite can be executed using the provided shell script:
```bash
./run_test.sh
```

The script will:
1. Load environment variables from `.env`
2. Create necessary directories
3. Start the MariaDB container
4. Wait for MariaDB to be ready
5. Initialize the database using `setup.sql`
6. Verify the database initialization
7. Start additional containers (container1 and container2)
8. Execute the tests
9. Run analysis on the results
10. Clean up by stopping all containers

## Results

Test results will be stored in the `results` directory.

## Analysis

After the tests complete, the script will automatically run `analyze_results.py` to process the test results.

## Cleanup

The script automatically cleans up by running `docker compose down` after completion. However, if you need to clean up manually, you can run:
```bash
docker compose down
```

## Troubleshooting

If you encounter any issues:
1. Check if the `.env` file exists and contains the correct credentials
2. Ensure Docker is running
3. Verify that all required ports are available
4. Check Docker logs for any container-specific issues:
   ```bash
   docker compose logs
   ```

## Contributing

Please read our contributing guidelines before submitting pull requests.

## License

MIT License
