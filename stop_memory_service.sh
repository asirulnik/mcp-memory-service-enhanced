#!/bin/bash

# stop_memory_service.sh - Safely stop the MCP Memory Service

# Change to the script's directory
cd "$(dirname "$0")"
echo "Working directory: $(pwd)"

# Check if PID file exists
if [ ! -f "logs/server.pid" ]; then
    echo "No PID file found. Service may not be running."
    exit 0
fi

# Read PID from file
PID=$(cat logs/server.pid)

# Check if process is running
if ! ps -p $PID > /dev/null; then
    echo "Process with PID $PID is not running."
    rm logs/server.pid
    echo "Removed stale PID file."
    exit 0
fi

# Attempt graceful termination
echo "Stopping MCP Memory Service with PID $PID..."
kill $PID

# Wait for process to terminate
for i in {1..5}; do
    if ! ps -p $PID > /dev/null; then
        echo "Service stopped successfully."
        rm logs/server.pid
        exit 0
    fi
    echo "Waiting for service to stop ($i/5)..."
    sleep 1
done

# Force kill if still running
if ps -p $PID > /dev/null; then
    echo "Service did not terminate gracefully. Forcing termination..."
    kill -9 $PID
    sleep 1
    
    if ! ps -p $PID > /dev/null; then
        echo "Service forcefully terminated."
        rm logs/server.pid
        exit 0
    else
        echo "ERROR: Failed to terminate service. Manual intervention may be required."
        exit 1
    fi
fi
