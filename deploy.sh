#!/bin/bash
# ============================================================
# NEXUS DEPLOY — Run this ONE command on Kali
# ============================================================

set -e
NEXUS="$HOME/workspace/projects/nexus"
LOGS="$HOME/workspace/logs"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  NEXUS — Living Intelligence System          ║"
echo "║  Deploying to your Kali server...            ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

echo "▶ Creating directories..."
mkdir -p "$NEXUS"
mkdir -p "$LOGS"
mkdir -p "$HOME/workspace/nexus-watch/phone"
mkdir -p "$HOME/workspace/nexus-watch/windows"
mkdir -p "$HOME/workspace/nexus-watch/web"
mkdir -p "$HOME/Sync/phone" 2>/dev/null || true
mkdir -p "$HOME/Sync/windows" 2>/dev/null || true
echo "  ✓ Directories ready"

echo "▶ Copying NEXUS files..."
for f in nexus_ingestor.py nexus_engine.py nexus_jarvis_bridge.py requirements.txt; do
    if [ -f "$HOME/$f" ]; then
        cp "$HOME/$f" "$NEXUS/"
        echo "  ✓ Copied $f"
    elif [ -f "$NEXUS/$f" ]; then
        echo "  ✓ Already present: $f"
    else
        echo "  ⚠ Missing: $f — upload it first"
    fi
done

echo "▶ Setting up Python environment..."
cd "$NEXUS"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt
echo "  ✓ Dependencies installed"

echo "▶ Downloading NLTK data..."
python3 -c "
import nltk
nltk.download('punkt', quiet=True)
nltk.download('stopwords', quiet=True)
print('  ✓ NLTK ready')
"

echo "▶ Setting up database..."
sudo mysql << 'SQLEOF'
CREATE DATABASE IF NOT EXISTS nexus_knowledge CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'nexus'@'localhost' IDENTIFIED BY 'nexus_knowledge_2026';
GRANT ALL PRIVILEGES ON nexus_knowledge.* TO 'nexus'@'localhost';
FLUSH PRIVILEGES;
USE nexus_knowledge;

CREATE TABLE IF NOT EXISTS sources (
    id INT AUTO_INCREMENT PRIMARY KEY,
    file_path VARCHAR(1000),
    file_name VARCHAR(500),
    file_type VARCHAR(50),
    source_type ENUM('phone','windows','web','manual') DEFAULT 'manual',
    content_hash VARCHAR(64) UNIQUE,
    raw_text LONGTEXT,
    processed BOOLEAN DEFAULT FALSE,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hash (content_hash),
    INDEX idx_processed (processed)
);

CREATE TABLE IF NOT EXISTS concepts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(500) NOT NULL,
    category ENUM('technical','business','innovation','security','general') DEFAULT 'general',
    description TEXT,
    frequency INT DEFAULT 1,
    importance_score FLOAT DEFAULT 0.5,
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_concept (name),
    INDEX idx_category (category),
    INDEX idx_importance (importance_score)
);

CREATE TABLE IF NOT EXISTS concept_source (
    concept_id INT,
    source_id INT,
    relevance_score FLOAT DEFAULT 0.5,
    PRIMARY KEY (concept_id, source_id),
    FOREIGN KEY (concept_id) REFERENCES concepts(id) ON DELETE CASCADE,
    FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS concept_relations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    concept_a INT,
    concept_b INT,
    relation_type VARCHAR(100),
    strength FLOAT DEFAULT 0.5,
    FOREIGN KEY (concept_a) REFERENCES concepts(id) ON DELETE CASCADE,
    FOREIGN KEY (concept_b) REFERENCES concepts(id) ON DELETE CASCADE,
    UNIQUE KEY unique_relation (concept_a, concept_b, relation_type)
);

CREATE TABLE IF NOT EXISTS insights (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(500),
    content TEXT,
    insight_type ENUM('pattern','opportunity','risk','recommendation','connection') DEFAULT 'pattern',
    related_project VARCHAR(200),
    delivered BOOLEAN DEFAULT FALSE,
    delivery_channel ENUM('whatsapp','telegram','startup') DEFAULT 'whatsapp',
    priority INT DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP NULL,
    INDEX idx_delivered (delivered),
    INDEX idx_priority (priority)
);

