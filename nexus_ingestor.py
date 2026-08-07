#!/usr/bin/env python3
"""
✝️ To God Be The Glory — Jesus Is King
NEXUS Ingestor v1.0 — Neural Exchange for Unified Synthesis & Understanding
Built by: Richard Dickson Maina | RICHIE Server

Ambient intelligence ingestor that silently processes all incoming knowledge:
- Watches Syncthing directories for new files (phone/windows/web)
- Processes PDFs, documents, images, URLs
- Extracts text and semantic embeddings via Ollama
- Builds knowledge graph in MariaDB
- Connects new info to your actual projects
"""

import os
import sys
import json
import time
import hashlib
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from enum import Enum
import threading
import queue

# Dependencies
import pymysql
from pymysql.cursors import DictCursor
import requests
import PyPDF2
from docx import Document
from PIL import Image
import pytesseract

# ============================================================================
# CONFIGURATION
# ============================================================================

class Config:
    """NEXUS Configuration"""
    
    # Database
    MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
    MYSQL_USER = os.getenv('MYSQL_USER', 'nexus')
    MYSQL_PASS = os.getenv('MYSQL_PASS', 'nexus_knowledge_2026')
    MYSQL_DB = 'nexus_knowledge'
    
    # Ollama embeddings
    OLLAMA_HOST = os.getenv('OLLAMA_HOST', 'http://localhost:11434')
    OLLAMA_EMBED_MODEL = 'nomic-embed-text'
    OLLAMA_CODE_MODEL = 'qwen2.5-coder:7b'
    OLLAMA_TIMEOUT = 60
    
    # Syncthing watch directories
    SYNCTHING_WATCH_DIRS = [
        '/home/riziki/Sync',  # Phone auto-sync
        '/home/riziki/workspace',  # Windows auto-sync
        '/home/riziki/Desktop',  # Quick drops
    ]
    
    # Processing
    MAX_FILE_SIZE_MB = 100
    BATCH_SIZE = 5
    EMBEDDING_DIMENSION = 768
    
    # Logging
    LOG_DIR = '/home/riziki/workspace/projects/nexus/logs'
    LOG_FILE = os.path.join(LOG_DIR, 'nexus_ingestor.log')
    LOG_LEVEL = logging.INFO
    
    @classmethod
    def ensure_paths(cls):
        """Create necessary directories"""
        Path(cls.LOG_DIR).mkdir(parents=True, exist_ok=True)


# ============================================================================
# LOGGING SETUP
# ============================================================================

