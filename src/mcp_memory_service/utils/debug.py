"""
MCP Memory Service
Copyright (c) 2024 Heinrich Krupp
Licensed under the MIT License. See LICENSE file in the project root for full license text.
"""

import logging
import time
from typing import Dict, Any, List, Optional
import json

from ..storage.chroma import ChromaMemoryStorage
from ..models.memory import Memory, MemoryQueryResult

logger = logging.getLogger(__name__)

def get_raw_embedding(storage: ChromaMemoryStorage, content: str) -> Dict[str, Any]:
    """Get raw embedding information for debugging.
    
    Args:
        storage: The storage implementation
        content: Text to embed
        
    Returns:
        Dictionary with embedding information
    """
    try:
        # Time embedding generation
        start_time = time.time()
        embedding = storage.model.encode(content)
        end_time = time.time()
        
        return {
            "embedding_time": round(end_time - start_time, 4),
            "embedding_dimensions": len(embedding),
            "embedding_model": "all-MiniLM-L6-v2",
            "embedding_sample": embedding[:5].tolist(),  # Just show first 5 values
            "content_preview": content[:100] + "..." if len(content) > 100 else content
        }
    except Exception as e:
        logger.error(f"Error generating embedding: {str(e)}")
        return {"error": str(e)}

def check_embedding_model(storage: ChromaMemoryStorage) -> Dict[str, Any]:
    """Check if embedding model is loaded and working.
    
    Args:
        storage: The storage implementation
        
    Returns:
        Dictionary with model information
    """
    try:
        # Try to embed a simple test string
        test_string = "This is a test string for embedding."
        
        # Time embedding generation
        start_time = time.time()
        embedding = storage.model.encode(test_string)
        end_time = time.time()
        
        return {
            "status": "ok",
            "model": "all-MiniLM-L6-v2",
            "embedding_dimensions": len(embedding),
            "embedding_time": round(end_time - start_time, 4),
            "device": str(storage.model.device)
        }
    except Exception as e:
        logger.error(f"Error checking embedding model: {str(e)}")
        return {
            "status": "error",
            "error": str(e)
        }

async def debug_retrieve_memory(storage: ChromaMemoryStorage, query: str, n_results: int = 5,
                              similarity_threshold: float = 0.0) -> List[MemoryQueryResult]:
    """Retrieve memories with additional debug information.
    
    Args:
        storage: The storage implementation
        query: The search query
        n_results: Maximum number of results to return
        similarity_threshold: Minimum similarity score threshold
        
    Returns:
        List of memory query results with debug info
    """
    try:
        # Query using the embedding function with include_distances=True
        results = storage.collection.query(
            query_texts=[query],
            n_results=n_results,
            include=["documents", "metadatas", "distances"]
        )
        
        if not results["ids"] or not results["ids"][0]:
            return []
        
        memory_results = []
        for i in range(len(results["ids"][0])):
            metadata = results["metadatas"][0][i]
            
            # Create memory object
            memory = Memory(
                content=results["documents"][0][i],
                content_hash=metadata.get("content_hash", ""),
                tags=metadata.get("tags", []),
                memory_type=metadata.get("memory_type", ""),
            )
            
            # Calculate cosine similarity from distance
            distance = results["distances"][0][i]
            similarity = 1 - distance
            
            # Skip if below threshold
            if similarity < similarity_threshold:
                continue
            
            # Create debug info
            debug_info = {
                "raw_distance": distance,
                "raw_similarity": similarity,
                "memory_id": results["ids"][0][i],
                "embedding_model": "all-MiniLM-L6-v2"
            }
            
            memory_results.append(MemoryQueryResult(memory, similarity, debug_info=debug_info))
        
        return memory_results
    except Exception as e:
        logger.error(f"Error in debug retrieve: {str(e)}")
        return []

async def exact_match_retrieve(storage: ChromaMemoryStorage, content: str) -> List[Memory]:
    """Retrieve memories using exact content match.
    
    Args:
        storage: The storage implementation
        content: Exact content to match
        
    Returns:
        List of matching memories
    """
    try:
        # Get all documents
        results = storage.collection.get(
            include=["documents", "metadatas"]
        )
        
        if not results["ids"]:
            return []
        
        # Find exact matches
        matches = []
        for i, doc in enumerate(results["documents"]):
            if doc == content:
                metadata = results["metadatas"][i]
                
                # Parse tags if stored as JSON string
                tags = []
                if "tags" in metadata:
                    tag_data = metadata["tags"]
                    if isinstance(tag_data, str):
                        try:
                            tags = json.loads(tag_data)
                        except json.JSONDecodeError:
                            tags = []
                    elif isinstance(tag_data, list):
                        tags = tag_data
                
                memory = Memory(
                    content=doc,
                    content_hash=metadata.get("content_hash", ""),
                    tags=tags,
                    memory_type=metadata.get("memory_type", ""),
                )
                matches.append(memory)
        
        return matches
    except Exception as e:
        logger.error(f"Error in exact match retrieve: {str(e)}")
        return []
