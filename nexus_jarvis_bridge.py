#!/usr/bin/env python3
"""
NEXUS ↔ JARVIS Integration Bridge
"""

import os
import sys
import logging
from datetime import datetime

import pymysql
import requests
from dotenv import load_dotenv

load_dotenv(os.path.expanduser("~/.env"))

log = logging.getLogger("nexus-jarvis")

DB_CONFIG = {
    "host": "localhost",
    "user": "nexus",
    "password": "nexus_knowledge_2026",
    "database": "nexus_knowledge",
    "charset": "utf8mb4",
    "cursorclass": pymysql.cursors.DictCursor
}

def get_db():
    return pymysql.connect(**DB_CONFIG)

def db_fetch(query, params=None):
    try:
        conn = get_db()
        with conn:
            with conn.cursor() as cursor:
                cursor.execute(query, params or ())
                return cursor.fetchall()
    except Exception as e:
        log.error(f"DB error: {e}")
        return []

def handle_nexus_query(user_message: str) -> str | None:
    msg = user_message.lower().strip()
    if msg in ["nexus", "nexus status", "knowledge", "what do you know"]:
        return get_knowledge_summary()
    elif msg.startswith("teach me") or msg.startswith("nexus teach"):
        topic = msg.replace("teach me", "").replace("nexus teach", "").strip()
        return get_teaching_response(topic)
    elif msg in ["nexus briefing", "morning briefing", "startup"]:
        return get_full_briefing()
    elif msg.startswith("nexus search ") or msg.startswith("find knowledge "):
        query = msg.replace("nexus search ", "").replace("find knowledge ", "")
        return search_knowledge(query)
    elif msg in ["nexus insights", "insights", "what insights"]:
        return get_recent_insights()
    return None

def get_knowledge_summary() -> str:
    try:
        total = db_fetch("SELECT COUNT(*) as cnt FROM sources")[0]["cnt"]
        concepts = db_fetch("SELECT COUNT(*) as cnt FROM concepts")[0]["cnt"]
        top = db_fetch("SELECT name, frequency FROM concepts ORDER BY frequency DESC LIMIT 5")
        msg = f"🧠 *NEXUS Knowledge Base*\n\n📚 {total} documents ingested\n💡 {concepts} concepts mapped\n\n*Top concepts:*\n"
        for c in top:
            msg += f"  • {c['name']} ({c['frequency']}x)\n"
        return msg
    except Exception as e:
        return f"NEXUS: Knowledge base loading... ({e})"

def get_teaching_response(topic: str) -> str:
    if not topic:
        return "What would you like to learn? Try: *teach me python* or *teach me business strategy*"
    try:
        concepts = db_fetch(
            """SELECT c.name, c.category, c.description, c.frequency
               FROM concepts c WHERE c.name LIKE %s OR c.description LIKE %s
               ORDER BY c.frequency DESC LIMIT 5""",
            (f"%{topic}%", f"%{topic}%")
        )
        sources = db_fetch(
            """SELECT file_name, raw_text FROM sources WHERE raw_text LIKE %s
               ORDER BY ingested_at DESC LIMIT 2""",
            (f"%{topic}%",)
        )
        if not concepts and not sources:
            return (f"🔍 No knowledge found about '{topic}' yet.\n\n"
                   f"Drop a PDF or document about it into your sync folder and NEXUS will learn it automatically.")
        msg = f"📚 *What I know about: {topic.title()}*\n\n"
        if concepts:
            msg += "*Related concepts:*\n"
            for c in concepts:
                msg += f"  • {c['name']} ({c['category']})\n"
                if c.get("description"):
                    msg += f"    _{c['description']}_\n"
        if sources:
            msg += f"\n*From {len(sources)} document(s) in your knowledge base.*\n"
            for s in sources[:1]:
                text = s.get("raw_text", "")
                idx = text.lower().find(topic.lower())
                if idx >= 0:
                    snippet = text[max(0, idx-50):idx+200].strip()
                    msg += f"\n_\"...{snippet}...\"_"
        return msg
    except Exception as e:
        return f"NEXUS: Error searching knowledge ({e})"

def get_full_briefing() -> str:
    try:
        total_sources = db_fetch("SELECT COUNT(*) as cnt FROM sources")[0]["cnt"]
        total_concepts = db_fetch("SELECT COUNT(*) as cnt FROM concepts")[0]["cnt"]
        new_today = db_fetch("""SELECT COUNT(*) as cnt FROM sources WHERE ingested_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)""")[0]["cnt"]
        top_concepts = db_fetch("SELECT name, category FROM concepts ORDER BY importance_score DESC, frequency DESC LIMIT 7")
        pending_insights = db_fetch("SELECT title, insight_type FROM insights WHERE delivered = FALSE ORDER BY priority DESC LIMIT 3")
        msg = f"🌅 *NEXUS Morning Briefing*\n_{datetime.now().strftime('%A, %B %d, %Y')}_\n\n"
        msg += f"📊 *Knowledge Base*\n  • {total_sources} total documents\n  • {total_concepts} concepts mapped\n  • {new_today} new today\n\n"
        if top_concepts:
            msg += "*🔥 Growing concepts:*\n"
            for c in top_concepts:
                msg += f"  • {c['name']} ({c['category']})\n"
        if pending_insights:
            msg += f"\n*💡 {len(pending_insights)} insights waiting:*\n"
            for i in pending_insights:
                msg += f"  • {i['title']}\n"
            msg += "\nReply *nexus insights* to see them.\n"
        msg += "\n_NEXUS is watching and learning. 🌱_"
        return msg
    except Exception as e:
        return f"NEXUS online. {datetime.now().strftime('%A, %B %d')} 🧠"

def search_knowledge(query: str) -> str:
    try:
        results = db_fetch(
            """SELECT file_name, source_type, SUBSTRING(raw_text, 1, 300) as preview
               FROM sources WHERE raw_text LIKE %s ORDER BY ingested_at DESC LIMIT 5""",
            (f"%{query}%",)
        )
        if not results:
            return f"🔍 No results for '{query}' in knowledge base."
        msg = f"🔍 *Search: {query}*\n\nFound in {len(results)} document(s):\n\n"
        for r in results:
            msg += f"📄 *{r['file_name']}* [{r['source_type']}]\n"
            preview = r["preview"].replace("\n", " ").strip()
            msg += f"_{preview[:150]}..._\n\n"
        return msg
    except Exception as e:
        return f"Search error: {e}"

def get_recent_insights() -> str:
    try:
        insights = db_fetch("SELECT title, content, insight_type, related_project FROM insights ORDER BY created_at DESC LIMIT 5")
        if not insights:
            return "💡 No insights yet. Keep syncing documents and NEXUS will start connecting dots."
        msg = "💡 *NEXUS Insights*\n\n"
        for i, ins in enumerate(insights, 1):
            msg += f"*{i}. {ins['title']}*\n{ins['content'][:200]}...\n"
            if ins.get("related_project"):
                msg += f"_→ {ins['related_project']}_\n"
            msg += "\n"
        return msg.strip()
    except Exception as e:
        return f"Insights error: {e}"

def send_boot_briefing():
    briefing = get_full_briefing()
    try:
        requests.post("http://localhost:5000/nexus-insight", json={"message": briefing}, timeout=5)
        log.info("Boot briefing sent")
    except Exception:
        log.info(f"Boot briefing (JARVIS offline):\n{briefing}")

if __name__ == "__main__":
    print(get_knowledge_summary())
    print("\n" + "="*50 + "\n")
    print(get_full_briefing())
