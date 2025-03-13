# MCP Memory Service - Enhanced

This repository contains enhanced versions of the original [doobidoo/mcp-memory-service](https://github.com/doobidoo/mcp-memory-service) with a focus on robust standalone operation.

## Overview

The MCP Memory Service provides AI assistants with a persistent semantic memory system using the Model Context Protocol (MCP). This enhanced version adds robust operation scripts, improved error handling, and automatic monitoring to the original implementation.

## Relationship to Original Implementation

This repository builds upon the reference implementation by [doobidoo](https://github.com/doobidoo/mcp-memory-service), adding operational enhancements while maintaining full compatibility with the original codebase.

## Enhanced Features

### 1. Robust Startup Scripts

- **start_memory_service.sh**: Basic service startup with better path resolution
- **persistent_memory_service.sh**: Background service with automatic restart capability
- **debug_memory_service.sh**: Interactive debugging mode
- **stop_memory_service.sh**: Clean process termination

### 2. Improved Path Resolution

- Multiple fallback options for base directory location
- Platform-specific default paths
- Environment variable configuration
- Write permission verification

### 3. Enhanced Error Handling

- Detailed validation and error reporting
- Graceful failure handling
- Better logging with timestamps and context

### 4. Watchdog Monitoring

- Automatic service monitoring
- Crash detection and recovery
- Process supervision

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/asirulnik/mcp-memory-service-enhanced.git
   cd mcp-memory-service-enhanced
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install the package in development mode:
   ```bash
   pip install -e .
   ```

## Usage

Start the service using one of the provided scripts:

### Basic Mode

```bash
./start_memory_service.sh
```

This starts the service with basic logging and error handling.

### Persistent Mode

```bash
./persistent_memory_service.sh
```

Starts the service with watchdog monitoring for automatic restart on failure.

### Debug Mode

```bash
./debug_memory_service.sh
```

Runs the service in the foreground with verbose logging.

### Stopping the Service

```bash
./stop_memory_service.sh
```

Gracefully terminates the running service.

## Key Enhancements

### Path Resolution

The enhanced implementation adds robust path resolution with fallback options:

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

### Watchdog Implementation

Automatic service monitoring and recovery:

```bash
# Watchdog implementation
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

## Configuration

### Environment Variables

- `MCP_MEMORY_BASE_DIR`: Set custom base directory for storage
- `PYTHONUNBUFFERED=1`: Force unbuffered Python output for better logging

### Default Storage Locations

- **macOS**: `~/Library/Application Support/mcp-memory/`
- **Windows**: `%LOCALAPPDATA%\mcp-memory\`
- **Linux**: `~/.local/share/mcp-memory/`

## Tools

The service implements all tools from the original reference implementation:

- `store_memory`: Store new information with tags
- `retrieve_memory`: Find relevant memories based on query
- `search_by_tag`: Search memories by tags
- `delete_memory`: Delete a specific memory by hash
- `delete_by_tag`: Delete all memories with a specific tag
- `cleanup_duplicates`: Find and remove duplicate entries
- `check_database_health`: Verify database integrity

## License

This project maintains the same license as the original reference implementation.

## Acknowledgments

- Original implementation by [doobidoo](https://github.com/doobidoo/mcp-memory-service)
- Enhanced by Andrew Sirulnik