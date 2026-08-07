# NEXUS — Neural Exchange for Unified Synthesis & Understanding

> ✝️ **To God Be The Glory — Jesus Is King**
>
> An ambient intelligence layer that wraps around your life. Silent. Persistent. Growing.

## What is NEXUS?

NEXUS is a living intelligence system that silently ingests, processes, and connects all knowledge flowing through your ecosystem — from your phone, laptop, web, and documents — into a unified knowledge graph that understands your actual projects and patterns.

It doesn't interrupt. It doesn't schedule. **It becomes the environment.**

### The Vision

```
PHONE (auto-sync)          WINDOWS (auto-sync)         WEB (auto-crawl)
     ↓                           ↓                           ↓
  Syncthing                   Syncthing                  JARVIS crawler
     ↓___________________________|___________________________|
                                 ↓
                        NEXUS INGESTOR
                   (PDF, docs, images, URLs)
                                 ↓
                    ┌────────────────────────┐
                    │   KNOWLEDGE GRAPH      │
                    │   MariaDB + ChromaDB   │
                    │   - Topics & concepts  │
                    │   - Relationships      │
                    │   - Source + recency   │
                    │   - Your projects map  │
                    └────────────────────────┘
                                 ↓
                    NEXUS ENGINE (Python)
                    - Connects new info to
                      YOUR actual projects
                    - Finds patterns across
                      all knowledge tracks
                    - Generates insights,
                      code snippets, ideas
                                 ↓
              ┌──────────────────┼──────────────────┐
              ↓                  ↓                  ↓
         WHATSAPP            TELEGRAM            STARTUP
         ambient             on-demand           brief on
         whispers            deep dives          boot-up
```

## Architecture

### Layer 1: NEXUS Ingestor
- **Watches**: `/home/riziki/Sync`, `/home/riziki/workspace`, `/home/riziki/Desktop`
- **Processes**: PDFs, DOCX, TXT, Markdown, images (OCR)
- **Indexes**: MariaDB + ChromaDB embeddings
- **Runs**: Continuously on Kali server
- **Speed**: ~100-500ms per document

### Layer 2: Knowledge Graph
- **Database**: `nexus_knowledge` MariaDB
- **Tables**: 
  - `concepts` — Topics, ideas, patterns
  - `relationships` — How concepts connect
  - `sources` — Every document ingested
  - `source_concepts` — Which concepts appear in which sources
  - `projects` — Your actual projects
  - `insights` — Generated intelligence
  - `ingest_queue` — Processing queue

### Layer 3: Semantic Processing
- **Embeddings**: Ollama `nomic-embed-text` (768-dim)
- **Code Understanding**: `qwen2.5-coder:7b`
- **Vector Store**: ChromaDB (`~/workspace/projects/jarvis/chroma_db/`)

### Layer 4: Ambient Delivery
- **WhatsApp**: Calm daily digests via Baileys bot
- **Telegram**: On-demand deep dives
- **Startup Brief**: Insights when you boot your laptop
- **Dashboard**: Web UI (future)

## Installation

### Prerequisites
- Kali Server (RICHIE) with Apache2, MariaDB, Ollama
- Ollama running with `nomic-embed-text` + `qwen2.5-coder:7b`
- Python 3.8+
- Syncthing configured for phone/windows sync

### Quick Start

```bash
# Navigate to NEXUS directory
cd /home/riziki/workspace/projects/nexus

# Make startup script executable
chmod +x start_nexus.sh

# Run startup script (handles venv, dependencies, schema init)
./start_nexus.sh
```

The script will:
1. Create Python virtual environment
2. Install dependencies
3. Initialize MariaDB schema
4. Verify Ollama is running
5. Start NEXUS Ingestor

### Manual Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Initialize database
mysql -u root < nexus_schema.sql

# Test connection
python3 nexus_ingestor.py --test

