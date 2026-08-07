#!/bin/bash
# ✝️ To God Be The Glory — Jesus Is King
# NEXUS Quick Start Integration Guide
# Built by: Richard Dickson Maina | RICHIE Server

cat << 'EOF'

════════════════════════════════════════════════════════════════════════════════
                        🧠 NEXUS IS ALIVE 🧠
                Neural Exchange for Unified Synthesis & Understanding
════════════════════════════════════════════════════════════════════════════════

✅ PHASE 1 COMPLETE: Foundation (Knowledge Graph + Ingestor)

═══════════════════════════════════════════════════════════════════════════════
                            ✨ WHAT'S RUNNING ✨
═══════════════════════════════════════════════════════════════════════════════

DATABASE LAYER:
  ✅ MariaDB: nexus_knowledge (11 tables)
  ✅ Concepts: 7 core system concepts + extracted from documents
  ✅ Sources: Every PDF/doc/image ingested and indexed
  ✅ Projects: poultry_farm, baileys_bot, jarvis_core, kilo_system, etc.

INGESTOR LAYER:
  ✅ File extractor: PDFs, DOCX, TXT, Markdown, images (OCR-ready)
  ✅ Concept extraction: Sentences → semantic concepts
  ✅ Embedding generation: Via Ollama nomic-embed-text (768-dim)
  ✅ Syncthing watcher: Monitors /home/riziki/Sync, /workspace, /Desktop

VERIFICATION:
  ✅ Database connectivity: Working
  ✅ Schema creation: 11 tables, 7 core concepts, 6 projects
  ✅ Test ingestion: Poultry farm document processed successfully
  ✅ Concept extraction: 7 concepts extracted and linked
  ✅ Database integrity: All relationships verified

═══════════════════════════════════════════════════════════════════════════════
                        🚀 START NEXUS NOW
═══════════════════════════════════════════════════════════════════════════════

METHOD 1: Automated Startup (recommended)
  cd /home/riziki/workspace/projects/nexus
  ./start_nexus.sh

  This will:
  • Create Python virtual environment
  • Install all dependencies
  • Initialize database schema
  • Check Ollama and MariaDB
  • Start full NEXUS Ingestor service

METHOD 2: Manual Startup
  cd /home/riziki/workspace/projects/nexus
  source venv/bin/activate
  python3 nexus_ingestor.py --full

METHOD 3: Watch Mode Only (Syncthing)
  python3 nexus_ingestor.py --watch

METHOD 4: Process Queue Only
  python3 nexus_ingestor.py --queue

═══════════════════════════════════════════════════════════════════════════════
                    📝 DATABASE CREDENTIALS
═══════════════════════════════════════════════════════════════════════════════

Host:     localhost
User:     nexus
Password: nexus_knowledge_2026
Database: nexus_knowledge

Query database directly:
  mysql -u nexus -p"nexus_knowledge_2026" nexus_knowledge

═══════════════════════════════════════════════════════════════════════════════
                        🔄 HOW IT WORKS
═══════════════════════════════════════════════════════════════════════════════

1. YOU SAVE A FILE:
   • Phone PDF → Syncthing → /home/riziki/Sync
   • Windows doc → Syncthing → /home/riziki/workspace
   • Laptop save → /home/riziki/Desktop

2. NEXUS DETECTS IT:
   • Ingestor watches directories every 5 seconds
   • Identifies new/changed files
   • Calculates content hash for deduplication

3. EXTRACTS KNOWLEDGE:
   • Reads text: PDF extraction, OCR, doc parsing
   • Finds concepts: Keyword-based + semantic extraction
   • Generates embeddings: Via Ollama (768-dim)

4. BUILDS THE GRAPH:
   • Stores source in `sources` table
   • Creates concepts in `concepts` table
   • Links with `source_concepts` relationships
   • Auto-categorizes (CODE, BUSINESS, SYSTEM, etc.)

5. READY FOR JARVIS:
   • JARVIS queries the knowledge graph
   • "Tell me about poultry farm" → finds all related docs/concepts
   • Returns context-aware answers

═══════════════════════════════════════════════════════════════════════════════
                      🔍 EXAMPLE QUERIES
═══════════════════════════════════════════════════════════════════════════════

Show all concepts:
  mysql -u nexus -p"nexus_knowledge_2026" nexus_knowledge \
    -e "SELECT name, category, relevance_score FROM concepts ORDER BY relevance_score DESC LIMIT 20;"

Show all ingested sources:
  mysql -u nexus -p"nexus_knowledge_2026" nexus_knowledge \
    -e "SELECT title, source_type, word_count, processing_status FROM sources;"

