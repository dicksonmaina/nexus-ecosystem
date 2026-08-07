#!/usr/bin/env python3
"""
NEXUS Engine - Pattern Finder & Insight Generator
"""

import os
import sys
import time
import logging
import schedule
import threading
from datetime import datetime, timedelta
from collections import defaultdict

import pymysql
import requests
from dotenv import load_dotenv

load_dotenv(os.path.expanduser("~/.env"))

LOG_DIR = os.path.expanduser("~/workspace/logs")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [NEXUS-ENGINE] %(levelname)s: %(message)s",
    handlers=[
        logging.FileHandler(f"{LOG_DIR}/nexus-engine.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
log = logging.getLogger("nexus-engine")

DB_CONFIG = {
    "host": "localhost",
    "user": "nexus",
    "password": "nexus_knowledge_2026",
    "database": "nexus_knowledge",
    "charset": "utf8mb4",
    "cursorclass": pymysql.cursors.DictCursor
}

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_MODEL = "llama-3.1-8b-instant"

def get_db():
    return pymysql.connect(**DB_CONFIG)

def db_execute(query, params=None, fetch=False):
    try:
        conn = get_db()
        with conn:
            with conn.cursor() as cursor:
                cursor.execute(query, params or ())
                if fetch:
                    return cursor.fetchall()
                conn.commit()
                return cursor.lastrowid
    except Exception as e:
        log.error(f"DB error: {e}")
        return None

def find_patterns():
    log.info("🔍 Scanning for patterns...")
    trending = db_execute(
        """SELECT c.name, c.category, c.frequency, COUNT(cs.source_id) as source_count
           FROM concepts c JOIN concept_source cs ON c.id = cs.concept_id
           GROUP BY c.id HAVING source_count > 1 ORDER BY source_count DESC, c.frequency DESC LIMIT 10""",
        fetch=True
    )
    if not trending:
        return
    for concept in trending:
        existing = db_execute(
            """SELECT id FROM insights WHERE title LIKE %s AND created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)""",
            (f"%{concept['name']}%",), fetch=True
        )
        if existing:
            continue
        db_execute(
            """INSERT INTO insights (title, content, insight_type, priority)
               VALUES (%s, %s, 'pattern', %s)""",
            (
                f"Pattern: {concept['name']} appearing frequently",
                f"'{concept['name']}' ({concept['category']}) has appeared in {concept['source_count']} documents with {concept['frequency']} total mentions. This pattern suggests growing importance.",
                min(concept['source_count'] + 4, 9)
            )
        )
        log.info(f"📊 Pattern found: {concept['name']} in {concept['source_count']} sources")

def find_cross_track_connections():
    log.info("🔗 Finding cross-track connections...")
    bridge_concepts = db_execute(
        """SELECT c.name,
                  SUM(CASE WHEN c.category IN ('technical') THEN 1 ELSE 0 END) as tech_count,
                  SUM(CASE WHEN c.category IN ('business') THEN 1 ELSE 0 END) as biz_count
           FROM concepts c WHERE c.category IN ('technical','business')
           GROUP BY c.name HAVING tech_count > 0 AND biz_count > 0 LIMIT 5""",
        fetch=True
    )
    for concept in (bridge_concepts or []):
        db_execute(
            """INSERT IGNORE INTO insights (title, content, insight_type, priority)
               VALUES (%s, %s, 'connection', 7)""",
            (f"Bridge concept: {concept['name']}",
             f"'{concept['name']}' connects both technical and business domains.")
        )

def analyze_project_gaps():
    log.info("🎯 Analyzing project knowledge gaps...")
    projects = db_execute("SELECT name, tech_stack FROM projects WHERE active = TRUE", fetch=True)
    for project in (projects or []):
        tech_stack = (project.get("tech_stack") or "").split(",")
        for tech in tech_stack:
            tech = tech.strip()
            if not tech:
                continue
            knowledge = db_execute("SELECT COUNT(*) as cnt FROM concepts WHERE name LIKE %s", (f"%{tech}%",), fetch=True)
            count = knowledge[0]["cnt"] if knowledge else 0
            if count < 2:
                db_execute(
                    """INSERT IGNORE INTO insights (title, content, insight_type, related_project, priority)
                       VALUES (%s, %s, 'recommendation', %s, 6)""",
                    (f"Knowledge gap: {tech} for {project['name']}",
                     f"Your '{project['name']}' project uses {tech}, but your knowledge base has limited info. Add learning materials about {tech}.",
                     project["name"])
                )

def generate_ai_insight():
    if not GROQ_API_KEY:
        return
    recent_concepts = db_execute(
        "SELECT name, category, frequency FROM concepts ORDER BY last_seen DESC, frequency DESC LIMIT 10",
        fetch=True
    )
    if not recent_concepts:
        return
    concept_list = ", ".join([c["name"] for c in recent_concepts])
    try:
        response = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"},
            json={
                "model": GROQ_MODEL,
                "max_tokens": 200,
                "messages": [{"role":"user","content":f"""You are an ambient intelligence assistant.
Based on these recently learned concepts: {concept_list}
Generate ONE brief, practical insight (2-3 sentences) that:
1. Connects 2-3 concepts non-obviously
2. Relates to building software or growing a business
3. Feels like a calm whisper from a wise advisor
Be specific and actionable. No preamble."""}]
            },
            timeout=15
        )
        if response.status_code == 200:
            data = response.json()
            insight_text = data["choices"][0]["message"]["content"].strip()
            db_execute(
                """INSERT INTO insights (title, content, insight_type, priority)
                   VALUES (%s, %s, 'recommendation', 7)""",
                (f"AI Insight — {datetime.now().strftime('%b %d')}", insight_text)
            )
            log.info(f"🤖 AI insight generated")
    except Exception as e:
        log.debug(f"AI insight skipped: {e}")

def deliver_insights():
    insights = db_execute("SELECT * FROM insights WHERE delivered = FALSE ORDER BY priority DESC, created_at ASC LIMIT 5", fetch=True)
    if not insights:
        return
    log.info(f"📤 Delivering {len(insights)} insights...")
    for insight in insights:
        message = f"🧠 *NEXUS Insight*\n\n*{insight['title']}*\n\n{insight['content']}"
        if insight.get("related_project"):
            message += f"\n\n_Related to: {insight['related_project']}_"
        delivered = False
        try:
            response = requests.post("http://localhost:5000/nexus-insight", json={"message": message}, timeout=5)
            delivered = response.status_code == 200
        except Exception:
            pass
        if not delivered:
            log.info(f"📝 {insight['title']}: {insight['content'][:100]}...")
        db_execute("UPDATE insights SET delivered = TRUE, delivered_at = CURRENT_TIMESTAMP WHERE id = %s", (insight["id"],))

def build_concept_relations():
    log.info("🕸 Building concept relations...")
    cooccurring = db_execute(
        """SELECT cs1.concept_id as a, cs2.concept_id as b, COUNT(*) as co_count
           FROM concept_source cs1 JOIN concept_source cs2 ON cs1.source_id = cs2.source_id
           WHERE cs1.concept_id < cs2.concept_id GROUP BY cs1.concept_id, cs2.concept_id HAVING co_count >= 2 LIMIT 50""",
        fetch=True
    )
    for pair in (cooccurring or []):
        strength = min(pair["co_count"] / 10.0, 1.0)
        db_execute(
            """INSERT INTO concept_relations (concept_a, concept_b, relation_type, strength)
               VALUES (%s, %s, 'co-occurrence', %s) ON DUPLICATE KEY UPDATE strength = %s""",
            (pair["a"], pair["b"], strength, strength)
        )

def run_engine():
    log.info("⚡ NEXUS Engine starting...")
    find_patterns()
    analyze_project_gaps()
    build_concept_relations()
    deliver_insights()
    schedule.every(1).hours.do(find_patterns)
    schedule.every(2).hours.do(find_cross_track_connections)
    schedule.every(3).hours.do(analyze_project_gaps)
    schedule.every(4).hours.do(build_concept_relations)
    schedule.every(6).hours.do(generate_ai_insight)
    schedule.every(30).minutes.do(deliver_insights)
    log.info("✅ NEXUS Engine running")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == "__main__":
    run_engine()
