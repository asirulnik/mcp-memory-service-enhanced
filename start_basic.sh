#!/bin/bash

# start_basic.sh - Simple script to start MCP Memory Service with minimal modifications

# Enable error reporting
set -e

# Change to the script's directory
cd "$(dirname "$0")"
echo "Working directory: $(pwd)"

# Create logs directory if it doesn't exist
mkdir -p logs
echo "Created logs directory: $(pwd)/logs"

# Use Python from virtual environment
PYTHON="$(pwd)/venv/bin/python"

# Add src directory to Python path
export PYTHONPATH="$(pwd)/src:$PYTHONPATH"
echo "Set PYTHONPATH to include src directory: $PYTHONPATH"

# Start the server in the background
echo "Starting MCP Memory Service..."
nohup $PYTHON -m mcp_memory_service.server > logs/memory_service.log 2>&1 &

# Save PID to file
echo $! > logs/server.pid
echo "Server started with PID $(cat logs/server.pid)"
echo "Log file: $(pwd)/logs/memory_service.log"
echo "To stop the server, use: kill $(cat logs/server.pid)"