def setup_logging():
    """Configure logging for NEXUS Ingestor"""
    Config.ensure_paths()
    
    logger = logging.getLogger('NEXUS_INGESTOR')
    logger.setLevel(Config.LOG_LEVEL)
    
    # File handler
    fh = logging.FileHandler(Config.LOG_FILE)
    fh.setLevel(Config.LOG_LEVEL)
    
    # Console handler
    ch = logging.StreamHandler()
    ch.setLevel(Config.LOG_LEVEL)
    
    # Formatter
    formatter = logging.Formatter(
        '%(asctime)s [%(levelname)s] %(name)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    fh.setFormatter(formatter)
    ch.setFormatter(formatter)
    
    logger.addHandler(fh)
    logger.addHandler(ch)
    
    return logger

logger = setup_logging()


# ============================================================================
# ENUM DEFINITIONS
# ============================================================================

class SourceType(Enum):
    """Source document types"""
    PDF = "PDF"
    DOCUMENT = "DOCUMENT"
    IMAGE = "IMAGE"
    URL = "URL"
    CODE_REPO = "CODE_REPO"
    WHATSAPP = "WHATSAPP"
    TELEGRAM = "TELEGRAM"
    SYNCTHING = "SYNCTHING"
    CRAWLED = "CRAWLED"


class ConceptCategory(Enum):
    """Concept classification"""
    CODE = "CODE"
    SYSTEM = "SYSTEM"
    BUSINESS = "BUSINESS"
    INNOVATION = "INNOVATION"
    PERSONAL = "PERSONAL"
    RESEARCH = "RESEARCH"
    TOOL = "TOOL"
    PATTERN = "PATTERN"
    PROBLEM = "PROBLEM"
    SOLUTION = "SOLUTION"


# ============================================================================
# DATABASE CONNECTION
# ============================================================================

class DatabaseConnection:
    """Manages MariaDB connection for NEXUS"""
    
    def __init__(self):
        self.connection = None
        self.connect()
    
    def connect(self):
        """Establish connection to MariaDB"""
        try:
            self.connection = pymysql.connect(
                host=Config.MYSQL_HOST,
                user=Config.MYSQL_USER,
                password=Config.MYSQL_PASS,
                database=Config.MYSQL_DB,
                charset='utf8mb4',
                cursorclass=DictCursor,
                autocommit=True
            )
            logger.info(f"✅ Connected to MariaDB @ {Config.MYSQL_HOST}:{Config.MYSQL_DB}")
        except Exception as e:
            logger.error(f"❌ Database connection failed: {e}")
            raise
    
    def query(self, sql: str, params: Tuple = None) -> List[Dict]:
        """Execute SELECT query"""
        try:
            with self.connection.cursor() as cursor:
                cursor.execute(sql, params or ())
                return cursor.fetchall()
        except Exception as e:
            logger.error(f"Query error: {e}\nSQL: {sql}")
            return []
    
    def execute(self, sql: str, params: Tuple = None) -> int:
        """Execute INSERT/UPDATE/DELETE query"""
        try:
            with self.connection.cursor() as cursor:
                cursor.execute(sql, params or ())
                self.connection.commit()
                return cursor.rowcount
        except Exception as e:
            logger.error(f"Execution error: {e}\nSQL: {sql}")
            self.connection.rollback()
            return 0
    
    def call_procedure(self, proc_name: str, args: Tuple = None):
        """Call stored procedure"""
        try:
            with self.connection.cursor() as cursor:
                cursor.callproc(proc_name, args or ())
                result = cursor.fetchall()
                self.connection.commit()
                return result
        except Exception as e:
            logger.error(f"Procedure call error: {e}")
            return None
    
    def close(self):
        """Close connection"""
        if self.connection:
            self.connection.close()
            logger.info("Database connection closed")


# ============================================================================
# FILE EXTRACTION
# ============================================================================

class FileExtractor:
    """Extract text from various document types"""
    
    @staticmethod
    def extract_pdf(file_path: str) -> str:
        """Extract text from PDF"""
        try:
            text = ""
            with open(file_path, 'rb') as f:
                reader = PyPDF2.PdfReader(f)
                for page in reader.pages:
                    text += page.extract_text() + "\n"
            logger.info(f"✅ Extracted {len(text)} chars from PDF: {file_path}")
            return text.strip()
        except Exception as e:
            logger.error(f"PDF extraction failed: {e}")
            return ""
    
    @staticmethod
    def extract_docx(file_path: str) -> str:
        """Extract text from DOCX"""
        try:
            doc = Document(file_path)
            text = "\n".join([para.text for para in doc.paragraphs])
            logger.info(f"✅ Extracted {len(text)} chars from DOCX: {file_path}")
            return text.strip()
        except Exception as e:
            logger.error(f"DOCX extraction failed: {e}")
            return ""
    
    @staticmethod
    def extract_txt(file_path: str) -> str:
        """Extract text from plain text file"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                text = f.read()
            logger.info(f"✅ Extracted {len(text)} chars from TXT: {file_path}")
            return text.strip()
        except Exception as e:
            logger.error(f"TXT extraction failed: {e}")
            return ""
    
    @staticmethod
    def extract_image(file_path: str) -> str:
        """Extract text from image using OCR"""
        try:
            img = Image.open(file_path)
            text = pytesseract.image_to_string(img)
            logger.info(f"✅ OCR extracted {len(text)} chars from image: {file_path}")
            return text.strip()
        except Exception as e:
            logger.warning(f"Image OCR failed (pytesseract may not be installed): {e}")
            return ""
    
    @staticmethod
    def extract_by_type(file_path: str) -> Tuple[str, SourceType]:
        """Auto-detect file type and extract"""
        path = Path(file_path)
        suffix = path.suffix.lower()
        
        extractors = {
            '.pdf': (FileExtractor.extract_pdf, SourceType.PDF),
            '.docx': (FileExtractor.extract_docx, SourceType.DOCUMENT),
            '.doc': (FileExtractor.extract_docx, SourceType.DOCUMENT),
            '.txt': (FileExtractor.extract_txt, SourceType.DOCUMENT),
            '.md': (FileExtractor.extract_txt, SourceType.DOCUMENT),
            '.png': (FileExtractor.extract_image, SourceType.IMAGE),
            '.jpg': (FileExtractor.extract_image, SourceType.IMAGE),
            '.jpeg': (FileExtractor.extract_image, SourceType.IMAGE),
        }
        
        if suffix in extractors:
            extractor, source_type = extractors[suffix]
            text = extractor(file_path)
            return text, source_type
        
        logger.warning(f"Unsupported file type: {suffix}")
        return "", SourceType.SYNCTHING


# ============================================================================
# EMBEDDING ENGINE
# ============================================================================

class EmbeddingEngine:
    """Generate semantic embeddings via Ollama"""
    
    @staticmethod
    def get_embedding(text: str) -> Optional[List[float]]:
        """Generate embedding for text using Ollama"""
        if not text or len(text.strip()) < 10:
            logger.warning("Text too short for embedding")
            return None
        
        try:
            # Truncate to reasonable length
            text = text[:1000]
            
            response = requests.post(
                f"{Config.OLLAMA_HOST}/api/embeddings",
                json={
                    "model": Config.OLLAMA_EMBED_MODEL,
                    "prompt": text
                },
                timeout=Config.OLLAMA_TIMEOUT
            )
            
            if response.status_code == 200:
                embedding = response.json().get('embedding')
                if embedding:
                    logger.debug(f"✅ Generated {len(embedding)}-dim embedding")
                    return embedding
            else:
                logger.error(f"Ollama embedding failed: {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"Embedding generation failed: {e}")
            return None
    
    @staticmethod
    def batch_embeddings(texts: List[str]) -> List[Optional[List[float]]]:
        """Generate embeddings for multiple texts"""
        embeddings = []
        for text in texts:
            embeddings.append(EmbeddingEngine.get_embedding(text))
        return embeddings


# ============================================================================
# CONCEPT EXTRACTION (Simple Rule-based)
# ============================================================================

class ConceptExtractor:
    """Extract potential concepts from text"""
    
    # Code-related keywords
    CODE_KEYWORDS = [
        'python', 'javascript', 'node', 'react', 'flask', 'database', 'api',
        'function', 'class', 'module', 'package', 'docker', 'kubernetes',
        'sql', 'query', 'index', 'cache', 'async', 'threading', 'process'
    ]
    
    # Business keywords
    BUSINESS_KEYWORDS = [
        'revenue', 'cost', 'budget', 'profit', 'customer', 'market', 'strategy',
        'growth', 'roi', 'analytics', 'metric', 'kpi', 'sales', 'operation'
    ]
    
    @staticmethod
    def extract_concepts(text: str) -> List[Dict]:
        """Extract concepts from text (rule-based for now)"""
        concepts = []
        
        # Simple approach: extract sentences as potential concepts
        sentences = text.split('.')
        for i, sentence in enumerate(sentences[:10]):  # Limit to first 10
            sentence = sentence.strip()
            if len(sentence) > 10 and len(sentence) < 200:
                
                # Categorize
                category = ConceptCategory.RESEARCH.value
                for keyword in ConceptExtractor.CODE_KEYWORDS:
                    if keyword.lower() in sentence.lower():
                        category = ConceptCategory.CODE.value
                        break
                for keyword in ConceptExtractor.BUSINESS_KEYWORDS:
                    if keyword.lower() in sentence.lower():
                        category = ConceptCategory.BUSINESS.value
                        break
                
                # Create concept ID from hash
                concept_id = f"concept_{hashlib.md5(sentence.encode()).hexdigest()[:12]}"
                
                concepts.append({
                    'concept_id': concept_id,
                    'name': sentence[:80],  # First 80 chars
                    'description': sentence,
                    'category': category
                })
        
        return concepts


# ============================================================================
# NEXUS INGESTOR CORE
# ============================================================================

class NEXUSIngestor:
    """Main NEXUS ingestor orchestrator"""
    
    def __init__(self):
        self.db = DatabaseConnection()
        self.ingest_queue = queue.Queue()
        self.processed_hashes = set()
        self.load_processed_hashes()
    
    def load_processed_hashes(self):
        """Load previously processed file hashes"""
        results = self.db.query("SELECT content_hash FROM sources WHERE content_hash IS NOT NULL")
        self.processed_hashes = {row['content_hash'] for row in results}
        logger.info(f"✅ Loaded {len(self.processed_hashes)} processed file hashes")
    
    def calculate_file_hash(self, file_path: str) -> str:
        """Calculate SHA256 hash of file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    
    def ingest_file(self, file_path: str, device_origin: str = 'KALI') -> bool:
        """Process a single file through NEXUS"""
        try:
            path = Path(file_path)
            
            # Validate file
            if not path.exists():
                logger.warning(f"File not found: {file_path}")
                return False
            
            if path.stat().st_size > Config.MAX_FILE_SIZE_MB * 1024 * 1024:
                logger.warning(f"File too large: {file_path}")
                return False
            
            # Calculate hash
            file_hash = self.calculate_file_hash(file_path)
            if file_hash in self.processed_hashes:
                logger.debug(f"File already processed (hash match): {file_path}")
                return False
            
            logger.info(f"🔄 Ingesting: {file_path}")
            
            # Extract text
            text, source_type = FileExtractor.extract_by_type(file_path)
            if not text:
                logger.warning(f"No text extracted from: {file_path}")
                return False
            
            # Store source in database
            source_id = f"src_{int(time.time() * 1000)}"
            insert_source_sql = """
                INSERT INTO sources (
                    source_id, source_type, title, file_path,
                    raw_content, extracted_text, word_count,
                    device_origin, processing_status, content_hash
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            word_count = len(text.split())
            self.db.execute(insert_source_sql, (
                source_id,
                source_type.value,
                path.name,
                file_path,
                text[:10000],  # Store first 10k chars
                text,
                word_count,
                device_origin,
                'PROCESSING',
                file_hash
            ))
            
            logger.info(f"✅ Stored source: {source_id} ({word_count} words)")
            
            # Extract concepts
            concepts = ConceptExtractor.extract_concepts(text)
            logger.info(f"📊 Extracted {len(concepts)} concepts")
            
            # Process concepts
            for concept in concepts:
                self._process_concept(concept, source_id)
            
            # Update source status
            self.db.execute(
                "UPDATE sources SET processing_status = %s WHERE source_id = %s",
                ('INDEXED', source_id)
            )
            
            self.processed_hashes.add(file_hash)
            logger.info(f"✨ Complete: {file_path}")
            return True
            
        except Exception as e:
            logger.error(f"Ingest failed for {file_path}: {e}")
            return False
    
    def _process_concept(self, concept: Dict, source_id: str):
        """Process a single concept"""
        try:
            # Get source DB ID
            source_results = self.db.query(
                "SELECT id FROM sources WHERE source_id = %s",
                (source_id,)
            )
            if not source_results:
                return
            
            source_db_id = source_results[0]['id']
            
            # Check if concept exists
            concept_results = self.db.query(
                "SELECT id FROM concepts WHERE concept_id = %s",
                (concept['concept_id'],)
            )
            
            if concept_results:
                concept_db_id = concept_results[0]['id']
            else:
                # Get embedding
                embedding = EmbeddingEngine.get_embedding(concept['description'])
                
                # Insert concept
                self.db.execute(
                    """
                    INSERT INTO concepts (
                        concept_id, name, description, category,
                        embedding_dimension, relevance_score
                    ) VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (
                        concept['concept_id'],
                        concept['name'],
                        concept['description'],
                        concept['category'],
                        len(embedding) if embedding else 768,
                        0.5
                    )
                )
                
                # Get the ID
                concept_results = self.db.query(
                    "SELECT id FROM concepts WHERE concept_id = %s",
                    (concept['concept_id'],)
                )
                concept_db_id = concept_results[0]['id']
            
            # Link source to concept
            self.db.execute(
                """
                INSERT INTO source_concepts (source_id, concept_id, relevance_score)
                VALUES (%s, %s, %s)
                ON DUPLICATE KEY UPDATE relevance_score = relevance_score + 0.1
                """,
                (source_db_id, concept_db_id, 0.5)
            )
            
        except Exception as e:
            logger.error(f"Concept processing failed: {e}")
    
    def watch_syncthing_directories(self):
        """Watch Syncthing directories for new files"""
        logger.info("🔍 Watching Syncthing directories...")
        
        watched_files = {}
        
        while True:
            try:
                for watch_dir in Config.SYNCTHING_WATCH_DIRS:
                    if not Path(watch_dir).exists():
                        continue
                    
                    # Find all supported file types
                    extensions = ['*.pdf', '*.docx', '*.doc', '*.txt', '*.md', '*.png', '*.jpg', '*.jpeg']
                    
                    for ext in extensions:
                        for file_path in Path(watch_dir).rglob(ext):
                            file_str = str(file_path)
                            
                            # Track modification time
                            try:
                                mtime = file_path.stat().st_mtime
                                
                                if file_str not in watched_files:
                                    watched_files[file_str] = mtime
                                    # New file or changed file
                                    if mtime > watched_files[file_str]:
                                        logger.info(f"📱 Detected change: {file_str}")
                                        self.ingest_file(file_str)
                                        watched_files[file_str] = mtime
                            except Exception as e:
                                logger.debug(f"File stat error: {e}")
                
                time.sleep(5)  # Check every 5 seconds
                
            except KeyboardInterrupt:
                logger.info("Syncthing watcher stopped")
                break
            except Exception as e:
                logger.error(f"Watch loop error: {e}")
                time.sleep(10)
    
    def process_queue(self):
        """Process ingest queue from database"""
        logger.info("🎯 Starting queue processor...")
        
        while True:
            try:
                # Get pending items
                pending = self.db.query(
                    """
                    SELECT * FROM ingest_queue
                    WHERE status = 'PENDING'
                    ORDER BY priority DESC, created_at ASC
                    LIMIT %s
                    """,
                    (Config.BATCH_SIZE,)
                )
                
                for item in pending:
                    try:
                        file_path = item['file_path'] or item['url']
                        self.db.execute(
                            "UPDATE ingest_queue SET status = %s WHERE id = %s",
                            ('PROCESSING', item['id'])
                        )
                        
                        success = self.ingest_file(file_path, item['source_device'])
                        
                        status = 'COMPLETED' if success else 'FAILED'
                        self.db.execute(
                            "UPDATE ingest_queue SET status = %s, processed_at = NOW() WHERE id = %s",
                            (status, item['id'])
                        )
                        
                    except Exception as e:
                        logger.error(f"Queue item failed: {e}")
                        self.db.execute(
                            "UPDATE ingest_queue SET status = %s, error_message = %s WHERE id = %s",
                            ('FAILED', str(e), item['id'])
                        )
                
                time.sleep(10)  # Check queue every 10 seconds
                
            except KeyboardInterrupt:
                logger.info("Queue processor stopped")
                break
            except Exception as e:
                logger.error(f"Queue processor error: {e}")
                time.sleep(10)
    
    def start(self):
        """Start NEXUS Ingestor"""
        logger.info("🚀 NEXUS Ingestor starting...")
        
        # Start queue processor in background thread
        queue_thread = threading.Thread(target=self.process_queue, daemon=True)
        queue_thread.start()
        logger.info("✅ Queue processor started")
        
        # Watch Syncthing directories (blocking)
        try:
            self.watch_syncthing_directories()
        except KeyboardInterrupt:
            logger.info("NEXUS Ingestor stopped by user")
        finally:
            self.db.close()


