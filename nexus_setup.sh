#!/bin/bash
# ============================================================
# NEXUS COMPLETE SETUP SCRIPT
# Neural Exchange for Unified Synthesis & Understanding
# Run this on Kali: bash nexus_setup.sh
# ============================================================

set -e
NEXUS_DIR="$HOME/workspace/projects/nexus"
LOG_DIR="$HOME/workspace/logs"
VENV="$NEXUS_DIR/venv"

echo "============================================================"
echo "  NEXUS - Neural Exchange for Unified Synthesis"
echo "  Setting up your living intelligence system..."
echo "============================================================"

mkdir -p "$NEXUS_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$HOME/workspace/nexus-watch/phone"
mkdir -p "$HOME/workspace/nexus-watch/windows"
mkdir -p "$HOME/workspace/nexus-watch/web"
mkdir -p "$HOME/.config/nexus"

echo "[1/7] Directories created"

cd "$NEXUS_DIR"
python3 -m venv venv
source venv/bin/activate
echo "[2/7] Virtual environment created"

pip install -q --upgrade pip
pip install -q pymysql requests python-dotenv watchdog PyPDF2 pdfplumber python-docx pillow schedule flask redis telebot nltk scikit-learn numpy
echo "[3/7] Dependencies installed"

python3 -c "
import nltk
nltk.download('punkt', quiet=True)
nltk.download('stopwords', quiet=True)
nltk.download('averaged_perceptron_tagger', quiet=True)
"
echo "[4/7] NLTK data downloaded"

echo "[5/7] Setting up database..."
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
    INDEX idx_processed (processed),
    INDEX idx_source (source_type)
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
    processed_at TIMESTAMP NULL,
    INDEX idx_status (status)
);

CREATE TABLE IF NOT EXISTS delivery_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    channel ENUM('whatsapp','telegram','startup'),
    message TEXT,
    insight_id INT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO projects (name, path, description, tech_stack) VALUES
('jarvis', '~/workspace/projects/jarvis', 'Personal AI assistant - brain of ecosystem', 'Python,Flask,Telegram,WhatsApp'),
('baileys-bot', '~/workspace/projects/baileys-bot', 'WhatsApp automation layer', 'Node.js,Baileys,WebSocket'),
('poultry-farm-system', '~/workspace/projects/poultry-farm-system', 'Farm management system', 'PHP,Python,MariaDB'),
('career-ops', '~/workspace/projects/career-ops', 'Job application automation pipeline', 'Node.js,TypeScript'),
('backend', '~/workspace/projects/backend', 'Shared backend services', 'Python,Node.js'),
('nexus', '~/workspace/projects/nexus', 'Living intelligence system', 'Python,MariaDB,Redis');

INSERT IGNORE INTO concepts (name, category, description, importance_score) VALUES
('Python', 'technical', 'Primary programming language', 0.9),
('JavaScript', 'technical', 'Frontend and Node.js development', 0.9),
('TypeScript', 'technical', 'Typed JavaScript for career-ops', 0.8),
('PHP', 'technical', 'Poultry farm system backend', 0.7),
('MariaDB', 'technical', 'Primary database system', 0.9),
('Redis', 'technical', 'Message bus and caching layer', 0.8),
('WhatsApp API', 'technical', 'Primary communication interface', 0.9),
('Machine Learning', 'technical', 'AI/ML concepts and applications', 0.8),
('Business Strategy', 'business', 'Strategic planning and execution', 0.8),
('Product Management', 'business', 'PPM and project lifecycle', 0.7),
('Cybersecurity', 'technical', 'Security practices and threat awareness', 0.8),
('System Architecture', 'technical', 'Designing scalable systems', 0.9),
('Innovation', 'innovation', 'Creative problem solving and new ideas', 0.8),
('Automation', 'technical', 'Workflow and process automation', 0.9),
('Networking', 'technical', 'Computer networking fundamentals', 0.7);
SQLEOF

echo "[6/7] Database initialized with schema and seed data"

sudo tee /etc/systemd/system/nexus.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=NEXUS - Living Intelligence System
After=network.target mariadb.service redis.service
Wants=mariadb.service

[Service]
Type=simple
User=riziki
WorkingDirectory=/home/riziki/workspace/projects/nexus
ExecStart=/home/riziki/workspace/projects/nexus/venv/bin/python3 /home/riziki/workspace/projects/nexus/nexus_ingestor.py
Restart=always
RestartSec=10
StandardOutput=append:/home/riziki/workspace/logs/nexus.log
StandardError=append:/home/riziki/workspace/logs/nexus-error.log
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SERVICEEOF

sudo systemctl daemon-reload
echo "[7/7] Systemd service registered"

echo ""
echo "============================================================"
echo "  NEXUS Setup Complete!"
echo "  Next: python3 nexus_ingestor.py --test"
echo "============================================================"
