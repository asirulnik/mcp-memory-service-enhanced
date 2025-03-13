# Process Management Guidelines

## Overview

This document details best practices for managing the MCP Memory Service as a standalone process, focusing on avoiding orphan processes and resource leaks.

## Issues and Solutions

### Orphan Process Issues

During implementation, we encountered issues with orphan processes and log file overwrites, particularly when using watchdog functionality:

1. **Recursive Process Creation**: Watchdog scripts that restart the service on crash can create multiple instances if not designed carefully.

2. **Overlapping Log Writes**: Multiple service instances writing to the same log file causes corruption or overwrites.

3. **Resource Leaks**: Orphaned processes continue to consume system resources and may interfere with new instances.

### Best Practices

#### 1. Process Identification

Regularly check for running instances with:

```bash
# Find all service processes
ps aux | grep "mcp_memory_service" | grep -v grep

# Find any related watchdog processes
ps aux | grep "watchdog.sh" | grep -v grep
```

#### 2. PID Management

Always track the process ID for proper management:

```bash
# Save PID on startup
echo $! > logs/server.pid

# Check if process exists before operations
if ps -p $(cat logs/server.pid) > /dev/null; then
    # Process exists
    echo "Service is running"
fi

# Remove PID file after termination
rm logs/server.pid
```

#### 3. Clean Termination

Implement graceful shutdown with proper signal handling:

```bash
# First try graceful termination
kill $PID

# Wait for termination
sleep 2

# Force kill if still running
if ps -p $PID > /dev/null; then
    kill -9 $PID
fi
```

#### 4. Orphan Process Cleanup

If orphaned processes are detected:

```bash
# Force kill all orphaned processes
kill -9 $(ps aux | grep -E "mcp_memory_service|watchdog.sh" | grep -v grep | awk '{print $2}')
```

## Recommended Process Management

### Simple Startup Process

Our recommended approach is simple but effective:

1. **Single Instance**: Always use `start_basic.sh` which launches only one properly managed instance.

2. **No Watchdog**: Avoid complex watchdog scripts that can lead to cascading issues.

3. **Clean Shutdown**: Always use `stop_basic.sh` to ensure proper termination and resource cleanup.

### Alternative: System-Level Service Management

For production environments, consider using your system's service manager:

- **Linux**: systemd unit files
- **macOS**: launchd plist files
- **Windows**: Windows Service

These provide better process monitoring, automatic restart, and resource management than custom watchdog scripts.

## Troubleshooting

### Common Issues

1. **Log File Overwriting**: Indicates multiple service instances are running. Stop all instances and restart with `start_basic.sh`.

2. **Service Not Starting**: Check for existing processes or stale PID files that might be preventing startup.

3. **Cannot Stop Service**: Use the force kill command if the normal stop script fails.

### Diagnostic Commands

```bash
# Check if service is running
ps -p $(cat logs/server.pid) > /dev/null && echo "Running" || echo "Not running"

# Check log file for errors
tail -f logs/memory_service.log

# Check for orphaned processes
ps aux | grep -E "mcp_memory_service|watchdog" | grep -v grep
```

By following these guidelines, you can maintain a reliable standalone MCP Memory Service without resource leaks or orphan processes.