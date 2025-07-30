#!/usr/bin/env node

// Azure MCP Server wrapper for Claude Code
const { spawn } = require('child_process');

// Set environment variables
process.env.AZURE_SUBSCRIPTION_ID = '8b10df28-e826-4de8-b929-4d5698853b5d';
process.env.AZURE_TENANT_ID = '0dc6b780-5b9e-4809-afb6-6bc499280f23';
process.env.AZURE_CLIENT_ID = '7e7da08a-c540-4e2c-97d5-ab954970484f';
process.env.AZURE_CLIENT_SECRET = 'zqR8Q~3fnNUgSKk1o8vTU9ToFvrVa9jyk~c5Lc2s';

// Start the Azure MCP server
const azureMcp = spawn('npx', ['@azure/mcp@latest', 'server', 'start'], {
  stdio: 'inherit',
  env: process.env
});

azureMcp.on('error', (err) => {
  console.error('Failed to start Azure MCP:', err);
  process.exit(1);
});

azureMcp.on('exit', (code) => {
  process.exit(code);
});