# Run full ingestor
python3 nexus_ingestor.py --full
```

## Usage

### Start NEXUS
```bash
./start_nexus.sh
# or
python3 nexus_ingestor.py --full
```

### Ingest a Specific File
```bash
python3 nexus_ingestor.py --ingest /path/to/document.pdf
```

### Watch Mode Only (Syncthing directories)
```bash
python3 nexus_ingestor.py --watch
```

### Process Queue Only
```bash
python3 nexus_ingestor.py --queue
```

### Test Database Connection
```bash
python3 nexus_ingestor.py --test
```

## How It Works Day-to-Day

### Scenario 1: You Boot Your Laptop
```
1. NEXUS Ingestor running in background
2. Syncthing has synced overnight
3. NEXUS processes new documents
4. Ollama generates embeddings
5. MariaDB builds relationships
6. NEXUS Engine analyzes your projects
7. WhatsApp bot sends: "3 key insights about poultry-farm + your new PHP patterns"
```

### Scenario 2: You Save a PDF to Phone
```
1. You save: "poultry-farm-financial-operations.pdf"
2. Syncthing pushes to Kali: /home/riziki/Sync
3. NEXUS detects file change
4. Extracts text + concepts
5. Generates embedding via Ollama
6. Links to `poultry_farm` project
7. Discovers: "Financial tracking pattern from this PDF fits your revenue module"
8. Queues insight for delivery
```

### Scenario 3: You Ask JARVIS
```
Q: "How can I optimize poultry farm revenue?"
JARVIS checks knowledge graph:
- Recent PDFs about farm operations
- Extracted business concepts
- Related code patterns from backend
- Financial metrics from your database
A: "Here's a strategy based on [3 sources] + implementation in Python/PHP"
```

## Database Schema Overview

### Key Tables

#### `concepts`
Topics, ideas, patterns extracted from documents
- `concept_id`: Unique identifier
- `name`: Short title
- `description`: Full text
- `category`: CODE, SYSTEM, BUSINESS, INNOVATION, etc.
- `relevance_score`: Calculated importance (0-1)
- `source_track`: Which knowledge track it belongs to
- `embedding_id`: Reference to ChromaDB vector

#### `relationships`
How concepts connect to each other
- `concept_a_id`, `concept_b_id`: Connected concepts
- `relationship_type`: DEPENDS_ON, FEEDS_INTO, SOLVES, etc.
- `strength`: Connection confidence (0-1)
- `reason`: Why they're connected

#### `sources`
Every document ingested
- `file_path`, `url`, `raw_content`
- `processing_status`: PENDING → PROCESSING → INDEXED
- `word_count`, `concept_count`
- `device_origin`: PHONE, WINDOWS, KALI, WEB

#### `projects`
Your actual projects mapped in NEXUS
- `poultry_farm`: Core farm management project
- `baileys_bot`: WhatsApp automation
- `jarvis_core`: Memory/intelligence system
- `kilo_system`: Diagnostic system
- `career_ops`: Career tracking

#### `ingest_queue`
Processing queue for documents
- Add here via API/bot
- NEXUS processes automatically
- Tracks status and errors

## Configuration

Edit `nexus_ingestor.py` Config class:

```python
class Config:
    MYSQL_HOST = 'localhost'  # MariaDB location
    MYSQL_DB = 'nexus_knowledge'
    
    OLLAMA_HOST = 'http://localhost:11434'
    OLLAMA_EMBED_MODEL = 'nomic-embed-text'
    OLLAMA_CODE_MODEL = 'qwen2.5-coder:7b'
    
    SYNCTHING_WATCH_DIRS = [
        '/home/riziki/Sync',
        '/home/riziki/workspace',
        '/home/riziki/Desktop',
    ]
    
    MAX_FILE_SIZE_MB = 100
    BATCH_SIZE = 5
```

## Integration Points

### With JARVIS
- JARVIS queries knowledge graph for context
- NEXUS can trigger JARVIS actions
- Shared memory database: `jarvis_memory`

### With Baileys WhatsApp Bot
- NEXUS queues insights
- Baileys sends ambient whispers
- User feedback loops back to knowledge graph

### With Ollama
- Text embeddings: `nomic-embed-text`
- Code understanding: `qwen2.5-coder:7b`
- Fully local — no API calls

### With Syncthing
- Phone auto-sync to `/home/riziki/Sync`
- Windows auto-sync to `/home/riziki/workspace`
- NEXUS watches and processes automatically

## Monitoring & Logs

Logs stored in: `/home/riziki/workspace/projects/nexus/logs/`

Monitor NEXUS:
```bash
tail -f /home/riziki/workspace/projects/nexus/logs/nexus_ingestor.log
```

Check database stats:
```sql
SELECT COUNT(*) FROM concepts;
SELECT COUNT(*) FROM relationships;
SELECT COUNT(*) FROM sources;
SELECT COUNT(*) FROM insights;
```

## Build Roadmap

- [x] **Phase 1**: Knowledge Graph Schema + Ingestor Foundation
- [ ] **Phase 2**: Code & Systems Track (first semantic model)
- [ ] **Phase 3**: Ambient Delivery (WhatsApp/Telegram)
- [ ] **Phase 4**: Business + Innovation Tracks
- [ ] **Phase 5**: Web Crawler for daily feeds
- [ ] **Phase 6**: Dashboard UI
- [ ] **Phase 7**: Multi-device sync optimization

## Troubleshooting

### "Connection refused" error
```bash
# Check MariaDB
sudo systemctl start mariadb
mysql -u root -e "SELECT 1"

# Check Ollama
curl http://localhost:11434/api/tags
```

### Database schema exists error
```bash
# Drop and recreate
mysql -u root -e "DROP DATABASE nexus_knowledge;"
mysql -u root < nexus_schema.sql
```

### File not being ingested
```bash
# Check Syncthing directories exist
ls -la /home/riziki/Sync /home/riziki/workspace /home/riziki/Desktop

# Check file permissions
chmod 644 /path/to/file

# Manually ingest
python3 nexus_ingestor.py --ingest /path/to/file.pdf
```

### Ollama embedding timeout
```bash
# Restart Ollama
killall ollama
ollama serve &
```

## Performance Metrics

- **File Processing**: 200-1000 words/sec
- **Embedding Generation**: 50-100 words/sec
- **Database Insertion**: 1000+ concepts/sec
- **Query Latency**: <100ms

## Development

### Adding a New Source Type
Edit `FileExtractor` in `nexus_ingestor.py`:
```python
@staticmethod
def extract_markdown(file_path: str) -> str:
    # Your extraction logic
    return text
```

### Adding a New Concept Category
Edit `ConceptCategory` enum:
```python
class ConceptCategory(Enum):
    YOUR_CATEGORY = "YOUR_CATEGORY"
```

### Extending Concept Extraction
Replace rule-based `ConceptExtractor` with LLM-based extraction:
```python
# Use qwen2.5-coder to extract concepts via prompt
```

## Contact & Support

Built by: **Richard Dickson Maina** | RICHIE Server | Kali

For issues, check logs and database state, then report detailed error messages.

---

**NEXUS** — *Where every knowledge becomes wisdom*

✝️ To God Be The Glory — Jesus Is King
