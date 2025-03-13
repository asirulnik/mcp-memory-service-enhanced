#!/bin/bash

# debug_memory_service.sh - Debug script with foreground operation and verbose output

# Enable error reporting
set -e
set -o pipefail

# Change to the MCP Memory Service directory
cd "$(dirname "$0")"
echo "Working directory: $(pwd)"

# Determine the Python interpreter to use
if [ -f "venv/bin/python" ]; then
    PYTHON="$(pwd)/venv/bin/python"
    echo "Using Python from virtual environment: $PYTHON"
    
    # Try to activate the virtual environment
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        echo "Activated virtual environment"
    fi
elif [ -n "$(which python3)" ]; then
    PYTHON="$(which python3)"
    echo "Using system Python3: $PYTHON"
else
    echo "ERROR: Cannot find any Python interpreter"
    exit 1
fi

# Add src directory to Python path
export PYTHONPATH="$(pwd)/src:$PYTHONPATH"
echo "Set PYTHONPATH to include src directory: $PYTHONPATH"

# Create logs directory if it doesn't exist
mkdir -p logs

# Test if the server can be executed
echo "Testing if the server module can be executed..."
$PYTHON -c "import mcp_memory_service.server; print('Module can be imported successfully')"

# Run the server in debug mode with foreground execution
echo "Starting MCP Memory Service in debug mode (foreground)..."
echo "Press Ctrl+C to stop the server"
echo ""

# Force unbuffered output for immediate logging
export PYTHONUNBUFFERED=1

# Run the server in foreground with verbose debug output
exec $PYTHON -m mcp_memory_service.server --debug
