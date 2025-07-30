#!/bin/bash

# Wait for SQL Server to start
echo "Waiting for SQL Server to start..."
sleep 30

# Run initialization script
echo "Running database initialization..."
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -i /docker-entrypoint-initdb.d/init.sql

echo "Database initialization completed!"