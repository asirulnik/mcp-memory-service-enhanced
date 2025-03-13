#!/bin/bash

# start_memory_service.sh - Simple script to start MCP Memory Service with improved logging

# Enable error reporting
set -e
set -o pipefail

# Change to the MCP Memory Service directory
cd "$(dirname "$0")"
echo "Working directory: $(pwd)"

# Create logs directory if it doesn't exist
mkdir -p logs
echo "Created logs directory: $(pwd)/logs"

# Activate virtual environment if it exists
if [ -d "venv" ] && [ -f "venv/bin/python" ]; then
    source venv/bin/activate
    echo "Activated virtual environment: $(which python)"
else
    echo "WARNING: Virtual environment not properly configured at $(pwd)/venv"
    echo "Attempting to use system Python..."
fi

# Add src directory to Python path
export PYTHONPATH="$(pwd)/src:$PYTHONPATH"
echo "Set PYTHONPATH to include src directory: $PYTHONPATH"

# Make sure we're using a Python interpreter
if [ -z "$(which python)" ]; then
    if [ -f "venv/bin/python" ]; then
        echo "Using Python from virtual environment directly"
        PYTHON="$(pwd)/venv/bin/python"
    elif [ -n "$(which python3)" ]; then
        echo "Using system Python3"
        PYTHON="$(which python3)"
    else
        echo "ERROR: Cannot find any Python interpreter"
        exit 1
    fi
else
    PYTHON="$(which python)"
fi

echo "Using Python interpreter: $PYTHON"

# Basic validation check
if ! $PYTHON -c "import mcp_memory_service" 2>/dev/null; then
    echo "ERROR: Cannot import mcp_memory_service module. Check your Python environment."
    echo "Current Python: $PYTHON"
    echo "PYTHONPATH: $PYTHONPATH"
    
    # Try installing the package in development mode if it's missing
    if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        echo "Attempting to install the package in development mode..."
        $PYTHON -m pip install -e .
        
        # Try importing again
        if ! $PYTHON -c "import mcp_memory_service" 2>/dev/null; then
            echo "Installation failed. Cannot import mcp_memory_service module."
            exit 1
        else
            echo "Successfully installed and imported mcp_memory_service module."
        fi
    else
        echo "No setup.py or pyproject.toml found. Cannot install the module."
        exit 1
    fi
fi

echo "Starting MCP Memory Service with improved logging..."
echo "Full logs will be saved to: $(pwd)/logs/memory_service.log"
echo ""

# Add timestamp to debugging log
echo "$(date) - Starting server" > logs/startup_debug.log

# Run the server with debug logging and basic error handling in background
$PYTHON -m mcp_memory_service.server \
  --debug > logs/memory_service.log 2>&1 &

# Save PID to file
echo $! > logs/server.pid

echo "Server started in background with PID $(cat logs/server.pid)"
echo "Log file: $(pwd)/logs/memory_service.log"

# Note: Server is running in background
echo "To stop the server, use: kill $(cat logs/server.pid)"
echo "To check server status: ps -p $(cat logs/server.pid) > /dev/null && echo 'Running' || echo 'Not running'"
echo "To view logs: tail -f logs/memory_service.log"