CREATE TABLE IF NOT EXISTS projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) UNIQUE,
    path VARCHAR(500),
    description TEXT,
    tech_stack VARCHAR(500),
    active BOOLEAN DEFAULT TRUE,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS knowledge_tracks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    track ENUM('code_systems','business','innovation') NOT NULL,
    concept_id INT,
    mastery_level FLOAT DEFAULT 0.0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (concept_id) REFERENCES concepts(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS web_crawl_queue (
    id INT AUTO_INCREMENT PRIMARY KEY,
    url VARCHAR(2000),
    status ENUM('pending','processing','done','failed') DEFAULT 'pending',
    priority INT DEFAULT 5,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL
);

CREATE TABLE IF NOT EXISTS delivery_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    channel ENUM('whatsapp','telegram','startup'),
    message TEXT,
    insight_id INT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO projects (name, path, description, tech_stack) VALUES
('jarvis', '~/workspace/projects/jarvis', 'Personal AI assistant', 'Python,Flask,Telegram,WhatsApp'),
('baileys-bot', '~/workspace/projects/baileys-bot', 'WhatsApp automation', 'Node.js,Baileys'),
('poultry-farm-system', '~/workspace/projects/poultry-farm-system', 'Farm management', 'PHP,Python,MariaDB'),
('career-ops', '~/workspace/projects/career-ops', 'Job pipeline', 'Node.js,TypeScript'),
('backend', '~/workspace/projects/backend', 'Shared APIs', 'Python,Node.js'),
('nexus', '~/workspace/projects/nexus', 'Living intelligence', 'Python,MariaDB,Redis');

INSERT IGNORE INTO concepts (name, category, description, importance_score) VALUES
('Python', 'technical', 'Primary programming language', 0.9),
('JavaScript', 'technical', 'Frontend and Node.js', 0.9),
('TypeScript', 'technical', 'Typed JavaScript', 0.8),
('MariaDB', 'technical', 'Primary database', 0.9),
('Redis', 'technical', 'Message bus', 0.8),
('WhatsApp API', 'technical', 'Communication layer', 0.9),
('Machine Learning', 'technical', 'AI/ML concepts', 0.8),
('Business Strategy', 'business', 'Strategic planning', 0.8),
('Cybersecurity', 'technical', 'Security practices', 0.8),
('Automation', 'technical', 'Workflow automation', 0.9),
('System Architecture', 'technical', 'System design', 0.9),
('Innovation', 'innovation', 'Creative problem solving', 0.8);
SQLEOF
echo "  ✓ Database ready"

echo "▶ Registering services..."

sudo tee /etc/systemd/system/nexus-ingestor.service > /dev/null << EOF
[Unit]
Description=NEXUS Ingestor - File Watcher
After=network.target mariadb.service
Wants=mariadb.service

[Service]
Type=simple
User=riziki
WorkingDirectory=$NEXUS
ExecStart=$NEXUS/venv/bin/python3 $NEXUS/nexus_ingestor.py
Restart=always
RestartSec=10
StandardOutput=append:$LOGS/nexus-ingestor.log
StandardError=append:$LOGS/nexus-ingestor-error.log
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/nexus-engine.service > /dev/null << EOF
[Unit]
Description=NEXUS Engine - Pattern Finder
After=network.target mariadb.service nexus-ingestor.service
Wants=mariadb.service

[Service]
Type=simple
User=riziki
WorkingDirectory=$NEXUS
ExecStart=$NEXUS/venv/bin/python3 $NEXUS/nexus_engine.py
Restart=always
RestartSec=30
StandardOutput=append:$LOGS/nexus-engine.log
StandardError=append:$LOGS/nexus-engine-error.log
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nexus-ingestor.service
sudo systemctl enable nexus-engine.service
echo "  ✓ Services registered and enabled"

echo "▶ Adding NEXUS to JARVIS..."
JARVIS_HANDLER="$HOME/workspace/projects/jarvis/whatsapp_handler.py"
if [ -f "$JARVIS_HANDLER" ]; then
    if ! grep -q "nexus_jarvis_bridge" "$JARVIS_HANDLER"; then
        sed -i '1s/^/# NEXUS Integration\ntry:\n    sys.path.insert(0, "\/home\/riziki\/workspace\/projects\/nexus")\n    from nexus_jarvis_bridge import handle_nexus_query\n    NEXUS_ENABLED = True\nexcept ImportError:\n    NEXUS_ENABLED = False\n\n/' "$JARVIS_HANDLER"
        echo "  ✓ NEXUS bridge added to JARVIS"
    else
        echo "  ✓ NEXUS already integrated with JARVIS"
    fi
else
    echo "  ⚠ JARVIS handler not found — add bridge manually"
fi

echo "▶ Testing NEXUS..."
cd "$NEXUS"
source venv/bin/activate
python3 nexus_ingestor.py --test

echo "▶ Starting NEXUS services..."
sudo systemctl start nexus-ingestor.service
sleep 2
sudo systemctl start nexus-engine.service
sleep 2

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅ NEXUS DEPLOYED SUCCESSFULLY              ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Services running:                           ║"
echo "║  • nexus-ingestor (file watcher)             ║"
echo "║  • nexus-engine (pattern finder)             ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Drop files here to learn:                   ║"
echo "║  ~/workspace/nexus-watch/phone/              ║"
echo "║  ~/workspace/nexus-watch/windows/            ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Commands (via WhatsApp/Telegram):           ║"
echo "║  • nexus          → knowledge summary        ║"
echo "║  • teach me X     → learn about topic X      ║"
echo "║  • nexus briefing → full morning briefing    ║"
echo "║  • nexus insights → pending insights         ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Check logs:                                 ║"
echo "║  tail -f ~/workspace/logs/nexus-ingestor.log ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "NEXUS is alive. It breathes with you. 🌱"
