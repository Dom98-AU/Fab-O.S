#!/bin/bash
# Azure SQL Operations Script

# Load environment variables
source .env

# Function to run SQL query
run_sql() {
    docker run --rm mcr.microsoft.com/mssql-tools /opt/mssql-tools18/bin/sqlcmd \
        -S $AZURE_SQL_SERVER \
        -d $AZURE_SQL_DATABASE \
        -U $AZURE_SQL_USER \
        -P $AZURE_SQL_PASSWORD \
        -C \
        -Q "$1"
}

# Check database status
echo "Checking database status..."
run_sql "SELECT @@VERSION"

# Run migrations
echo "Running migrations..."
for script in Migrations/*.sql; do
    echo "Executing $script..."
    docker run --rm -v $(pwd):/scripts mcr.microsoft.com/mssql-tools /opt/mssql-tools18/bin/sqlcmd \
        -S $AZURE_SQL_SERVER \
        -d $AZURE_SQL_DATABASE \
        -U $AZURE_SQL_USER \
        -P $AZURE_SQL_PASSWORD \
        -C \
        -i /scripts/$script
done

# Check table counts
echo "Checking table counts..."
run_sql "SELECT t.name, p.rows FROM sys.tables t JOIN sys.partitions p ON t.object_id = p.object_id WHERE p.index_id <= 1"

# Monitor performance
echo "Recent slow queries..."
run_sql "SELECT TOP 5 total_elapsed_time/1000 as ms, execution_count, SUBSTRING(text, 1, 100) as query FROM sys.dm_exec_query_stats CROSS APPLY sys.dm_exec_sql_text(sql_handle) ORDER BY total_elapsed_time DESC"