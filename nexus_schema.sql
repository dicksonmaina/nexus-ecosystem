-- ✝️ To God Be The Glory — Jesus Is King
-- NEXUS Knowledge Graph Schema
-- Built by: Richard Dickson Maina | RICHIE Server
-- Living Intelligence System

-- ==============================================================================
-- DATABASE CREATION
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS nexus_knowledge
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE nexus_knowledge;

-- ==============================================================================
-- CORE CONCEPTS TABLE
-- ==============================================================================

CREATE TABLE IF NOT EXISTS concepts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    concept_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category ENUM(
        'CODE',
        'SYSTEM',
        'BUSINESS',
        'INNOVATION',
        'PERSONAL',
        'RESEARCH',
        'TOOL',
        'PATTERN',
        'PROBLEM',
        'SOLUTION'
    ) NOT NULL DEFAULT 'RESEARCH',
    
    -- Semantic embedding (stored as JSON array, loaded from ChromaDB)
    embedding_id VARCHAR(255),
    embedding_dimension INT DEFAULT 768,
    
    -- Recency tracking
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    access_count INT DEFAULT 0,
    
    -- Confidence/relevance
    relevance_score FLOAT DEFAULT 0.5,
    
    -- Metadata
    source_track ENUM('CODE', 'SYSTEMS', 'BUSINESS', 'INNOVATION') DEFAULT 'SYSTEMS',
    is_core BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Project association
    project_id INT,
    
    -- Content hash for deduplication
    content_hash VARCHAR(64),
    
    INDEX idx_concept_id (concept_id),
    INDEX idx_category (category),
    INDEX idx_source_track (source_track),
    INDEX idx_project_id (project_id),
    INDEX idx_last_updated (last_updated),
    INDEX idx_relevance_score (relevance_score DESC),
    FULLTEXT INDEX ft_name_description (name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- RELATIONSHIPS TABLE
-- ==============================================================================

CREATE TABLE IF NOT EXISTS relationships (
    id INT PRIMARY KEY AUTO_INCREMENT,
    concept_a_id INT NOT NULL,
    concept_b_id INT NOT NULL,
    
    -- Type of relationship
    relationship_type ENUM(
        'DEPENDS_ON',
        'FEEDS_INTO',
        'RELATED_TO',
        'CONFLICTS_WITH',
        'ENABLES',
        'REQUIRED_FOR',
        'SOLVES',
        'EXTENDS',
        'IMPLEMENTS',
        'REFERENCES'
    ) NOT NULL DEFAULT 'RELATED_TO',
    
    -- Strength of connection (0-1)
    strength FLOAT DEFAULT 0.5,
    
    -- Why they're connected
    reason TEXT,
    
    -- Directional (A → B or bidirectional)
    is_bidirectional BOOLEAN DEFAULT FALSE,
    
    -- Tracking
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Source document
    inferred_from_source_id INT,
    
    INDEX idx_concept_a (concept_a_id),
    INDEX idx_concept_b (concept_b_id),
    INDEX idx_type (relationship_type),
    INDEX idx_strength (strength DESC),
    UNIQUE KEY unique_pair (concept_a_id, concept_b_id, relationship_type),
    FOREIGN KEY (concept_a_id) REFERENCES concepts(id) ON DELETE CASCADE,
    FOREIGN KEY (concept_b_id) REFERENCES concepts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- SOURCES TABLE
-- ==============================================================================

CREATE TABLE IF NOT EXISTS sources (
    id INT PRIMARY KEY AUTO_INCREMENT,
    source_id VARCHAR(255) UNIQUE NOT NULL,
    
    -- Source metadata
    source_type ENUM(
        'PDF',
        'DOCUMENT',
        'IMAGE',
        'URL',
        'CODE_REPO',
        'EMAIL',
        'WHATSAPP',
        'TELEGRAM',
        'SYNCTHING',
        'CRAWLED'
    ) NOT NULL,
    
    title VARCHAR(255),
    url VARCHAR(500),
    file_path VARCHAR(500),
    mime_type VARCHAR(50),
    
    -- Content
    raw_content LONGTEXT,
    extracted_text LONGTEXT,
    
    -- Processing
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    indexed_at TIMESTAMP NULL,
    processing_status ENUM('PENDING', 'PROCESSING', 'INDEXED', 'FAILED') DEFAULT 'PENDING',
    error_message TEXT,
    
    -- Stats
    word_count INT DEFAULT 0,
    concept_count INT DEFAULT 0,
    
    -- Metadata
    ingested_by VARCHAR(100),
    device_origin ENUM('PHONE', 'WINDOWS', 'KALI', 'WEB') DEFAULT 'KALI',
    
    -- Tracking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_source_id (source_id),
    INDEX idx_source_type (source_type),
    INDEX idx_processing_status (processing_status),
    INDEX idx_processed_at (processed_at),
    INDEX idx_device_origin (device_origin),
    FULLTEXT INDEX ft_title_content (title, extracted_text)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- SOURCE-CONCEPT MAPPING
-- ==============================================================================

CREATE TABLE IF NOT EXISTS source_concepts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    source_id INT NOT NULL,
    concept_id INT NOT NULL,
    
    -- Relevance of this concept in this source
    relevance_score FLOAT DEFAULT 0.5,
    
    -- How many times mentioned
    mention_count INT DEFAULT 1,
    
    -- Position (paragraph/section)
    context_excerpt TEXT,
    page_number INT,
    
    INDEX idx_source_id (source_id),
    INDEX idx_concept_id (concept_id),
    INDEX idx_relevance (relevance_score DESC),
    UNIQUE KEY unique_source_concept (source_id, concept_id),
    FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE CASCADE,
    FOREIGN KEY (concept_id) REFERENCES concepts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- PROJECTS TABLE
-- ==============================================================================

CREATE TABLE IF NOT EXISTS projects (
    id INT PRIMARY KEY AUTO_INCREMENT,
    project_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Project type
    project_type ENUM(
        'POULTRY_FARM',
        'BAILEYS_BOT',
        'JARVIS',
        'KILO_SYSTEM',
        'CAREER_OPS',
        'RESEARCH',
        'INFRASTRUCTURE'
    ) NOT NULL,
    
    -- Status
    status ENUM('ACTIVE', 'PAUSED', 'COMPLETED', 'PLANNING') DEFAULT 'ACTIVE',
    
    -- Tracking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Associated repository path
    repo_path VARCHAR(500),
    
    -- Core concepts for this project
    core_concept_ids JSON,
    
    INDEX idx_project_id (project_id),
    INDEX idx_project_type (project_type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- INSIGHTS TABLE (Generated by NEXUS Engine)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS insights (
    id INT PRIMARY KEY AUTO_INCREMENT,
    insight_id VARCHAR(255) UNIQUE NOT NULL,
    
    -- The insight
    title VARCHAR(255) NOT NULL,
    description TEXT,
    insight_type ENUM(
        'PATTERN',
        'OPPORTUNITY',
        'RISK',
        'RECOMMENDATION',
        'CONNECTION',
        'OPTIMIZATION'
    ) NOT NULL,
    
    -- What it connects
    related_concepts JSON,
    related_projects JSON,
    related_sources JSON,
    
    -- Confidence
    confidence_score FLOAT DEFAULT 0.5,
    
    -- Delivery
    delivery_channel ENUM('WHATSAPP', 'TELEGRAM', 'STARTUP_BRIEF', 'DASHBOARD') DEFAULT 'WHATSAPP',
    delivered_at TIMESTAMP NULL,
    
    -- Tracking
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_insight_id (insight_id),
    INDEX idx_type (insight_type),
    INDEX idx_generated_at (generated_at),
    INDEX idx_delivered_at (delivered_at),
    FULLTEXT INDEX ft_title_description (title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- INGEST QUEUE
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ingest_queue (
    id INT PRIMARY KEY AUTO_INCREMENT,
    queue_id VARCHAR(255) UNIQUE NOT NULL,
    
    -- What to ingest
    file_path VARCHAR(500),
    url VARCHAR(500),
    
    -- Status
    status ENUM('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED') DEFAULT 'PENDING',
    
    -- Tracking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,
    error_message TEXT,
    
    -- Metadata
    priority INT DEFAULT 0,
    source_device ENUM('PHONE', 'WINDOWS', 'KALI', 'WEB') DEFAULT 'KALI',
    
    INDEX idx_status (status),
    INDEX idx_priority (priority DESC),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- USAGE STATISTICS
-- ==============================================================================

CREATE TABLE IF NOT EXISTS usage_stats (
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Daily rollup
    stat_date DATE NOT NULL UNIQUE,
    
    -- Counts
    new_concepts INT DEFAULT 0,
    new_relationships INT DEFAULT 0,
    new_sources INT DEFAULT 0,
    new_insights INT DEFAULT 0,
    
    -- Activity
    concepts_accessed INT DEFAULT 0,
    relationships_queried INT DEFAULT 0,
    sources_ingested INT DEFAULT 0,
    
    -- Performance
    avg_ingest_time_ms INT DEFAULT 0,
    avg_query_time_ms INT DEFAULT 0,
    
    -- Tracking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_stat_date (stat_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- INITIAL SYSTEM CONCEPTS (Seed Data)
-- ==============================================================================

INSERT INTO concepts (concept_id, name, category, source_track, is_core)
VALUES
    ('NEXUS_CORE', 'NEXUS Core System', 'SYSTEM', 'SYSTEMS', TRUE),
    ('KNOWLEDGE_GRAPH', 'Knowledge Graph Architecture', 'SYSTEM', 'SYSTEMS', TRUE),
    ('SYNC_ENGINE', 'Syncthing Auto-Sync', 'SYSTEM', 'SYSTEMS', TRUE),
    ('MARIADB_INSTANCE', 'MariaDB Central Database', 'SYSTEM', 'SYSTEMS', TRUE),
    ('OLLAMA_EMBEDDINGS', 'Ollama Embeddings (qwen2.5-coder)', 'TOOL', 'CODE', TRUE),
    ('JARVIS_INTEGRATION', 'JARVIS Memory Framework', 'SYSTEM', 'SYSTEMS', TRUE),
    ('CHROMADB_VECTOR', 'ChromaDB Vector Store', 'TOOL', 'SYSTEMS', TRUE)
ON DUPLICATE KEY UPDATE concept_id = concept_id;

-- ==============================================================================
-- INITIAL PROJECT SEEDING
-- ==============================================================================

INSERT INTO projects (project_id, name, project_type, status)
VALUES
    ('poultry_farm', 'Poultry Farm System', 'POULTRY_FARM', 'ACTIVE'),
    ('baileys_bot', 'Baileys WhatsApp Bot', 'BAILEYS_BOT', 'ACTIVE'),
    ('jarvis_core', 'JARVIS Memory System', 'JARVIS', 'ACTIVE'),
    ('kilo_system', 'KILO Diagnostic System', 'KILO_SYSTEM', 'ACTIVE'),
    ('career_ops', 'Career Operations', 'CAREER_OPS', 'ACTIVE'),
    ('nexus_engine', 'NEXUS Intelligence Engine', 'RESEARCH', 'ACTIVE')
ON DUPLICATE KEY UPDATE project_id = project_id;

-- ==============================================================================
-- VIEWS FOR COMMON QUERIES
-- ==============================================================================

CREATE OR REPLACE VIEW top_concepts AS
SELECT 
    c.concept_id,
    c.name,
    c.category,
    c.relevance_score,
    COUNT(DISTINCT sc.source_id) as source_count,
    COUNT(DISTINCT r.id) as relationship_count,
    c.last_updated
FROM concepts c
LEFT JOIN source_concepts sc ON c.id = sc.concept_id
LEFT JOIN relationships r ON c.id = r.concept_a_id OR c.id = r.concept_b_id
WHERE c.is_active = TRUE
GROUP BY c.id
ORDER BY c.relevance_score DESC, source_count DESC;

CREATE OR REPLACE VIEW project_knowledge_map AS
SELECT 
    p.project_id,
    p.name,
    COUNT(DISTINCT c.id) as concept_count,
    COUNT(DISTINCT sc.source_id) as source_count,
    COUNT(DISTINCT r.id) as relationship_count,
    MAX(c.last_updated) as last_activity
FROM projects p
LEFT JOIN concepts c ON FIND_IN_SET(c.id, JSON_EXTRACT(p.core_concept_ids, '$[*]'))
LEFT JOIN source_concepts sc ON c.id = sc.concept_id
LEFT JOIN relationships r ON c.id = r.concept_a_id OR c.id = r.concept_b_id
WHERE p.status = 'ACTIVE'
GROUP BY p.id;

CREATE OR REPLACE VIEW recent_insights AS
SELECT 
    insight_id,
    title,
    insight_type,
    confidence_score,
    delivery_channel,
    generated_at,
    delivered_at,
    CASE 
        WHEN delivered_at IS NULL THEN 'PENDING'
        ELSE 'DELIVERED'
    END as status
FROM insights
WHERE generated_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY generated_at DESC;

-- ==============================================================================
-- STORED PROCEDURES FOR COMMON OPERATIONS
-- ==============================================================================

DELIMITER $$

CREATE PROCEDURE sp_add_concept_with_relationships(
    IN p_concept_id VARCHAR(255),
    IN p_name VARCHAR(255),
    IN p_description TEXT,
    IN p_category VARCHAR(50),
    IN p_project_id INT
)
BEGIN
    DECLARE v_concept_id INT;
    
    INSERT INTO concepts (concept_id, name, description, category, project_id)
    VALUES (p_concept_id, p_name, p_description, p_category, p_project_id)
    ON DUPLICATE KEY UPDATE 
        name = p_name,
        description = p_description,
        updated_at = CURRENT_TIMESTAMP;
    
    SET v_concept_id = LAST_INSERT_ID();
    
    SELECT v_concept_id as concept_id;
END$$

CREATE PROCEDURE sp_record_access(
    IN p_concept_id INT
)
BEGIN
    UPDATE concepts 
    SET access_count = access_count + 1,
        last_updated = CURRENT_TIMESTAMP
    WHERE id = p_concept_id;
END$$

CREATE PROCEDURE sp_calculate_relevance(
    IN p_concept_id INT
)
BEGIN
    UPDATE concepts c
    SET relevance_score = (
        (access_count * 0.2) +
        ((SELECT COUNT(*) FROM source_concepts WHERE concept_id = p_concept_id) * 0.3) +
        ((SELECT COUNT(*) FROM relationships WHERE concept_a_id = p_concept_id OR concept_b_id = p_concept_id) * 0.3) +
        (DATEDIFF(NOW(), last_updated) / 365 * 0.2)
    ) / 100
    WHERE id = p_concept_id;
END$$

DELIMITER ;

-- ==============================================================================
-- VERIFICATION QUERIES
-- ==============================================================================

-- Check schema creation
SELECT 'Schema created successfully' as status;
SELECT COUNT(*) as table_count FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'nexus_knowledge';
SELECT COUNT(*) as concept_count FROM concepts WHERE is_core = TRUE;
SELECT COUNT(*) as project_count FROM projects;
