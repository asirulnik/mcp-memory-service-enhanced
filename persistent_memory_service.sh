#!/bin/bash

# persistent_memory_service.sh - Robust script to start and monitor MCP Memory Service

# Enable error reporting
set -e
set -o pipefail

# Change to the MCP Memory Service directory
cd "$(dirname "$0")"
echo "Working directory: $(pwd)"

# Create logs directory if it doesn't exist
mkdir -p logs
echo "Created logs directory: $(pwd)/logs"

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

# Check for mcp_memory_service module
if ! $PYTHON -c "import mcp_memory_service" 2>/dev/null; then
    echo "ERROR: Cannot import mcp_memory_service module. Attempting to install..."
    
    # Try installing the package in development mode if it's missing
    if [ -f "pyproject.toml" ]; then
        echo "Installing from pyproject.toml..."
        $PYTHON -m pip install -e .
    else
        echo "No pyproject.toml found. Creating minimal setup..."
        echo "from setuptools import setup, find_packages
setup(
    name='mcp_memory_service',
    version='0.1',
    package_dir={'': 'src'},
    packages=find_packages(where='src'),
)" > setup.py
        $PYTHON -m pip install -e .
    fi
    
    # Try importing again
    if ! $PYTHON -c "import mcp_memory_service" 2>/dev/null; then
        echo "Installation failed. Cannot import mcp_memory_service module."
        exit 1
    else
        echo "Successfully installed and imported mcp_memory_service module."
    fi
fi

# Add timestamp to debugging log
echo "$(date) - Starting server with persistent monitoring" > logs/startup_debug.log

# Kill any existing processes
pkill -f "mcp_memory_service.server" || true
echo "Cleaned up any existing server processes"

# Start the server as a background process but with nohup to keep it running
echo "Starting MCP Memory Service with persistent monitoring..."
export PYTHONUNBUFFERED=1  # Force Python to use unbuffered output
nohup $PYTHON -m mcp_memory_service.server --debug > logs/memory_service.log 2>&1 &

# Save PID to file
echo $! > logs/server.pid
echo "Server started with PID $(cat logs/server.pid)"

# Wait a moment to make sure it's running
sleep 2

# Check if process is still running
if ps -p $(cat logs/server.pid) > /dev/null; then
    echo "Server successfully started and is still running"
    echo "Log file: $(pwd)/logs/memory_service.log"
    echo "To stop the server, use: kill $(cat logs/server.pid)"
    echo "To check server status: ps -p $(cat logs/server.pid) > /dev/null && echo 'Running' || echo 'Not running'"
    echo "To view logs: tail -f logs/memory_service.log"
else
    echo "WARNING: Server started but stopped immediately. Check the logs for errors:"
    cat logs/memory_service.log
    exit 1
fi

# Set up a watchdog to restart the service if it crashes
cat > logs/watchdog.sh << EOF
#!/bin/bash
while true; do
    if ! ps -p \$(cat $(pwd)/logs/server.pid) > /dev/null; then
        echo "\$(date) - Server crashed, restarting..." >> $(pwd)/logs/watchdog.log
        $(pwd)/persistent_memory_service.sh
        exit 0
    fi
    sleep 10
done
EOF

chmod +x logs/watchdog.sh
nohup logs/watchdog.sh > logs/watchdog.log 2>&1 &
echo "Watchdog started with PID $!"
echo "Watchdog log: $(pwd)/logs/watchdog.log"
