#!/bin/bash

# Impala connection details
IMPALA_HOST="cdp1"
IMPALA_PORT="21000"

# Test timeout values (in seconds)
QUERY_TIMEOUT_VALUES=(1 5 10 30 60 120 180 240 300)

# Create table if not exists
CREATE_TABLE_QUERY="CREATE TABLE IF NOT EXISTS kudu_table1 (id BIGINT PRIMARY KEY, col1 STRING, col2 INT) STORED AS KUDU"

# Test query
TEST_QUERY="SELECT t1.*, t2.*, t3.*, t4.*, t5.*, t6.* FROM kudu_table1 t1 JOIN kudu_table2 t2 ON t1.id = t2.id JOIN kudu_table2 t3 ON t2.id = t3.id JOIN kudu_table2 t4 ON t3.id = t4.id JOIN kudu_table2 t5 ON t4.id = t5.id JOIN kudu_table2 t6 ON t5.id = t6.id WHERE t1.id BETWEEN 1 AND 1000000000 AND t2.id % 2 = 0 AND t1.id % 3 = 0 AND t3.id % 5 = 0 AND t4.id % 7 = 0 AND t5.id % 11 = 0 AND t6.id % 13 = 0"

# Results file
RESULTS_FILE="kudu_timeout_results.csv"
echo "query_timeout_s,success,execution_time_ms,rows_scanned" > $RESULTS_FILE

# Run tests
for timeout in "${QUERY_TIMEOUT_VALUES[@]}"
do
  echo "Testing with QUERY_TIMEOUT_S: ${timeout}s"
  
  # Create table and insert data
  impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "$CREATE_TABLE_QUERY"
  
  # Delete all rows from table before inserting new data
  impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "DELETE FROM kudu_table1"
  
  # Insert test data
  INSERT_DATA_QUERY="INSERT INTO kudu_table1 SELECT id, CONCAT('value', CAST(id AS STRING)), CAST(id % 100 AS INT) FROM (SELECT ROW_NUMBER() OVER(ORDER BY id) AS id FROM kudu_table2 LIMIT 1000000) t"
  impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "$INSERT_DATA_QUERY"
  
  # Set query timeout and execute query
  impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "SET QUERY_TIMEOUT_S=$timeout"
  
  # Execute query and measure time
  start_time=$(date +%s%3N)
  
  if impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "$TEST_QUERY" > /dev/null 2>&1
  then
    success=1
  else
    success=0
  fi
  
  end_time=$(date +%s%3N)
  execution_time=$((end_time - start_time))
  
  # Get rows scanned from query profile
  rows_scanned=$(impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "$TEST_QUERY" --quiet --delimited -B | grep -v '^$' | wc -l)
  
  # Record results
  echo "$timeout,$success,$execution_time,$rows_scanned" >> $RESULTS_FILE
  
  # Wait between tests
  sleep 5
done

echo "Test completed. Results saved to $RESULTS_FILE"
