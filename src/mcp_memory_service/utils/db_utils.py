"""
MCP Memory Service
Copyright (c) 2024 Heinrich Krupp
Licensed under the MIT License. See LICENSE file in the project root for full license text.
"""

import logging
import os
import shutil
import json
from typing import Tuple, Dict, Any, Optional
import time
from datetime import datetime

from ..storage.chroma import ChromaMemoryStorage

logger = logging.getLogger(__name__)

async def validate_database(storage: ChromaMemoryStorage) -> Tuple[bool, str]:
    """Validate the database health.
    
    Args:
        storage: The ChromaMemoryStorage instance
        
    Returns:
        Tuple of (is_valid, message)
    """
    try:
        # Basic validation - check if we can get collection info
        collection = storage.collection
        
        # Try to get count of items
        count = collection.count()
        
        # If we got here, basic functions are working
        return True, f"Database validated successfully. Contains {count} memories."
    except Exception as e:
        logger.error(f"Database validation error: {str(e)}")
        return False, f"Database validation failed: {str(e)}"

async def repair_database(storage: ChromaMemoryStorage) -> Tuple[bool, str]:
    """Attempt to repair database issues.
    
    Args:
        storage: The ChromaMemoryStorage instance
        
    Returns:
        Tuple of (success, message)
    """
    try:
        from ..config import BACKUPS_PATH, CHROMA_PATH
        
        # Create backup before repair
        backup_path = os.path.join(BACKUPS_PATH, f"chroma_backup_{int(time.time())}")
        os.makedirs(backup_path, exist_ok=True)
        
        # Copy database files to backup
        for item in os.listdir(CHROMA_PATH):
            item_path = os.path.join(CHROMA_PATH, item)
            if os.path.isfile(item_path):
                shutil.copy2(item_path, backup_path)
            elif os.path.isdir(item_path):
                shutil.copytree(item_path, os.path.join(backup_path, item))
        
        # Re-initialize collection
        storage.collection = storage.client.get_or_create_collection(
            name="memory_collection",
            metadata={"hnsw:space": "cosine"},
            embedding_function=storage.embedding_function
        )
        
        # Validate after repair
        is_valid, message = await validate_database(storage)
        if is_valid:
            return True, f"Database repaired successfully. Backup created at {backup_path}"
        else:
            return False, f"Repair attempt completed but validation still fails: {message}"
    except Exception as e:
        logger.error(f"Database repair error: {str(e)}")
        return False, f"Database repair failed: {str(e)}"

def get_database_stats(storage: ChromaMemoryStorage) -> Dict[str, Any]:
    """Get detailed statistics about the database.
    
    Args:
        storage: The ChromaMemoryStorage instance
        
    Returns:
        Dictionary of statistics
    """
    try:
        collection = storage.collection
        
        # Get basic count
        count = collection.count()
        
        # Get all entries to analyze
        results = collection.get(
            include=["metadatas", "documents"]
        )
        
        # Initialize stats
        stats = {
            "total_memories": count,
            "total_content_length": 0,
            "avg_content_length": 0,
            "memory_types": {},
            "tags": {},
            "oldest_memory": None,
            "newest_memory": None,
            "collection_name": "memory_collection",
            "embedding_model": "all-MiniLM-L6-v2"
        }
        
        # Process metadata
        if results["ids"]:
            oldest_timestamp = float('inf')
            newest_timestamp = 0
            
            for i, metadata in enumerate(results["metadatas"]):
                # Content stats
                content_length = len(results["documents"][i])
                stats["total_content_length"] += content_length
                
                # Memory type stats
                memory_type = metadata.get("memory_type", "")
                stats["memory_types"][memory_type] = stats["memory_types"].get(memory_type, 0) + 1
                
                # Tag stats
                try:
                    tags_str = metadata.get("tags", "[]")
                    tags = json.loads(tags_str) if isinstance(tags_str, str) else []
                    for tag in tags:
                        stats["tags"][tag] = stats["tags"].get(tag, 0) + 1
                except (json.JSONDecodeError, TypeError):
                    pass
                
                # Timestamp stats
                timestamp_str = metadata.get("timestamp")
                if timestamp_str:
                    try:
                        timestamp = float(timestamp_str)
                        if timestamp < oldest_timestamp:
                            oldest_timestamp = timestamp
                            stats["oldest_memory"] = datetime.fromtimestamp(timestamp).isoformat()
                        if timestamp > newest_timestamp:
                            newest_timestamp = timestamp
                            stats["newest_memory"] = datetime.fromtimestamp(timestamp).isoformat()
                    except ValueError:
                        pass
            
            # Calculate average
            if count > 0:
                stats["avg_content_length"] = stats["total_content_length"] / count
            
            # Sort and limit tag counts for readability
            sorted_tags = sorted(stats["tags"].items(), key=lambda x: x[1], reverse=True)
            stats["top_tags"] = dict(sorted_tags[:10]) if len(sorted_tags) > 10 else dict(sorted_tags)
        
        return stats
    except Exception as e:
        logger.error(f"Error getting database stats: {str(e)}")
        return {"error": str(e)}