Show concepts related to a topic:
  mysql -u nexus -p"nexus_knowledge_2026" nexus_knowledge \
    -e "SELECT c.name, COUNT(sc.source_id) as mention_count FROM concepts c \
        LEFT JOIN source_concepts sc ON c.id = sc.concept_id \
        WHERE c.name LIKE '%revenue%' GROUP BY c.id;"

Show projects and their knowledge:
  mysql -u nexus -p"nexus_knowledge_2026" nexus_knowledge \
    -e "SELECT project_id, name, status FROM projects WHERE status='ACTIVE';"

═══════════════════════════════════════════════════════════════════════════════
                        📊 MONITORING
═══════════════════════════════════════════════════════════════════════════════

Watch NEXUS logs in real-time:
  tail -f /home/riziki/workspace/projects/nexus/logs/nexus_ingestor.log

Check database statistics:
  mysql -u nexus -p"nexus_knowledge_2026" nexus_knowledge \
    -e "SELECT (SELECT COUNT(*) FROM concepts) as concepts, \
             (SELECT COUNT(*) FROM sources) as sources, \
             (SELECT COUNT(*) FROM relationships) as relationships, \
             (SELECT COUNT(*) FROM insights) as insights;"

Check processing queue:
  mysql -u nexus -p"nexus_knowledge_2026" nexus_knowledge \
    -e "SELECT status, COUNT(*) FROM ingest_queue GROUP BY status;"

═══════════════════════════════════════════════════════════════════════════════
                    🔧 CONFIGURATION
═══════════════════════════════════════════════════════════════════════════════

Edit config in nexus_ingestor.py:

  # Watch directories (auto-sync folders)
  SYNCTHING_WATCH_DIRS = [
    '/home/riziki/Sync',        # Phone auto-sync
    '/home/riziki/workspace',   # Windows auto-sync
    '/home/riziki/Desktop',     # Quick drops
  ]

  # Ollama models
  OLLAMA_EMBED_MODEL = 'nomic-embed-text'    # For embeddings
  OLLAMA_CODE_MODEL = 'qwen2.5-coder:7b'     # For code analysis

  # Processing limits
  MAX_FILE_SIZE_MB = 100
  BATCH_SIZE = 5
  OLLAMA_TIMEOUT = 60

═══════════════════════════════════════════════════════════════════════════════
                      💡 NEXT PHASE (Phase 2+)
═══════════════════════════════════════════════════════════════════════════════

✅ Phase 1: Knowledge Graph + Ingestor (DONE)
  • Schema: 11 tables, relationships, projects
  • Ingestor: Files → concepts → database
  • Embeddings: Ready for similarity search
  • Syncthing: Auto-watch configured

📋 Phase 2: NEXUS Engine (Insights & Connections)
  • Analyze concept relationships
  • Find patterns across knowledge
  • Connect new info to your projects
  • Generate insights (pattern, opportunity, risk)

🤖 Phase 3: Ambient Delivery (WhatsApp/Telegram)
  • NEXUS queues insights → Baileys bot
  • Calm WhatsApp messages, not interruptions
  • On-demand Telegram deep dives
  • Startup boot-up brief

📚 Phase 4: Knowledge Tracks
  • Code & Systems track first
  • Business & Innovation tracks
  • Personal & Research tracks

🌐 Phase 5: Web Crawler
  • Daily tech news crawling
  • Industry-specific feeds
  • Business intelligence
  • Auto-ingestion into graph

💻 Phase 6: Dashboard
  • Web UI for knowledge exploration
  • Visual relationship graphs
  • Search and discovery
  • Insight timeline

═══════════════════════════════════════════════════════════════════════════════
                      🛠️ TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════════════════

"Connection refused" error:
  • Check MariaDB: sudo systemctl status mariadb
  • Start if needed: sudo systemctl start mariadb

Ollama timeout:
  • Check running: curl http://localhost:11434/api/tags
  • Restart: killall ollama; ollama serve &

Files not ingesting:
  • Check watch directories exist and are writable
  • Manually test: python3 nexus_ingestor.py --ingest /path/to/file

Schema already exists:
  • Drop and recreate: mysql -u nexus -p"nexus_knowledge_2026" \
      -e "DROP DATABASE nexus_knowledge;" && \
      sudo mysql < nexus_schema.sql

═══════════════════════════════════════════════════════════════════════════════

                    ✝️ To God Be The Glory — Jesus Is King
                         NEXUS: Where Knowledge Becomes Wisdom

════════════════════════════════════════════════════════════════════════════════

EOF
