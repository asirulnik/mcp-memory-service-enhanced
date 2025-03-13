# MCP Memory Service - Enhanced

This repository contains enhanced versions of the original [doobidoo/mcp-memory-service](https://github.com/doobidoo/mcp-memory-service) with a focus on robust standalone operation.

## Overview

The MCP Memory Service provides AI assistants with a persistent semantic memory system using the Model Context Protocol (MCP). This enhanced version adds path resolution improvements, better error handling, and simplified operation scripts to the original implementation.

## Relationship to Original Implementation

This repository builds upon the reference implementation by [doobidoo](https://github.com/doobidoo/mcp-memory-service), adding operational enhancements while maintaining full compatibility with the original codebase.

## Enhanced Features

### 1. Simple Standalone Operation

- **start_basic.sh**: Minimal service startup with proper path resolution
- **stop_basic.sh**: Clean process termination with PID tracking
- **Database Path Resolution**: Automatically finds and creates storage locations

### 2. Improved Path Resolution

- Multiple fallback options for base directory location
- Platform-specific default paths
- Environment variable configuration
- Write permission verification

### 3. Enhanced Error Handling

- Detailed validation and error reporting
- Graceful failure handling
- Better logging with timestamps and context

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

### Basic Operation

Starting the service:
```bash
./start_basic.sh
```

This script:
- Sets the PYTHONPATH to include the src directory
- Runs the server module in the background
- Saves the PID for later termination
- Creates logs in the logs/ directory

Stopping the service:
```bash
./stop_basic.sh
```

This script:
- Checks if the process is running
- Terminates it gracefully
- Removes the PID file after successful termination

### Process Management

#### Checking Service Status

```bash
# Check if service is running using the saved PID
ps -p $(cat logs/server.pid) > /dev/null && echo "Running" || echo "Not running"

# View the service logs
tail -f logs/memory_service.log
```

#### Handling Orphan Processes

If you encounter log file overwrites or other process-related issues:

1. Check for multiple process instances:
   ```bash
   ps aux | grep -E "mcp_memory_service|watchdog.sh" | grep -v grep
   ```

2. Kill any orphaned processes:
   ```bash
   kill -9 $(ps aux | grep -E "mcp_memory_service|watchdog.sh" | grep -v grep | awk '{print $2}')
   ```

3. Remove any stale PID files:
   ```bash
   rm -f logs/server.pid
   ```

4. Restart with the simple script:
   ```bash
   ./start_basic.sh
   ```

For detailed process management guidelines, see [Process Management Documentation](docs/process_management.md).

## Key Enhancements

### Database Path Resolution

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

## Configuration

### Environment Variables

- `MCP_MEMORY_BASE_DIR`: Set custom base directory for storage
- `PYTHONPATH`: Must include the src directory

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