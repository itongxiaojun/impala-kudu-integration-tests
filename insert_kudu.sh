#!/bin/bash

# Impala connection details
IMPALA_HOST="cdp1"
IMPALA_PORT="21000"

# Set Kudu scan timeout to 600 seconds
export KUDU_SCAN_TIMEOUT_MS=600000

# Generate and insert 100,000 rows of data in batches
BATCH_SIZE=1000
for ((i=1; i<=100000; i+=BATCH_SIZE))
do
  VALUES=""
  for ((j=i; j<i+BATCH_SIZE && j<=100000; j++))
  do
    VALUES+="($j, 'user$j'),"
  done
  # Remove trailing comma
  VALUES=${VALUES%,}
  
  SQL_QUERY="INSERT INTO kudu_table2 VALUES $VALUES"
  
  impala-shell -i $IMPALA_HOST:$IMPALA_PORT -q "$SQL_QUERY"
  
  # Print progress after each batch
  echo "Inserted $((i+BATCH_SIZE-1)) rows..."
  
  # Add small delay between batches
  sleep 1
done

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Data inserted successfully!"
else
    echo "Failed to insert data."
fi
