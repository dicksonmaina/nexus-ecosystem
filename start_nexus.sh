#!/bin/bash
# ✝️ To God Be The Glory — Jesus Is King
# NEXUS Ingestor Startup Script
# Built by: Richard Dickson Maina | RICHIE Server

set -e

PROJECT_DIR="/home/riziki/workspace/projects/nexus"
PYTHON_CMD="python3"
VENV_DIR="$PROJECT_DIR/venv"

echo "════════════════════════════════════════════════════════════════"
echo "NEXUS Ingestor — Neural Exchange for Unified Synthesis"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if we have a virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating Python virtual environment..."
    $PYTHON_CMD -m venv "$VENV_DIR"
fi

# Activate virtual environment
echo "✅ Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Install/update dependencies
echo "📦 Installing dependencies..."
pip install -q --upgrade pip
pip install -q -r "$PROJECT_DIR/requirements.txt"

# Check database connectivity
echo ""
echo "🗄️  Checking MariaDB connection..."
if ! $PYTHON_CMD -c "import pymysql; pymysql.connect(host='localhost', user='root')" 2>/dev/null; then
    echo "⚠️  MariaDB may not be running. Attempting to start..."
    sudo systemctl start mariadb || echo "❌ Could not start MariaDB"
fi

# Check Ollama connectivity
echo "🧠 Checking Ollama connectivity..."
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "⚠️  Ollama may not be running. Attempting to start..."
    ollama serve &
    sleep 5
fi

# Initialize database schema if needed
echo ""
echo "🗄️  Initializing NEXUS database schema..."
mysql -u root < "$PROJECT_DIR/nexus_schema.sql" 2>/dev/null || echo "⚠️  Schema may already exist (that's OK)"

# Show status
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "NEXUS Ingestor ready. Starting..."
echo "════════════════════════════════════════════════════════════════"
echo ""

# Start ingestor
cd "$PROJECT_DIR"
$PYTHON_CMD -u nexus_ingestor.py --full

# Cleanup on exit
deactivate 2>/dev/null || true
