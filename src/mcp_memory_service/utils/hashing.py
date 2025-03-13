"""
MCP Memory Service
Copyright (c) 2024 Heinrich Krupp
Licensed under the MIT License. See LICENSE file in the project root for full license text.
"""

import hashlib
import json
from typing import Dict, Any, Union

def generate_content_hash(content: str, metadata: Union[Dict[str, Any], None] = None) -> str:
    """Generate a hash for content and optional metadata.
    
    Args:
        content: The primary content to hash
        metadata: Optional metadata to include in the hash
        
    Returns:
        A unique hash string
    """
    # Start with content
    hash_input = content
    
    # Add metadata if provided
    if metadata:
        # Extract only serializable metadata and sort keys for consistency
        serializable_metadata = {}
        for k, v in metadata.items():
            # Skip any complex objects that can't be easily serialized
            if isinstance(v, (str, int, float, bool, list, dict)):
                serializable_metadata[k] = v
        
        # Add serialized metadata to hash input if there's any serializable data
        if serializable_metadata:
            hash_input += json.dumps(serializable_metadata, sort_keys=True)
    
    # Generate and return SHA-256 hash
    return hashlib.sha256(hash_input.encode('utf-8')).hexdigest()