# ============================================================================
# CLI INTERFACE
# ============================================================================

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='NEXUS Ingestor - Neural Exchange for Unified Synthesis & Understanding'
    )
    parser.add_argument('--ingest', type=str, help='Ingest a specific file')
    parser.add_argument('--watch', action='store_true', help='Watch Syncthing directories')
    parser.add_argument('--queue', action='store_true', help='Process ingest queue only')
    parser.add_argument('--full', action='store_true', help='Start full ingestor (watch + queue)')
    parser.add_argument('--test', action='store_true', help='Test database connection')
    
    args = parser.parse_args()
    
    try:
        ingestor = NEXUSIngestor()
        
        if args.test:
            logger.info("✅ Database connection successful")
            results = ingestor.db.query("SELECT COUNT(*) as count FROM concepts")
            logger.info(f"Concepts in database: {results[0]['count']}")
            
        elif args.ingest:
            logger.info(f"Ingesting file: {args.ingest}")
            success = ingestor.ingest_file(args.ingest)
            logger.info(f"Result: {'✅ Success' if success else '❌ Failed'}")
            
        elif args.watch:
            logger.info("Starting Syncthing watcher...")
            ingestor.watch_syncthing_directories()
            
        elif args.queue:
            logger.info("Starting queue processor...")
            ingestor.process_queue()
            
        elif args.full:
            logger.info("Starting full NEXUS Ingestor...")
            ingestor.start()
            
        else:
            parser.print_help()
            ingestor.start()  # Default: run full ingestor
            
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
