# MCP Memory Service - Implementation Details

## Overview

This document provides detailed information about the implementation of the enhanced MCP Memory Service, focusing on the improvements for standalone operation.

## A. Critical Directory Paths

### Reference Implementation (GitHub)
```
/                                 # Root directory
├── src/                          # Source code
│   └── mcp_memory_service/       # Main package
│       ├── __init__.py
│       ├── config.py             # Configuration
│       ├── server.py             # Server implementation
│       ├── models/               # Data models
│       ├── storage/              # Storage implementation
│       └── utils/                # Utility functions
├── tests/                        # Test suite
├── scripts/                      # Utility scripts
└── venv/                         # Virtual environment (not in repo)
```

### Enhanced Implementation
```
/                                 # Root directory
├── src/                          # Source code
│   └── mcp_memory_service/       # Main package
│       ├── __init__.py
│       ├── config.py             # Configuration (enhanced)
│       ├── server.py             # Server implementation
│       ├── models/               # Data models
│       ├── storage/              # Storage implementation
│       └── utils/                # Utility functions (enhanced)
├── logs/                         # Log directory (added)
├── venv/                         # Virtual environment
├── start_memory_service.sh       # Basic startup script (added)
├── persistent_memory_service.sh  # Persistent mode script (added)
├── debug_memory_service.sh       # Debug mode script (added)
└── stop_memory_service.sh        # Stop script (added)
```

### Default Data Storage Locations
```
# macOS
~/Library/Application Support/mcp-memory/
├── chroma_db/                    # ChromaDB files
└── backups/                      # Database backups

# Windows
%LOCALAPPDATA%\mcp-memory\
├── chroma_db\                    # ChromaDB files
└── backups\                      # Database backups

# Linux
~/.local/share/mcp-memory/
├── chroma_db/                    # ChromaDB files
└── backups/                      # Database backups
```

## B. Key Enhancements

### 1. Configuration Improvements

The enhanced implementation adds significant improvements to configuration handling:

#### Dynamic Base Directory Discovery

```python
def get_base_directory() -> str:
    """Get base directory for storage, with fallback options."""
    # First choice: Environment variable
    if base_dir := os.getenv('MCP_MEMORY_BASE_DIR'):
        return validate_and_create_path(base_dir)
    
    # Second choice: Local app data directory
    home = str(Path.home())
    if sys.platform == 'darwin':  # macOS
        base = os.path.join(home, 'Library', 'Application Support', 'mcp-memory')
    elif sys.platform == 'win32':  # Windows
        base = os.path.join(os.getenv('LOCALAPPDATA', ''), 'mcp-memory')
    else:  # Linux and others
        base = os.path.join(home, '.local', 'share', 'mcp-memory')
    
    return validate_and_create_path(base)
```

#### Path Validation with Write Testing

```python
def validate_and_create_path(path: str) -> str:
    """Validate and create a directory path, ensuring it's writable."""
    try:
        # Convert to absolute path
        abs_path = os.path.abspath(path)
        
        # Create directory if it doesn't exist
        os.makedirs(abs_path, exist_ok=True)
        
        # Check if directory is writable
        test_file = os.path.join(abs_path, '.write_test')
        try:
            with open(test_file, 'w') as f:
                f.write('test')
            os.remove(test_file)
        except Exception as e:
            raise PermissionError(f"Directory {abs_path} is not writable: {str(e)}")
        logger.info(f"Directory {abs_path} is writable.")
        return abs_path
    except Exception as e:
        logger.error(f"Error validating path {path}: {str(e)}")
        raise
```

### 2. Service Management Scripts

#### Basic Mode (start_memory_service.sh)

Provides basic service startup with error handling:

```bash
# Run the server with debug logging and basic error handling in background
$PYTHON -m mcp_memory_service.server \
  --debug > logs/memory_service.log 2>&1 &

# Save PID to file
echo $! > logs/server.pid
```

#### Persistent Mode (persistent_memory_service.sh)

Implements watchdog functionality for automatic restart:

```bash
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
```

#### Debug Mode (debug_memory_service.sh)

Foreground operation with interactive debugging:

```bash
# Force unbuffered output for immediate logging
export PYTHONUNBUFFERED=1

# Run the server in foreground with verbose debug output
exec $PYTHON -m mcp_memory_service.server --debug
```

#### Service Termination (stop_memory_service.sh)

Graceful process termination with PID tracking:

```bash
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
```

### 3. Database Validation and Repair

Added database health validation during startup:

```python
async def validate_database_health(self):
    """Validate database health during initialization."""
    from .utils.db_utils import validate_database, repair_database
    
    # Check database health
    is_valid, message = await validate_database(self.storage)
    if not is_valid:
        logger.warning(f"Database validation failed: {message}")
        
        # Attempt repair
        logger.info("Attempting database repair...")
        repair_success, repair_message = await repair_database(self.storage)
        
        if not repair_success:
            raise RuntimeError(f"Database repair failed: {repair_message}")
        else:
            logger.info(f"Database repair successful: {repair_message}")
    else:
        logger.info(f"Database validation successful: {message}")
```

### 4. Virtual Environment Detection

Robust Python interpreter detection with fallbacks:

```bash
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
```

### 5. Module Import Validation

Automatic package installation when module import fails:

```bash
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
```

## C. Compatibility Considerations

### 1. API Compatibility

The enhanced implementation maintains full API compatibility with the reference implementation:

- All tools have identical names and input schemas
- Internal class interfaces remain unchanged
- Data models retain the same structure

### 2. Database Compatibility

The ChromaDB implementation maintains compatibility while adding validation:

- Same collection name (`memory_collection`)
- Same embedding function (`all-MiniLM-L6-v2`)
- Same schema for metadata
- Same distance metric (`cosine`)

### 3. Environment Variables

The following environment variables can be used to customize behavior:

| Variable | Purpose | Default |
|----------|---------|--------|
| `MCP_MEMORY_BASE_DIR` | Custom base directory for storage | Platform-specific default paths |
| `PYTHONPATH` | Include src directory in module search | Set in startup scripts |
| `PYTHONUNBUFFERED` | Force unbuffered output for logging | Set to 1 in persistent mode |

## D. Testing Results

| Test Case | Result | Notes |
|-----------|--------|-------|
| Installation | ✅ Success | Successfully installs in development mode |
| Standalone Start | ✅ Success | Service starts independently |
| Memory Storage | ✅ Success | Stores and retrieves memories |
| Path Resolution | ✅ Success | Correctly finds storage locations |
| Error Handling | ✅ Success | Properly handles and reports errors |
| Process Management | ✅ Success | Successfully monitors and restarts |
| Clean Shutdown | ✅ Success | Properly terminates and releases resources |

## E. Future Considerations

1. **Multi-User Access**: The current implementation doesn't fully address multi-user access to the same database.
2. **Network Storage**: Additional considerations may be needed for using network storage locations.
3. **Very Large Databases**: Performance optimizations may be needed for very large memory collections.
4. **Authentication**: Consider adding authentication for secure communication between client and server.

These edge cases are documented for future enhancement.