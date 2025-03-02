#!/bin/bash

# Configuration
DB_HOST=${DB_HOST:-"mariadb_container"}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-"testdb"}
DB_USER=${DB_USER:-"root"}
DB_PASS=${DB_PASS:-"rootpassword"}
CONTAINER_ID=${CONTAINER_ID:-"unknown"}
NUM_QUERIES=${NUM_QUERIES:-200}
OUTPUT_FILE="/output/results_${CONTAINER_ID}.csv"

# Create output directory
mkdir -p /output

# Add CSV header
echo "container_id,query_number,task_id,task_name,timestamp" >$OUTPUT_FILE

echo "Container $CONTAINER_ID starting $NUM_QUERIES queries..."

# Run the queries
for i in $(seq 1 $NUM_QUERIES); do
  # Execute query and capture results
  result=$(mariadb -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASS $DB_NAME -e "
    START TRANSACTION;
    # Get a row ID that's not selected
    SET @row_id = (
      SELECT id FROM tasks 
      WHERE selected = FALSE 
      LIMIT 1 
      FOR UPDATE SKIP LOCKED
    );

    # Update the row if we found one
    UPDATE tasks 
    SET selected = TRUE 
    WHERE selected = FALSE AND id = @row_id;

    # Return the updated row
    SELECT id, task_name FROM tasks 
    WHERE id = @row_id;

    COMMIT;
    " 2>/dev/null | tail -n 1)

  # If we got a result, save it
  if [ ! -z "$result" ]; then
    task_id=$(echo $result | awk '{print $1}')
    task_name=$(echo $result | awk '{print $2}')
    timestamp=$(date +"%Y-%m-%d %H:%M:%S.%N")
    echo "$CONTAINER_ID,$i,$task_id,$task_name,$timestamp" >>$OUTPUT_FILE
  else
    echo "$CONTAINER_ID,$i,no_result,no_result,$(date +"%Y-%m-%d %H:%M:%S.%N")" >>$OUTPUT_FILE
  fi

  # Optional small random delay to simulate real-world conditions
  sleep 0.$(shuf -i 1-5 -n 1)
done

echo "Container $CONTAINER_ID completed $NUM_QUERIES queries. Results saved to $OUTPUT_FILE"
