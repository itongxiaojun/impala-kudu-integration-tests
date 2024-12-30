#!/bin/bash

# Configuration
IMPALA_HOST="cdp1"
IMPALA_PORT="21000"
KUDU_SCAN_TIMEOUT_MS=600000
BATCH_SIZE=1000
TOTAL_ROWS=1000000
RESULTS_FILE="kudu_performance_results.csv"

# Create Kudu tables
create_tables() {
  echo "Creating Kudu tables..."
  impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "
    CREATE TABLE IF NOT EXISTS kudu_table1 (
      id BIGINT PRIMARY KEY,
      col1 STRING,
      col2 INT
    ) STORED AS KUDU;
    
    CREATE TABLE IF NOT EXISTS kudu_table2 (
      id BIGINT PRIMARY KEY,
      col1 STRING,
      col2 INT
    ) STORED AS KUDU;
  "
}

# Insert data into Kudu tables
insert_data() {
  echo "Inserting data into Kudu tables..."
  export KUDU_SCAN_TIMEOUT_MS
  
  # Insert into kudu_table1
  for ((i=1; i<=TOTAL_ROWS; i+=BATCH_SIZE))
  do
    VALUES=""
    for ((j=i; j<i+BATCH_SIZE && j<=TOTAL_ROWS; j++))
    do
      VALUES+="($j, 'user$j', $((j % 100))),"
    done
    VALUES=${VALUES%,}
    
    SQL_QUERY="INSERT INTO kudu_table1 VALUES $VALUES"
    impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "$SQL_QUERY"
    
    echo "Inserted $((i+BATCH_SIZE-1)) rows into kudu_table1..."
    sleep 1
  done

  # Insert into kudu_table2
  for ((i=1; i<=TOTAL_ROWS; i+=BATCH_SIZE))
  do
    VALUES=""
    for ((j=i; j<i+BATCH_SIZE && j<=TOTAL_ROWS; j++))
    do
      VALUES+="($j, 'user$j', $((j % 100))),"
    done
    VALUES=${VALUES%,}
    
    SQL_QUERY="INSERT INTO kudu_table2 VALUES $VALUES"
    impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "$SQL_QUERY"
    
    echo "Inserted $((i+BATCH_SIZE-1)) rows into kudu_table2..."
    sleep 1
  done
}

# Run performance tests
run_tests() {
  echo "Running performance tests..."
  QUERY_TIMEOUT_VALUES=(1 5 10 30 60 120 180 240 300)
  
  echo "query_timeout_s,success,execution_time_ms,rows_scanned" > $RESULTS_FILE
  
  for timeout in "${QUERY_TIMEOUT_VALUES[@]}"
  do
    echo "Testing with QUERY_TIMEOUT_S: ${timeout}s"
    
    # Set query timeout
    impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "SET QUERY_TIMEOUT_S=$timeout"
    
    # Test query
    TEST_QUERY="SELECT t1.*, t2.*, t3.*, t4.*, t5.*, t6.* 
                FROM kudu_table1 t1 
                JOIN kudu_table2 t2 ON t1.id = t2.id 
                JOIN kudu_table2 t3 ON t2.id = t3.id 
                JOIN kudu_table2 t4 ON t3.id = t4.id 
                JOIN kudu_table2 t5 ON t4.id = t5.id 
                JOIN kudu_table2 t6 ON t5.id = t6.id 
                WHERE t1.id BETWEEN 1 AND 1000000000 
                  AND t2.id % 2 = 0 
                  AND t1.id % 3 = 0 
                  AND t3.id % 5 = 0 
                  AND t4.id % 7 = 0 
                  AND t5.id % 11 = 0 
                  AND t6.id % 13 = 0"
    
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
    
    # Get rows scanned
    rows_scanned=$(impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "$TEST_QUERY" --quiet --delimited -B | grep -v '^$' | wc -l)
    
    # Record results
    echo "$timeout,$success,$execution_time,$rows_scanned" >> $RESULTS_FILE
    
    sleep 5
  done
}

# Main execution
create_tables
insert_data
run_tests

echo "Impala+Kudu integration completed. Results saved to $RESULTS_FILE"
