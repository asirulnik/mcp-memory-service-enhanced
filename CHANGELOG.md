# Changelog

All notable changes to the MCP Memory Service Enhanced project will be documented in this file.

## [0.2.1] - 2025-03-13

### Added
- Basic startup and shutdown scripts for minimal configuration
- Streamlined process management without watchdog dependency

### Changed
- Simplified startup approach for better reliability
- Improved documentation with latest findings

### Fixed
- Resolved process termination issues
- Fixed recursive startup in watchdog implementation

## [0.2.0] - 2025-03-13

### Added
- Robust startup scripts with different operation modes
- Enhanced path resolution with multiple fallback options
- Expanded logging and error handling
- Database validation and repair utilities

### Changed
- Improved ChromaDB storage implementation with better error handling
- Enhanced config with dynamic base directory discovery
- Updated README with comprehensive documentation

### Fixed
- Path resolution issues across different environments
- Initialization sequence to properly handle permissions
- Improved error handling for database operations

## [0.1.0] - 2024-12-27

### Initial Release
- Fork of original doobidoo/mcp-memory-service
- Basic MCP protocol compliance implementation
- Vector-based memory storage with ChromaDB backend
